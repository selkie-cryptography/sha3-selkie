//! Batched SHAKE: four independent streams absorbed and squeezed in parallel.
//!
//! The API is the XOF wrapper of [FIPS 203 Section 4.1]: `new` is
//! `XOF.Init()`, `update` is `XOF.Absorb` (repeatable), and `finalize_xof`
//! yields a reader whose `squeeze` is `XOF.Squeeze` (repeatable, per-lane
//! lengths) — mirroring the single-stream [`Shake128`](crate::Shake128) /
//! [`Shake256`](crate::Shake256) convention, four lanes at a time.
//!
//! While every `update` call passes four equal-length slices the lanes run in
//! lockstep on the batched permutation ([`permute_x4`]) — the matrix-expansion
//! and PRF pattern of a lattice KEM. An unequal-length `update` splits the
//! lanes into four scalar sponges from that point on. Either way the output is
//! bit-identical to the per-stream hashers, so a caller can cross-check the
//! batched path against the scalar one.
//!
//! [FIPS 203 Section 4.1]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.203.pdf#section.4.1

use crate::{
    backend::{State, permute_x4},
    shake::SHAKE_DOMAIN,
    sponge::Sponge,
};

#[cfg(test)]
mod tests;

/// Returns whether all four buffers share a length (the lockstep condition,
/// absorbing or squeezing).
fn equal_lengths<T: AsRef<[u8]>>(buffers: &[T; 4]) -> bool {
    #[allow(
        clippy::indexing_slicing,
        reason = "`buffers` is a fixed array of length 4"
    )]
    let len = buffers[0].as_ref().len();

    buffers.iter().all(|buffer| buffer.as_ref().len() == len)
}

/// Four `Keccak-f[1600]` states absorbed and squeezed in lockstep at a
/// `RATE`-byte rate.
///
/// Valid only while every absorb call carries equal-length inputs, so every
/// lane crosses its rate-block boundaries and finalizes at the same offset;
/// the permutation then advances all four at once via [`permute_x4`].
#[derive(Clone)]
struct SpongeX4<const RATE: usize> {
    /// One state per lane, lane `x + 5*y` little-endian.
    states: [[u64; 25]; 4],

    /// The shared byte cursor within the current rate block.
    offset: usize,
}

impl<const RATE: usize> SpongeX4<RATE> {
    /// Returns four empty lockstep lanes.
    const fn new() -> Self {
        Self {
            states: [[0u64; 25]; 4],
            offset: 0,
        }
    }

    /// Absorbs one equal-length input per lane, permuting after each full
    /// rate block. The caller guarantees equal lengths.
    ///
    /// Whole 8-byte lanes are XORed at once wherever the shared cursor is
    /// lane-aligned (`RATE` is always a multiple of 8); ragged head and tail
    /// bytes go through the byte path.
    #[allow(
        clippy::indexing_slicing,
        clippy::needless_range_loop,
        reason = "lockstep absorb indexes four parallel lanes by byte position"
    )]
    fn absorb(&mut self, inputs: &[&[u8]; 4]) {
        let len = inputs[0].len();
        let mut j = 0;

        while self.offset % 8 != 0 && j < len {
            self.absorb_byte_x4(inputs, j);
            j += 1;
        }

        while j + 8 <= len {
            for lane in 0..4 {
                #[allow(
                    clippy::unwrap_used,
                    reason = "`j + 8 <= len` makes the slice exactly 8 bytes"
                )]
                let word = u64::from_le_bytes(inputs[lane][j..j + 8].try_into().unwrap());
                self.states[lane][self.offset / 8] ^= word;
            }
            self.offset += 8;
            j += 8;

            if self.offset == RATE {
                permute_x4(&mut self.states);
                self.offset = 0;
            }
        }

        while j < len {
            self.absorb_byte_x4(inputs, j);
            j += 1;
        }
    }

    /// Absorbs byte `j` of every lane at the shared cursor, permuting on a
    /// full rate block.
    #[allow(
        clippy::indexing_slicing,
        reason = "the caller bounds `j` by the shared input length"
    )]
    fn absorb_byte_x4(&mut self, inputs: &[&[u8]; 4], j: usize) {
        for (lane, input) in inputs.iter().enumerate() {
            self.xor_byte(lane, self.offset, input[j]);
        }
        self.offset += 1;

        if self.offset == RATE {
            permute_x4(&mut self.states);
            self.offset = 0;
        }
    }

    /// Applies pad10*1 with `domain` to every lane and permutes, switching
    /// the lanes to squeezing.
    fn finalize(&mut self, domain: u8) {
        for lane in 0..4 {
            self.xor_byte(lane, self.offset, domain);
            self.xor_byte(lane, RATE - 1, 0x80);
        }

        permute_x4(&mut self.states);
        self.offset = 0;
    }

    /// Squeezes into each `out[lane]`, permuting between rate blocks. The
    /// caller guarantees equal per-lane lengths (the lockstep condition;
    /// ragged reads degrade to scalar lanes before reaching here).
    ///
    /// Whole 8-byte lanes are copied at once wherever the shared cursor is
    /// lane-aligned, with a byte path for ragged head and tail.
    #[allow(
        clippy::indexing_slicing,
        clippy::needless_range_loop,
        reason = "lockstep squeeze indexes four parallel lanes by byte position"
    )]
    fn squeeze(&mut self, out: [&mut [u8]; 4]) {
        let len = out[0].len();
        let mut j = 0;

        while j < len {
            if self.offset == RATE {
                permute_x4(&mut self.states);
                self.offset = 0;
            }

            if self.offset % 8 == 0 && j + 8 <= len {
                for lane in 0..4 {
                    let word = self.states[lane][self.offset / 8];
                    out[lane][j..j + 8].copy_from_slice(&word.to_le_bytes());
                }
                self.offset += 8;
                j += 8;
                continue;
            }

            for lane in 0..4 {
                let word = self.states[lane][self.offset / 8];
                out[lane][j] = (word >> (8 * (self.offset % 8))) as u8;
            }
            self.offset += 1;
            j += 1;
        }
    }

    /// XORs `byte` into `lane` at byte position `pos` (little-endian in-lane).
    #[allow(
        clippy::indexing_slicing,
        reason = "lane < 4 and pos/8 < 25 hold for every caller"
    )]
    fn xor_byte(&mut self, lane: usize, pos: usize, byte: u8) {
        self.states[lane][pos / 8] ^= u64::from(byte) << (8 * (pos % 8));
    }
}

impl<const RATE: usize> From<SpongeX4<RATE>> for [Sponge<RATE>; 4] {
    /// Splits the lockstep lanes into four scalar sponges (an unequal-length
    /// `update` or ragged squeeze ending the lockstep).
    fn from(sponge: SpongeX4<RATE>) -> Self {
        let offset = sponge.offset;

        sponge
            .states
            .map(|lanes| Sponge::from_parts(State::from(lanes), offset))
    }
}

/// The absorbing phase shared by both batched widths: lockstep while every
/// `update` carries equal lengths, four scalar sponges after the first that
/// does not.
#[derive(Clone)]
enum Absorbing<const RATE: usize> {
    /// The lockstep batched sponge.
    Lockstep(SpongeX4<RATE>),

    /// One scalar sponge per lane.
    Lanes([Sponge<RATE>; 4]),
}

impl<const RATE: usize> Absorbing<RATE> {
    /// Returns the empty (lockstep) absorbing state.
    const fn new() -> Self {
        Self::Lockstep(SpongeX4::new())
    }

    /// Absorbs one input per lane, leaving lockstep on unequal lengths.
    fn update(&mut self, inputs: [&[u8]; 4]) {
        match self {
            Self::Lockstep(sponge) if equal_lengths(&inputs) => sponge.absorb(&inputs),
            Self::Lockstep(sponge) => {
                let mut lanes =
                    <[Sponge<RATE>; 4]>::from(core::mem::replace(sponge, SpongeX4::new()));
                for (lane, input) in lanes.iter_mut().zip(inputs) {
                    lane.absorb(input);
                }

                *self = Self::Lanes(lanes);
            }
            Self::Lanes(lanes) => {
                for (lane, input) in lanes.iter_mut().zip(inputs) {
                    lane.absorb(input);
                }
            }
        }
    }

    /// Applies pad10*1 to every lane, entering the squeezing phase.
    fn finalize(self, domain: u8) -> Squeezing<RATE> {
        match self {
            Self::Lockstep(mut sponge) => {
                sponge.finalize(domain);

                Squeezing::Lockstep(sponge)
            }
            Self::Lanes(mut lanes) => {
                for lane in &mut lanes {
                    lane.finalize(domain);
                }

                Squeezing::Lanes(lanes)
            }
        }
    }
}

/// The squeezing phase shared by both batched widths: lockstep while every
/// squeeze reads equal per-lane lengths, four scalar sponges after the first
/// that does not (the lockstep cursor is shared, so ragged reads would skip
/// stream bytes on the shorter lanes instead of resuming them).
#[derive(Clone)]
enum Squeezing<const RATE: usize> {
    /// The lockstep batched sponge.
    Lockstep(SpongeX4<RATE>),

    /// One scalar sponge per lane.
    Lanes([Sponge<RATE>; 4]),
}

impl<const RATE: usize> Squeezing<RATE> {
    /// Fills each `out[i]` with the next output bytes of lane `i`, leaving
    /// lockstep on unequal lengths.
    fn squeeze(&mut self, out: [&mut [u8]; 4]) {
        match self {
            Self::Lockstep(sponge) if equal_lengths(&out) => sponge.squeeze(out),
            Self::Lockstep(sponge) => {
                let mut lanes =
                    <[Sponge<RATE>; 4]>::from(core::mem::replace(sponge, SpongeX4::new()));
                for (lane, slot) in lanes.iter_mut().zip(out) {
                    lane.squeeze(slot);
                }

                *self = Self::Lanes(lanes);
            }
            Self::Lanes(lanes) => {
                for (lane, slot) in lanes.iter_mut().zip(out) {
                    lane.squeeze(slot);
                }
            }
        }
    }
}

/// Four independent SHAKE128 streams (ML-KEM's `SampleNTT` matrix expansion).
#[derive(Clone)]
pub struct Shake128X4 {
    /// The absorbing lanes.
    inner: Absorbing<168>,
}

impl Shake128X4 {
    /// Returns four empty streams (`XOF.Init`).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            inner: Absorbing::new(),
        }
    }

    /// Absorbs one input per lane (`XOF.Absorb`); may be called repeatedly.
    pub fn update(&mut self, inputs: [&[u8]; 4]) {
        self.inner.update(inputs);
    }

    /// Finalizes absorption and returns a reader over the four output
    /// streams.
    #[must_use]
    pub fn finalize_xof(self) -> Shake128X4Reader {
        Shake128X4Reader {
            inner: self.inner.finalize(SHAKE_DOMAIN),
        }
    }

    /// Absorbs one input per lane and finalizes in one shot.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 4]) -> Shake128X4Reader {
        let mut hasher = Self::new();
        hasher.update(inputs);

        hasher.finalize_xof()
    }
}

impl Default for Shake128X4 {
    fn default() -> Self {
        Self::new()
    }
}

/// Streaming reader over four finalized [`Shake128X4`] output streams.
#[derive(Clone)]
pub struct Shake128X4Reader {
    /// The squeezing lanes.
    inner: Squeezing<168>,
}

impl Shake128X4Reader {
    /// Fills each `out[i]` with the next output bytes of lane `i`
    /// (`XOF.Squeeze`); may be called repeatedly. Equal per-lane lengths stay
    /// on the batched lockstep path; the first unequal-length call splits the
    /// lanes into scalar sponges so every lane still resumes its own stream.
    pub fn squeeze(&mut self, out: [&mut [u8]; 4]) {
        self.inner.squeeze(out);
    }
}

/// Four independent SHAKE256 streams (ML-KEM's CBD noise sampling).
#[derive(Clone)]
pub struct Shake256X4 {
    /// The absorbing lanes.
    inner: Absorbing<136>,
}

impl Shake256X4 {
    /// Returns four empty streams (`XOF.Init`).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            inner: Absorbing::new(),
        }
    }

    /// Absorbs one input per lane (`XOF.Absorb`); may be called repeatedly.
    pub fn update(&mut self, inputs: [&[u8]; 4]) {
        self.inner.update(inputs);
    }

    /// Finalizes absorption and returns a reader over the four output
    /// streams.
    #[must_use]
    pub fn finalize_xof(self) -> Shake256X4Reader {
        Shake256X4Reader {
            inner: self.inner.finalize(SHAKE_DOMAIN),
        }
    }

    /// Absorbs one input per lane and finalizes in one shot.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 4]) -> Shake256X4Reader {
        let mut hasher = Self::new();
        hasher.update(inputs);

        hasher.finalize_xof()
    }
}

impl Default for Shake256X4 {
    fn default() -> Self {
        Self::new()
    }
}

/// Streaming reader over four finalized [`Shake256X4`] output streams.
#[derive(Clone)]
pub struct Shake256X4Reader {
    /// The squeezing lanes.
    inner: Squeezing<136>,
}

impl Shake256X4Reader {
    /// Fills each `out[i]` with the next output bytes of lane `i`
    /// (`XOF.Squeeze`); may be called repeatedly. Equal per-lane lengths stay
    /// on the batched lockstep path; the first unequal-length call splits the
    /// lanes into scalar sponges so every lane still resumes its own stream.
    pub fn squeeze(&mut self, out: [&mut [u8]; 4]) {
        self.inner.squeeze(out);
    }
}

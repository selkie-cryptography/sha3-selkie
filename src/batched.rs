//! Batched SHAKE: two or four independent streams absorbed and squeezed in
//! parallel.
//!
//! The API is the XOF wrapper of [FIPS 203 Section 4.1]: `new` is
//! `XOF.Init()`, `update` is `XOF.Absorb` (repeatable), and `finalize_xof`
//! yields a reader whose `squeeze` is `XOF.Squeeze` (repeatable, per-lane
//! lengths) — mirroring the single-stream [`Shake128`](crate::Shake128) /
//! [`Shake256`](crate::Shake256) convention, several lanes at a time.
//!
//! While every `update` call passes equal-length slices the lanes run in
//! lockstep on the batched permutation ([`Batch`]) — the matrix-expansion and
//! PRF pattern of a lattice KEM. An unequal-length `update` splits the lanes
//! into scalar sponges from that point on. Either way the output is
//! bit-identical to the per-stream hashers, so a caller can cross-check the
//! batched path against the scalar one.
//!
//! # Choosing a width
//!
//! Take the widest that your stream count fills. The four-way path is the more
//! efficient per stream, so it stays the right choice even with one lane idle;
//! the two-way types are for counts that would leave *two* lanes idle, where a
//! four-way permutation would do half its work for nothing.
//!
//! [FIPS 203 Section 4.1]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.203.pdf#section.4.1

use crate::{
    backend::{self, Batch, State},
    shake::SHAKE_DOMAIN,
    sponge::Sponge,
};

#[cfg(test)]
mod tests;

/// Returns whether all `LANES` buffers share a length (the lockstep condition,
/// absorbing or squeezing).
fn equal_lengths<T: AsRef<[u8]>, const LANES: usize>(buffers: &[T; LANES]) -> bool {
    let mut lengths = buffers.iter().map(|buffer| buffer.as_ref().len());
    let Some(first) = lengths.next() else {
        return true;
    };

    lengths.all(|len| len == first)
}

/// `LANES` `Keccak-f[1600]` states absorbed and squeezed in lockstep at a
/// `RATE`-byte rate.
///
/// Valid only while every absorb call carries equal-length inputs, so every
/// lane crosses its rate-block boundaries and finalizes at the same offset;
/// the permutation then advances all of them at once via [`Batch::permute`].
#[derive(Clone)]
struct SpongeX<const RATE: usize, const LANES: usize> {
    /// One state per lane, lane `x + 5*y` little-endian.
    states: [[u64; 25]; LANES],

    /// The shared byte cursor within the current rate block.
    offset: usize,
}

impl<const RATE: usize, const LANES: usize> SpongeX<RATE, LANES>
where
    [[u64; 25]; LANES]: Batch,
{
    /// Returns `LANES` empty lockstep lanes.
    const fn new() -> Self {
        Self {
            states: [[0u64; 25]; LANES],
            offset: 0,
        }
    }

    /// Absorbs one equal-length input per lane, permuting after each full
    /// rate block. The caller guarantees equal lengths.
    ///
    /// Walks a rate block at a time rather than a word at a time: the cursor
    /// arithmetic and the per-lane dispatch then amortize over the whole block
    /// instead of over every eight bytes.
    fn absorb(&mut self, inputs: &[&[u8]; LANES]) {
        let len = inputs.first().map_or(0, |input| input.len());
        let mut j = 0;

        while j < len {
            let run = (RATE - self.offset).min(len - j);

            #[allow(
                clippy::indexing_slicing,
                reason = "`run` is bounded by the shared input length, so `j + run <= len`"
            )]
            for (state, input) in self.states.iter_mut().zip(inputs.iter()) {
                backend::xor_block(state, self.offset, &input[j..j + run]);
            }

            self.offset += run;
            j += run;

            if self.offset == RATE {
                self.states.permute();
                self.offset = 0;
            }
        }
    }

    /// Applies pad10*1 with `domain` to every lane and permutes, switching
    /// the lanes to squeezing.
    fn finalize(&mut self, domain: u8) {
        for lane in 0..LANES {
            self.xor_byte(lane, self.offset, domain);
            self.xor_byte(lane, RATE - 1, 0x80);
        }

        self.states.permute();
        self.offset = 0;
    }

    /// Squeezes into each `out[lane]`, permuting between rate blocks. The
    /// caller guarantees equal per-lane lengths (the lockstep condition;
    /// ragged reads degrade to scalar lanes before reaching here).
    ///
    /// Block-at-a-time, as [`Self::absorb`].
    fn squeeze(&mut self, mut out: [&mut [u8]; LANES]) {
        let len = out.first().map_or(0, |slot| slot.len());
        let mut j = 0;

        while j < len {
            if self.offset == RATE {
                self.states.permute();
                self.offset = 0;
            }

            let run = (RATE - self.offset).min(len - j);

            #[allow(
                clippy::indexing_slicing,
                reason = "`run` is bounded by the shared output length, so `j + run <= len`"
            )]
            for (state, slot) in self.states.iter().zip(out.iter_mut()) {
                backend::read_block(state, self.offset, &mut slot[j..j + run]);
            }

            self.offset += run;
            j += run;
        }
    }

    /// XORs `byte` into `lane` at byte position `pos` (little-endian in-lane).
    #[allow(
        clippy::indexing_slicing,
        reason = "lane < LANES and pos/8 < 25 hold for every caller"
    )]
    fn xor_byte(&mut self, lane: usize, pos: usize, byte: u8) {
        self.states[lane][pos / 8] ^= u64::from(byte) << (8 * (pos % 8));
    }
}

impl<const RATE: usize, const LANES: usize> From<SpongeX<RATE, LANES>> for [Sponge<RATE>; LANES] {
    /// Splits the lockstep lanes into scalar sponges (an unequal-length
    /// `update` or ragged squeeze ending the lockstep).
    fn from(sponge: SpongeX<RATE, LANES>) -> Self {
        let offset = sponge.offset;

        sponge
            .states
            .map(|lanes| Sponge::from_parts(State::from(lanes), offset))
    }
}

/// The absorbing phase shared by every batched width and rate: lockstep while
/// every `update` carries equal lengths, scalar sponges after the first that
/// does not.
#[derive(Clone)]
enum Absorbing<const RATE: usize, const LANES: usize> {
    /// The lockstep batched sponge.
    Lockstep(SpongeX<RATE, LANES>),

    /// One scalar sponge per lane.
    Lanes([Sponge<RATE>; LANES]),
}

impl<const RATE: usize, const LANES: usize> Absorbing<RATE, LANES>
where
    [[u64; 25]; LANES]: Batch,
{
    /// Returns the empty (lockstep) absorbing state.
    const fn new() -> Self {
        Self::Lockstep(SpongeX::new())
    }

    /// Absorbs one input per lane, leaving lockstep on unequal lengths.
    fn update(&mut self, inputs: [&[u8]; LANES]) {
        match self {
            Self::Lockstep(sponge) if equal_lengths(&inputs) => sponge.absorb(&inputs),
            Self::Lockstep(sponge) => {
                let mut lanes =
                    <[Sponge<RATE>; LANES]>::from(core::mem::replace(sponge, SpongeX::new()));
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
    fn finalize(self, domain: u8) -> Squeezing<RATE, LANES> {
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

/// The squeezing phase shared by every batched width and rate: lockstep while
/// every squeeze reads equal per-lane lengths, scalar sponges after the first
/// that does not (the lockstep cursor is shared, so ragged reads would skip
/// stream bytes on the shorter lanes instead of resuming them).
#[derive(Clone)]
enum Squeezing<const RATE: usize, const LANES: usize> {
    /// The lockstep batched sponge.
    Lockstep(SpongeX<RATE, LANES>),

    /// One scalar sponge per lane.
    Lanes([Sponge<RATE>; LANES]),
}

impl<const RATE: usize, const LANES: usize> Squeezing<RATE, LANES>
where
    [[u64; 25]; LANES]: Batch,
{
    /// Fills each `out[i]` with the next output bytes of lane `i`, leaving
    /// lockstep on unequal lengths.
    fn squeeze(&mut self, out: [&mut [u8]; LANES]) {
        match self {
            Self::Lockstep(sponge) if equal_lengths(&out) => sponge.squeeze(out),
            Self::Lockstep(sponge) => {
                let mut lanes =
                    <[Sponge<RATE>; LANES]>::from(core::mem::replace(sponge, SpongeX::new()));
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
    inner: Absorbing<168, 4>,
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
    inner: Squeezing<168, 4>,
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

/// Two independent SHAKE128 streams, for a stream count that would leave two
/// [`Shake128X4`] lanes idle.
#[derive(Clone)]
pub struct Shake128X2 {
    /// The absorbing lanes.
    inner: Absorbing<168, 2>,
}

impl Shake128X2 {
    /// Returns two empty streams (`XOF.Init`).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            inner: Absorbing::new(),
        }
    }

    /// Absorbs one input per lane (`XOF.Absorb`); may be called repeatedly.
    pub fn update(&mut self, inputs: [&[u8]; 2]) {
        self.inner.update(inputs);
    }

    /// Finalizes absorption and returns a reader over the two output streams.
    #[must_use]
    pub fn finalize_xof(self) -> Shake128X2Reader {
        Shake128X2Reader {
            inner: self.inner.finalize(SHAKE_DOMAIN),
        }
    }

    /// Absorbs one input per lane and finalizes in one shot.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 2]) -> Shake128X2Reader {
        let mut hasher = Self::new();
        hasher.update(inputs);

        hasher.finalize_xof()
    }
}

impl Default for Shake128X2 {
    fn default() -> Self {
        Self::new()
    }
}

/// Streaming reader over two finalized [`Shake128X2`] output streams.
#[derive(Clone)]
pub struct Shake128X2Reader {
    /// The squeezing lanes.
    inner: Squeezing<168, 2>,
}

impl Shake128X2Reader {
    /// Fills each `out[i]` with the next output bytes of lane `i`
    /// (`XOF.Squeeze`); may be called repeatedly, with the same lockstep rules
    /// as [`Shake128X4Reader::squeeze`].
    pub fn squeeze(&mut self, out: [&mut [u8]; 2]) {
        self.inner.squeeze(out);
    }
}

/// Four independent SHAKE256 streams (ML-KEM's CBD noise sampling).
#[derive(Clone)]
pub struct Shake256X4 {
    /// The absorbing lanes.
    inner: Absorbing<136, 4>,
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
    inner: Squeezing<136, 4>,
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

/// Two independent SHAKE256 streams, for a stream count that would leave two
/// [`Shake256X4`] lanes idle — ML-KEM-512's `SamplePolyCBD` vector, whose
/// `k = 2` components fill exactly two lanes.
#[derive(Clone)]
pub struct Shake256X2 {
    /// The absorbing lanes.
    inner: Absorbing<136, 2>,
}

impl Shake256X2 {
    /// Returns two empty streams (`XOF.Init`).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            inner: Absorbing::new(),
        }
    }

    /// Absorbs one input per lane (`XOF.Absorb`); may be called repeatedly.
    pub fn update(&mut self, inputs: [&[u8]; 2]) {
        self.inner.update(inputs);
    }

    /// Finalizes absorption and returns a reader over the two output streams.
    #[must_use]
    pub fn finalize_xof(self) -> Shake256X2Reader {
        Shake256X2Reader {
            inner: self.inner.finalize(SHAKE_DOMAIN),
        }
    }

    /// Absorbs one input per lane and finalizes in one shot.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 2]) -> Shake256X2Reader {
        let mut hasher = Self::new();
        hasher.update(inputs);

        hasher.finalize_xof()
    }
}

impl Default for Shake256X2 {
    fn default() -> Self {
        Self::new()
    }
}

/// Streaming reader over two finalized [`Shake256X2`] output streams.
#[derive(Clone)]
pub struct Shake256X2Reader {
    /// The squeezing lanes.
    inner: Squeezing<136, 2>,
}

impl Shake256X2Reader {
    /// Fills each `out[i]` with the next output bytes of lane `i`
    /// (`XOF.Squeeze`); may be called repeatedly, with the same lockstep rules
    /// as [`Shake256X4Reader::squeeze`].
    pub fn squeeze(&mut self, out: [&mut [u8]; 2]) {
        self.inner.squeeze(out);
    }
}

/// Eight independent SHAKE128 streams, for callers with enough streams to fill
/// a 512-bit AVX-512 permutation.
#[derive(Clone)]
pub struct Shake128X8 {
    /// The absorbing lanes.
    inner: Absorbing<168, 8>,
}

impl Shake128X8 {
    /// Returns eight empty streams (`XOF.Init`).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            inner: Absorbing::new(),
        }
    }

    /// Absorbs one input per lane (`XOF.Absorb`); may be called repeatedly.
    pub fn update(&mut self, inputs: [&[u8]; 8]) {
        self.inner.update(inputs);
    }

    /// Finalizes absorption and returns a reader over the eight output
    /// streams.
    #[must_use]
    pub fn finalize_xof(self) -> Shake128X8Reader {
        Shake128X8Reader {
            inner: self.inner.finalize(SHAKE_DOMAIN),
        }
    }

    /// Absorbs one input per lane and finalizes in one shot.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 8]) -> Shake128X8Reader {
        let mut hasher = Self::new();
        hasher.update(inputs);

        hasher.finalize_xof()
    }
}

impl Default for Shake128X8 {
    fn default() -> Self {
        Self::new()
    }
}

/// Streaming reader over eight finalized [`Shake128X8`] output streams.
#[derive(Clone)]
pub struct Shake128X8Reader {
    /// The squeezing lanes.
    inner: Squeezing<168, 8>,
}

impl Shake128X8Reader {
    /// Fills each `out[i]` with the next output bytes of lane `i`
    /// (`XOF.Squeeze`); may be called repeatedly, with the same lockstep rules
    /// as [`Shake128X4Reader::squeeze`].
    pub fn squeeze(&mut self, out: [&mut [u8]; 8]) {
        self.inner.squeeze(out);
    }
}

/// Eight independent SHAKE256 streams, the SHAKE256 counterpart of
/// [`Shake128X8`].
#[derive(Clone)]
pub struct Shake256X8 {
    /// The absorbing lanes.
    inner: Absorbing<136, 8>,
}

impl Shake256X8 {
    /// Returns eight empty streams (`XOF.Init`).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            inner: Absorbing::new(),
        }
    }

    /// Absorbs one input per lane (`XOF.Absorb`); may be called repeatedly.
    pub fn update(&mut self, inputs: [&[u8]; 8]) {
        self.inner.update(inputs);
    }

    /// Finalizes absorption and returns a reader over the eight output
    /// streams.
    #[must_use]
    pub fn finalize_xof(self) -> Shake256X8Reader {
        Shake256X8Reader {
            inner: self.inner.finalize(SHAKE_DOMAIN),
        }
    }

    /// Absorbs one input per lane and finalizes in one shot.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 8]) -> Shake256X8Reader {
        let mut hasher = Self::new();
        hasher.update(inputs);

        hasher.finalize_xof()
    }
}

impl Default for Shake256X8 {
    fn default() -> Self {
        Self::new()
    }
}

/// Streaming reader over eight finalized [`Shake256X8`] output streams.
#[derive(Clone)]
pub struct Shake256X8Reader {
    /// The squeezing lanes.
    inner: Squeezing<136, 8>,
}

impl Shake256X8Reader {
    /// Fills each `out[i]` with the next output bytes of lane `i`
    /// (`XOF.Squeeze`); may be called repeatedly, with the same lockstep rules
    /// as [`Shake256X4Reader::squeeze`].
    pub fn squeeze(&mut self, out: [&mut [u8]; 8]) {
        self.inner.squeeze(out);
    }
}

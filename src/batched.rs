//! Batched SHAKE: two or four independent streams absorbed and squeezed in
//! parallel.
//!
//! The API is the XOF wrapper of [FIPS 203 Section 4.1]: `new` is
//! `XOF.Init()`, `update` is `XOF.Absorb` (repeatable), and `finalize_xof`
//! moves the lanes to their squeezing phase, where `squeeze` is `XOF.Squeeze`
//! (repeatable, per-lane lengths) — mirroring the single-stream
//! [`Shake128`](crate::Shake128) / [`Shake256`](crate::Shake256) convention,
//! several lanes at a time.
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

use core::marker::PhantomData;

use crate::{
    backend::{self, Batch, State},
    shake::{
        SHAKE_DOMAIN, SHAKE128_RATE, SHAKE256_RATE,
        phase::{Absorbing, Squeezing},
    },
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

/// The `LANES` sponges behind every batched width and rate: lockstep while the
/// calls stay equal-length, one scalar sponge per lane after the first that
/// does not.
///
/// Carries both phases' operations; the public types' `Phase` parameter is what
/// keeps a caller from absorbing after the pad.
#[derive(Clone)]
enum Sponges<const RATE: usize, const LANES: usize> {
    /// The lockstep batched sponge.
    Lockstep(SpongeX<RATE, LANES>),

    /// One scalar sponge per lane.
    Lanes([Sponge<RATE>; LANES]),
}

impl<const RATE: usize, const LANES: usize> Sponges<RATE, LANES>
where
    [[u64; 25]; LANES]: Batch,
{
    /// Returns the empty (lockstep) lanes.
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

    /// Applies pad10*1 with `domain` to every lane, entering the squeezing
    /// phase.
    fn finalize(&mut self, domain: u8) {
        match self {
            Self::Lockstep(sponge) => sponge.finalize(domain),
            Self::Lanes(lanes) => {
                for lane in lanes.iter_mut() {
                    lane.finalize(domain);
                }
            }
        }
    }

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
pub struct Shake128X4<Phase> {
    /// The four lanes, absorbing or squeezing as `Phase` says.
    inner: Sponges<SHAKE128_RATE, 4>,

    /// The lifecycle phase, resolved at compile time and absent at run time.
    phase: PhantomData<Phase>,
}

impl Shake128X4<Absorbing> {
    /// SHAKE128's rate in bytes (r/8, for r = 1344): the sponge emits this many
    /// bytes per permutation, so it is the natural chunk for a caller reading
    /// the stream block by block.
    pub const RATE: usize = SHAKE128_RATE;

    /// Returns four empty streams (`XOF.Init`).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            inner: Sponges::new(),
            phase: PhantomData,
        }
    }

    /// Absorbs one input per lane (`XOF.Absorb`); may be called repeatedly.
    pub fn update(&mut self, inputs: [&[u8]; 4]) {
        self.inner.update(inputs);
    }

    /// Pads every lane and returns the same streams in their squeezing phase.
    #[must_use]
    pub fn finalize_xof(mut self) -> Shake128X4<Squeezing> {
        self.inner.finalize(SHAKE_DOMAIN);

        Shake128X4 {
            inner: self.inner,
            phase: PhantomData,
        }
    }

    /// Absorbs one input per lane and finalizes in one shot.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 4]) -> Shake128X4<Squeezing> {
        let mut hasher = Self::new();
        hasher.update(inputs);

        hasher.finalize_xof()
    }
}

impl Default for Shake128X4<Absorbing> {
    fn default() -> Self {
        Self::new()
    }
}

impl Shake128X4<Squeezing> {
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
pub struct Shake128X2<Phase> {
    /// The two lanes, absorbing or squeezing as `Phase` says.
    inner: Sponges<SHAKE128_RATE, 2>,

    /// The lifecycle phase, resolved at compile time and absent at run time.
    phase: PhantomData<Phase>,
}

impl Shake128X2<Absorbing> {
    /// SHAKE128's rate in bytes (r/8, for r = 1344): the sponge emits this many
    /// bytes per permutation, so it is the natural chunk for a caller reading
    /// the stream block by block.
    pub const RATE: usize = SHAKE128_RATE;

    /// Returns two empty streams (`XOF.Init`).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            inner: Sponges::new(),
            phase: PhantomData,
        }
    }

    /// Absorbs one input per lane (`XOF.Absorb`); may be called repeatedly.
    pub fn update(&mut self, inputs: [&[u8]; 2]) {
        self.inner.update(inputs);
    }

    /// Pads every lane and returns the same streams in their squeezing phase.
    #[must_use]
    pub fn finalize_xof(mut self) -> Shake128X2<Squeezing> {
        self.inner.finalize(SHAKE_DOMAIN);

        Shake128X2 {
            inner: self.inner,
            phase: PhantomData,
        }
    }

    /// Absorbs one input per lane and finalizes in one shot.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 2]) -> Shake128X2<Squeezing> {
        let mut hasher = Self::new();
        hasher.update(inputs);

        hasher.finalize_xof()
    }
}

impl Default for Shake128X2<Absorbing> {
    fn default() -> Self {
        Self::new()
    }
}

impl Shake128X2<Squeezing> {
    /// Fills each `out[i]` with the next output bytes of lane `i`
    /// (`XOF.Squeeze`); may be called repeatedly. Equal per-lane lengths stay
    /// on the batched lockstep path; the first unequal-length call splits the
    /// lanes into scalar sponges so every lane still resumes its own stream.
    pub fn squeeze(&mut self, out: [&mut [u8]; 2]) {
        self.inner.squeeze(out);
    }
}

/// Four independent SHAKE256 streams (ML-KEM's CBD noise sampling).
#[derive(Clone)]
pub struct Shake256X4<Phase> {
    /// The four lanes, absorbing or squeezing as `Phase` says.
    inner: Sponges<SHAKE256_RATE, 4>,

    /// The lifecycle phase, resolved at compile time and absent at run time.
    phase: PhantomData<Phase>,
}

impl Shake256X4<Absorbing> {
    /// SHAKE256's rate in bytes (r/8, for r = 1088): the sponge emits this many
    /// bytes per permutation, so it is the natural chunk for a caller reading
    /// the stream block by block.
    pub const RATE: usize = SHAKE256_RATE;

    /// Returns four empty streams (`XOF.Init`).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            inner: Sponges::new(),
            phase: PhantomData,
        }
    }

    /// Absorbs one input per lane (`XOF.Absorb`); may be called repeatedly.
    pub fn update(&mut self, inputs: [&[u8]; 4]) {
        self.inner.update(inputs);
    }

    /// Pads every lane and returns the same streams in their squeezing phase.
    #[must_use]
    pub fn finalize_xof(mut self) -> Shake256X4<Squeezing> {
        self.inner.finalize(SHAKE_DOMAIN);

        Shake256X4 {
            inner: self.inner,
            phase: PhantomData,
        }
    }

    /// Absorbs one input per lane and finalizes in one shot.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 4]) -> Shake256X4<Squeezing> {
        let mut hasher = Self::new();
        hasher.update(inputs);

        hasher.finalize_xof()
    }
}

impl Default for Shake256X4<Absorbing> {
    fn default() -> Self {
        Self::new()
    }
}

impl Shake256X4<Squeezing> {
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
pub struct Shake256X2<Phase> {
    /// The two lanes, absorbing or squeezing as `Phase` says.
    inner: Sponges<SHAKE256_RATE, 2>,

    /// The lifecycle phase, resolved at compile time and absent at run time.
    phase: PhantomData<Phase>,
}

impl Shake256X2<Absorbing> {
    /// SHAKE256's rate in bytes (r/8, for r = 1088): the sponge emits this many
    /// bytes per permutation, so it is the natural chunk for a caller reading
    /// the stream block by block.
    pub const RATE: usize = SHAKE256_RATE;

    /// Returns two empty streams (`XOF.Init`).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            inner: Sponges::new(),
            phase: PhantomData,
        }
    }

    /// Absorbs one input per lane (`XOF.Absorb`); may be called repeatedly.
    pub fn update(&mut self, inputs: [&[u8]; 2]) {
        self.inner.update(inputs);
    }

    /// Pads every lane and returns the same streams in their squeezing phase.
    #[must_use]
    pub fn finalize_xof(mut self) -> Shake256X2<Squeezing> {
        self.inner.finalize(SHAKE_DOMAIN);

        Shake256X2 {
            inner: self.inner,
            phase: PhantomData,
        }
    }

    /// Absorbs one input per lane and finalizes in one shot.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 2]) -> Shake256X2<Squeezing> {
        let mut hasher = Self::new();
        hasher.update(inputs);

        hasher.finalize_xof()
    }
}

impl Default for Shake256X2<Absorbing> {
    fn default() -> Self {
        Self::new()
    }
}

impl Shake256X2<Squeezing> {
    /// Fills each `out[i]` with the next output bytes of lane `i`
    /// (`XOF.Squeeze`); may be called repeatedly. Equal per-lane lengths stay
    /// on the batched lockstep path; the first unequal-length call splits the
    /// lanes into scalar sponges so every lane still resumes its own stream.
    pub fn squeeze(&mut self, out: [&mut [u8]; 2]) {
        self.inner.squeeze(out);
    }
}

/// Eight independent SHAKE128 streams, for callers with enough streams to fill
/// a 512-bit AVX-512 permutation.
#[derive(Clone)]
pub struct Shake128X8<Phase> {
    /// The eight lanes, absorbing or squeezing as `Phase` says.
    inner: Sponges<SHAKE128_RATE, 8>,

    /// The lifecycle phase, resolved at compile time and absent at run time.
    phase: PhantomData<Phase>,
}

impl Shake128X8<Absorbing> {
    /// SHAKE128's rate in bytes (r/8, for r = 1344): the sponge emits this many
    /// bytes per permutation, so it is the natural chunk for a caller reading
    /// the stream block by block.
    pub const RATE: usize = SHAKE128_RATE;

    /// Returns eight empty streams (`XOF.Init`).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            inner: Sponges::new(),
            phase: PhantomData,
        }
    }

    /// Absorbs one input per lane (`XOF.Absorb`); may be called repeatedly.
    pub fn update(&mut self, inputs: [&[u8]; 8]) {
        self.inner.update(inputs);
    }

    /// Pads every lane and returns the same streams in their squeezing phase.
    #[must_use]
    pub fn finalize_xof(mut self) -> Shake128X8<Squeezing> {
        self.inner.finalize(SHAKE_DOMAIN);

        Shake128X8 {
            inner: self.inner,
            phase: PhantomData,
        }
    }

    /// Absorbs one input per lane and finalizes in one shot.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 8]) -> Shake128X8<Squeezing> {
        let mut hasher = Self::new();
        hasher.update(inputs);

        hasher.finalize_xof()
    }
}

impl Default for Shake128X8<Absorbing> {
    fn default() -> Self {
        Self::new()
    }
}

impl Shake128X8<Squeezing> {
    /// Fills each `out[i]` with the next output bytes of lane `i`
    /// (`XOF.Squeeze`); may be called repeatedly. Equal per-lane lengths stay
    /// on the batched lockstep path; the first unequal-length call splits the
    /// lanes into scalar sponges so every lane still resumes its own stream.
    pub fn squeeze(&mut self, out: [&mut [u8]; 8]) {
        self.inner.squeeze(out);
    }
}

/// Eight independent SHAKE256 streams, the SHAKE256 counterpart of
/// [`Shake128X8`].
#[derive(Clone)]
pub struct Shake256X8<Phase> {
    /// The eight lanes, absorbing or squeezing as `Phase` says.
    inner: Sponges<SHAKE256_RATE, 8>,

    /// The lifecycle phase, resolved at compile time and absent at run time.
    phase: PhantomData<Phase>,
}

impl Shake256X8<Absorbing> {
    /// SHAKE256's rate in bytes (r/8, for r = 1088): the sponge emits this many
    /// bytes per permutation, so it is the natural chunk for a caller reading
    /// the stream block by block.
    pub const RATE: usize = SHAKE256_RATE;

    /// Returns eight empty streams (`XOF.Init`).
    #[must_use]
    pub const fn new() -> Self {
        Self {
            inner: Sponges::new(),
            phase: PhantomData,
        }
    }

    /// Absorbs one input per lane (`XOF.Absorb`); may be called repeatedly.
    pub fn update(&mut self, inputs: [&[u8]; 8]) {
        self.inner.update(inputs);
    }

    /// Pads every lane and returns the same streams in their squeezing phase.
    #[must_use]
    pub fn finalize_xof(mut self) -> Shake256X8<Squeezing> {
        self.inner.finalize(SHAKE_DOMAIN);

        Shake256X8 {
            inner: self.inner,
            phase: PhantomData,
        }
    }

    /// Absorbs one input per lane and finalizes in one shot.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 8]) -> Shake256X8<Squeezing> {
        let mut hasher = Self::new();
        hasher.update(inputs);

        hasher.finalize_xof()
    }
}

impl Default for Shake256X8<Absorbing> {
    fn default() -> Self {
        Self::new()
    }
}

impl Shake256X8<Squeezing> {
    /// Fills each `out[i]` with the next output bytes of lane `i`
    /// (`XOF.Squeeze`); may be called repeatedly. Equal per-lane lengths stay
    /// on the batched lockstep path; the first unequal-length call splits the
    /// lanes into scalar sponges so every lane still resumes its own stream.
    pub fn squeeze(&mut self, out: [&mut [u8]; 8]) {
        self.inner.squeeze(out);
    }
}

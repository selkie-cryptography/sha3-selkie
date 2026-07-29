//! Extendable-output functions ([FIPS 202 Section 6.2]): SHAKE128 and SHAKE256.
//!
//! Each is an absorbing sponge whose [`finalize_xof`][Shake128::finalize_xof]
//! moves it to its squeezing phase, where it streams output on demand, for
//! callers like ML-KEM's `SampleNTT` rejection sampler that cannot know their
//! output length in advance.
//!
//! [FIPS 202 Section 6.2]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf#section.6.2

use core::marker::PhantomData;

use self::phase::{Absorbing, Squeezing};
use crate::sponge::Sponge;

#[cfg(test)]
mod tests;

/// The sponge lifecycle, carried in a type parameter.
///
/// A sponge absorbs input, is padded once, and from then on only produces
/// output; absorbing after the pad is meaningless. Rather than two types per
/// width, each hasher takes a `Phase` parameter and carries the operations of
/// exactly one phase, so `update`-after-`read` is a compile error and every
/// signature names the phase it takes or returns.
pub mod phase {
    /// Taking input, not yet padded. The starting phase of every hasher.
    #[derive(Clone, Copy, Debug, PartialEq, Eq)]
    pub struct Absorbing;

    /// Padded and permuted; producing output only.
    #[derive(Clone, Copy, Debug, PartialEq, Eq)]
    pub struct Squeezing;
}

/// The SHAKE domain-separation byte (`1111` then pad10*1, packed
/// little-endian).
pub(crate) const SHAKE_DOMAIN: u8 = 0x1F;

/// SHAKE128's rate in bytes, r/8 for r = 1344. Parameterizes the sponge and is
/// republished as `Shake128::RATE`, so the two cannot drift apart.
pub(crate) const SHAKE128_RATE: usize = 168;

/// SHAKE256's rate in bytes, r/8 for r = 1088. Parameterizes the sponge and is
/// republished as `Shake256::RATE`, so the two cannot drift apart.
pub(crate) const SHAKE256_RATE: usize = 136;

/// SHAKE128: an extendable-output function with a 168-byte rate.
#[derive(Clone)]
pub struct Shake128<Phase> {
    /// The sponge, absorbing or squeezing as `Phase` says.
    sponge: Sponge<SHAKE128_RATE>,

    /// The lifecycle phase, resolved at compile time and absent at run time.
    phase: PhantomData<Phase>,
}

impl Shake128<Absorbing> {
    /// SHAKE128's rate in bytes (r/8, for r = 1344): the sponge emits this many
    /// bytes per permutation, so it is the natural chunk for a caller reading
    /// the stream block by block.
    pub const RATE: usize = SHAKE128_RATE;

    /// Returns an empty hasher.
    #[must_use]
    pub const fn new() -> Self {
        Self {
            sponge: Sponge::new(),
            phase: PhantomData,
        }
    }

    /// Absorbs more input.
    pub fn update(&mut self, data: &[u8]) {
        self.sponge.absorb(data);
    }

    /// Pads the sponge and returns it in its squeezing phase.
    #[must_use]
    pub fn finalize_xof(mut self) -> Shake128<Squeezing> {
        self.sponge.finalize(SHAKE_DOMAIN);

        Shake128 {
            sponge: self.sponge,
            phase: PhantomData,
        }
    }

    /// Absorbs `data` and reads `N` output bytes in one shot.
    #[must_use]
    pub fn digest<const N: usize>(data: &[u8]) -> [u8; N] {
        let mut hasher = Self::new();
        hasher.update(data);

        let mut reader = hasher.finalize_xof();
        let mut out = [0u8; N];
        reader.read(&mut out);

        out
    }
}

impl Default for Shake128<Absorbing> {
    fn default() -> Self {
        Self::new()
    }
}

impl Shake128<Squeezing> {
    /// Fills `out` with the next output bytes, extending the stream across
    /// calls.
    pub fn read(&mut self, out: &mut [u8]) {
        self.sponge.squeeze(out);
    }
}

/// SHAKE256: an extendable-output function with a 136-byte rate.
#[derive(Clone)]
pub struct Shake256<Phase> {
    /// The sponge, absorbing or squeezing as `Phase` says.
    sponge: Sponge<SHAKE256_RATE>,

    /// The lifecycle phase, resolved at compile time and absent at run time.
    phase: PhantomData<Phase>,
}

impl Shake256<Absorbing> {
    /// SHAKE256's rate in bytes (r/8, for r = 1088): the sponge emits this many
    /// bytes per permutation, so it is the natural chunk for a caller reading
    /// the stream block by block.
    pub const RATE: usize = SHAKE256_RATE;

    /// Returns an empty hasher.
    #[must_use]
    pub const fn new() -> Self {
        Self {
            sponge: Sponge::new(),
            phase: PhantomData,
        }
    }

    /// Absorbs more input.
    pub fn update(&mut self, data: &[u8]) {
        self.sponge.absorb(data);
    }

    /// Pads the sponge and returns it in its squeezing phase.
    #[must_use]
    pub fn finalize_xof(mut self) -> Shake256<Squeezing> {
        self.sponge.finalize(SHAKE_DOMAIN);

        Shake256 {
            sponge: self.sponge,
            phase: PhantomData,
        }
    }

    /// Absorbs `data` and reads `N` output bytes in one shot.
    #[must_use]
    pub fn digest<const N: usize>(data: &[u8]) -> [u8; N] {
        let mut hasher = Self::new();
        hasher.update(data);

        let mut reader = hasher.finalize_xof();
        let mut out = [0u8; N];
        reader.read(&mut out);

        out
    }
}

impl Default for Shake256<Absorbing> {
    fn default() -> Self {
        Self::new()
    }
}

impl Shake256<Squeezing> {
    /// Fills `out` with the next output bytes, extending the stream across
    /// calls.
    pub fn read(&mut self, out: &mut [u8]) {
        self.sponge.squeeze(out);
    }
}

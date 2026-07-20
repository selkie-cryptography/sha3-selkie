//! Extendable-output functions ([FIPS 202 Section 6.2]): SHAKE128 and SHAKE256.
//!
//! Each is an absorbing hasher whose [`finalize_xof`][Shake128::finalize_xof]
//! yields a reader that streams output on demand, for callers like ML-KEM's
//! `SampleNTT` rejection sampler that cannot know their output length in
//! advance.
//!
//! [FIPS 202 Section 6.2]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf#section.6.2

use crate::sponge::Sponge;

#[cfg(test)]
mod tests;

/// The SHAKE domain-separation byte (`1111` then pad10*1, packed
/// little-endian).
const SHAKE_DOMAIN: u8 = 0x1F;

/// SHAKE128: an extendable-output function with a 168-byte rate.
#[derive(Clone)]
pub struct Shake128 {
    /// The absorbing sponge.
    sponge: Sponge<168>,
}

impl Shake128 {
    /// Returns an empty hasher.
    #[must_use]
    pub const fn new() -> Self {
        Self {
            sponge: Sponge::new(),
        }
    }

    /// Absorbs more input.
    pub fn update(&mut self, data: &[u8]) {
        self.sponge.absorb(data);
    }

    /// Finalizes absorption and returns a reader over the output stream.
    #[must_use]
    pub fn finalize_xof(mut self) -> Shake128Reader {
        self.sponge.finalize(SHAKE_DOMAIN);

        Shake128Reader {
            sponge: self.sponge,
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

impl Default for Shake128 {
    fn default() -> Self {
        Self::new()
    }
}

/// Streaming reader over a finalized [`Shake128`] output.
#[derive(Clone)]
pub struct Shake128Reader {
    /// The squeezing sponge.
    sponge: Sponge<168>,
}

impl Shake128Reader {
    /// Fills `out` with the next output bytes, extending the stream across
    /// calls.
    pub fn read(&mut self, out: &mut [u8]) {
        self.sponge.squeeze(out);
    }
}

/// SHAKE256: an extendable-output function with a 136-byte rate.
#[derive(Clone)]
pub struct Shake256 {
    /// The absorbing sponge.
    sponge: Sponge<136>,
}

impl Shake256 {
    /// Returns an empty hasher.
    #[must_use]
    pub const fn new() -> Self {
        Self {
            sponge: Sponge::new(),
        }
    }

    /// Absorbs more input.
    pub fn update(&mut self, data: &[u8]) {
        self.sponge.absorb(data);
    }

    /// Finalizes absorption and returns a reader over the output stream.
    #[must_use]
    pub fn finalize_xof(mut self) -> Shake256Reader {
        self.sponge.finalize(SHAKE_DOMAIN);

        Shake256Reader {
            sponge: self.sponge,
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

impl Default for Shake256 {
    fn default() -> Self {
        Self::new()
    }
}

/// Streaming reader over a finalized [`Shake256`] output.
#[derive(Clone)]
pub struct Shake256Reader {
    /// The squeezing sponge.
    sponge: Sponge<136>,
}

impl Shake256Reader {
    /// Fills `out` with the next output bytes, extending the stream across
    /// calls.
    pub fn read(&mut self, out: &mut [u8]) {
        self.sponge.squeeze(out);
    }
}

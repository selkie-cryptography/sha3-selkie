//! Fixed-output SHA-3 hashes ([FIPS 202 Section 6.1]).
//!
//! [FIPS 202 Section 6.1]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf#section.6.1

use crate::sponge::Sponge;

#[cfg(test)]
mod tests;

/// The SHA-3 domain-separation byte (`01` then pad10*1, packed little-endian).
const SHA3_DOMAIN: u8 = 0x06;

/// SHA3-256: a 256-bit hash with a 136-byte rate.
#[derive(Clone)]
pub struct Sha3_256 {
    /// The absorbing sponge.
    sponge: Sponge<136>,
}

impl Sha3_256 {
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

    /// Consumes the hasher and returns the 32-byte digest.
    #[must_use]
    pub fn finalize(mut self) -> [u8; 32] {
        self.sponge.finalize(SHA3_DOMAIN);

        let mut digest = [0u8; 32];
        self.sponge.squeeze(&mut digest);

        digest
    }

    /// Hashes `data` in one shot.
    #[must_use]
    pub fn digest(data: &[u8]) -> [u8; 32] {
        let mut hasher = Self::new();
        hasher.update(data);

        hasher.finalize()
    }
}

impl Default for Sha3_256 {
    fn default() -> Self {
        Self::new()
    }
}

/// SHA3-512: a 512-bit hash with a 72-byte rate.
#[derive(Clone)]
pub struct Sha3_512 {
    /// The absorbing sponge.
    sponge: Sponge<72>,
}

impl Sha3_512 {
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

    /// Consumes the hasher and returns the 64-byte digest.
    #[must_use]
    pub fn finalize(mut self) -> [u8; 64] {
        self.sponge.finalize(SHA3_DOMAIN);

        let mut digest = [0u8; 64];
        self.sponge.squeeze(&mut digest);

        digest
    }

    /// Hashes `data` in one shot.
    #[must_use]
    pub fn digest(data: &[u8]) -> [u8; 64] {
        let mut hasher = Self::new();
        hasher.update(data);

        hasher.finalize()
    }
}

impl Default for Sha3_512 {
    fn default() -> Self {
        Self::new()
    }
}

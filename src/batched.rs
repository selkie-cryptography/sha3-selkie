//! Batched SHAKE: several independent streams squeezed in parallel.
//!
//! The lanes are bit-identical to the per-stream [`Shake128`] / [`Shake256`],
//! so a caller can cross-check the batched path against the scalar one. The
//! implementation runs four scalar lanes.

use crate::shake::{Shake128, Shake128Reader, Shake256, Shake256Reader};

#[cfg(test)]
mod tests;

/// Four independent SHAKE128 streams (ML-KEM's `SampleNTT` matrix expansion).
pub struct Shake128X4 {
    /// The four finalized per-lane readers.
    lanes: [Shake128Reader; 4],
}

impl Shake128X4 {
    /// Absorbs one seed per lane and finalizes, returning the batched reader.
    #[must_use]
    pub fn absorb(seeds: [&[u8]; 4]) -> Self {
        Self {
            lanes: seeds.map(|seed| {
                let mut hasher = Shake128::new();
                hasher.update(seed);

                hasher.finalize_xof()
            }),
        }
    }

    /// Fills each `out[i]` with the next output bytes of lane `i`.
    pub fn squeeze(&mut self, out: [&mut [u8]; 4]) {
        for (reader, slot) in self.lanes.iter_mut().zip(out) {
            reader.read(slot);
        }
    }
}

/// Four independent SHAKE256 streams (ML-KEM's CBD noise sampling).
pub struct Shake256X4 {
    /// The four finalized per-lane readers.
    lanes: [Shake256Reader; 4],
}

impl Shake256X4 {
    /// Absorbs one input per lane and finalizes, returning the batched reader.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 4]) -> Self {
        Self {
            lanes: inputs.map(|input| {
                let mut hasher = Shake256::new();
                hasher.update(input);

                hasher.finalize_xof()
            }),
        }
    }

    /// Fills each `out[i]` with the next output bytes of lane `i`.
    pub fn squeeze(&mut self, out: [&mut [u8]; 4]) {
        for (reader, slot) in self.lanes.iter_mut().zip(out) {
            reader.read(slot);
        }
    }
}

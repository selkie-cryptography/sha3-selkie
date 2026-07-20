//! Batched SHAKE: four independent streams squeezed in parallel.
//!
//! When the four inputs share a length the streams run in lockstep on the
//! two-way batched permutation ([`permute_x4`]) — the matrix-expansion and PRF
//! pattern of a lattice KEM; otherwise each lane falls back to the scalar
//! hasher. Either way the output is bit-identical to the per-stream
//! [`Shake128`] / [`Shake256`], so a caller can cross-check the batched path
//! against the scalar one.

use crate::{
    backend::permute_x4,
    shake::{SHAKE_DOMAIN, Shake128, Shake128Reader, Shake256, Shake256Reader},
};

#[cfg(test)]
mod tests;

/// Returns whether all four inputs share a length (the batched precondition).
fn equal_lengths(inputs: &[&[u8]; 4]) -> bool {
    #[allow(
        clippy::indexing_slicing,
        reason = "`inputs` is a fixed array of length 4"
    )]
    let len = inputs[0].len();

    inputs.iter().all(|input| input.len() == len)
}

/// Four `Keccak-f[1600]` states absorbed and squeezed in lockstep at a
/// `RATE`-byte rate.
///
/// Used only when the four inputs share a length, so every lane crosses its
/// rate-block boundaries and finalizes at the same offset; the permutation then
/// advances all four at once via [`permute_x4`].
struct SpongeX4<const RATE: usize> {
    /// One state per lane, lane `x + 5*y` little-endian.
    states: [[u64; 25]; 4],

    /// The shared byte cursor within the current rate block.
    offset: usize,
}

impl<const RATE: usize> SpongeX4<RATE> {
    /// Absorbs one equal-length input per lane, applies pad10*1 with `domain`,
    /// and permutes into the squeezing phase.
    #[allow(
        clippy::indexing_slicing,
        clippy::needless_range_loop,
        reason = "lockstep absorb indexes four parallel lanes by byte position"
    )]
    fn absorb_finalize(inputs: [&[u8]; 4], domain: u8) -> Self {
        let mut sponge = Self {
            states: [[0u64; 25]; 4],
            offset: 0,
        };

        for j in 0..inputs[0].len() {
            for lane in 0..4 {
                sponge.xor_byte(lane, sponge.offset, inputs[lane][j]);
            }
            sponge.offset += 1;

            if sponge.offset == RATE {
                permute_x4(&mut sponge.states);
                sponge.offset = 0;
            }
        }

        for lane in 0..4 {
            sponge.xor_byte(lane, sponge.offset, domain);
            sponge.xor_byte(lane, RATE - 1, 0x80);
        }

        permute_x4(&mut sponge.states);
        sponge.offset = 0;

        sponge
    }

    /// Squeezes into each `out[lane]`, permuting between rate blocks.
    ///
    /// Per-lane lengths may differ: every lane advances in lockstep and only
    /// bytes within a lane's own length are written.
    #[allow(
        clippy::indexing_slicing,
        clippy::needless_range_loop,
        reason = "lockstep squeeze indexes four parallel lanes by byte position"
    )]
    fn squeeze(&mut self, out: [&mut [u8]; 4]) {
        let longest = out.iter().map(|slot| slot.len()).max().unwrap_or(0);

        for j in 0..longest {
            if self.offset == RATE {
                permute_x4(&mut self.states);
                self.offset = 0;
            }

            for lane in 0..4 {
                if j < out[lane].len() {
                    let word = self.states[lane][self.offset / 8];
                    out[lane][j] = (word >> (8 * (self.offset % 8))) as u8;
                }
            }

            self.offset += 1;
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

/// Four independent SHAKE128 streams (ML-KEM's `SampleNTT` matrix expansion).
pub struct Shake128X4 {
    /// Batched when the seeds share a length, else four scalar lanes.
    inner: Inner128,
}

/// The two `Shake128X4` execution paths.
enum Inner128 {
    /// The lockstep two-way-batched sponge (equal-length seeds).
    Batched(SpongeX4<168>),

    /// One scalar reader per lane (unequal-length seeds).
    Scalar([Shake128Reader; 4]),
}

impl Shake128X4 {
    /// Absorbs one seed per lane and finalizes, returning the batched reader.
    #[must_use]
    pub fn absorb(seeds: [&[u8]; 4]) -> Self {
        let inner = if equal_lengths(&seeds) {
            Inner128::Batched(SpongeX4::absorb_finalize(seeds, SHAKE_DOMAIN))
        } else {
            Inner128::Scalar(seeds.map(|seed| {
                let mut hasher = Shake128::new();
                hasher.update(seed);

                hasher.finalize_xof()
            }))
        };

        Self { inner }
    }

    /// Fills each `out[i]` with the next output bytes of lane `i`.
    pub fn squeeze(&mut self, out: [&mut [u8]; 4]) {
        match &mut self.inner {
            Inner128::Batched(sponge) => sponge.squeeze(out),
            Inner128::Scalar(readers) => {
                for (reader, slot) in readers.iter_mut().zip(out) {
                    reader.read(slot);
                }
            }
        }
    }
}

/// Four independent SHAKE256 streams (ML-KEM's CBD noise sampling).
pub struct Shake256X4 {
    /// Batched when the inputs share a length, else four scalar lanes.
    inner: Inner256,
}

/// The two `Shake256X4` execution paths.
enum Inner256 {
    /// The lockstep two-way-batched sponge (equal-length inputs).
    Batched(SpongeX4<136>),

    /// One scalar reader per lane (unequal-length inputs).
    Scalar([Shake256Reader; 4]),
}

impl Shake256X4 {
    /// Absorbs one input per lane and finalizes, returning the batched reader.
    #[must_use]
    pub fn absorb(inputs: [&[u8]; 4]) -> Self {
        let inner = if equal_lengths(&inputs) {
            Inner256::Batched(SpongeX4::absorb_finalize(inputs, SHAKE_DOMAIN))
        } else {
            Inner256::Scalar(inputs.map(|input| {
                let mut hasher = Shake256::new();
                hasher.update(input);

                hasher.finalize_xof()
            }))
        };

        Self { inner }
    }

    /// Fills each `out[i]` with the next output bytes of lane `i`.
    pub fn squeeze(&mut self, out: [&mut [u8]; 4]) {
        match &mut self.inner {
            Inner256::Batched(sponge) => sponge.squeeze(out),
            Inner256::Scalar(readers) => {
                for (reader, slot) in readers.iter_mut().zip(out) {
                    reader.read(slot);
                }
            }
        }
    }
}

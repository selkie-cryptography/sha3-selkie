//! The Keccak sponge: byte-oriented absorb and squeeze over a [`State`], with
//! the rate a const generic so each SHA-3 and SHAKE instance is a distinct
//! type.

use crate::backend::State;

/// A Keccak sponge with a `RATE`-byte rate (the bitrate `r` in bytes; the
/// capacity is `200 - RATE`).
///
/// Absorbs input in `RATE`-byte blocks, applies pad10*1 with a
/// domain-separation byte at [`finalize`][Sponge::finalize], then squeezes
/// output in `RATE`-byte blocks. A single `offset` cursor tracks the position
/// within the current block for both phases.
#[derive(Clone)]
pub(crate) struct Sponge<const RATE: usize> {
    /// The permutation state.
    state: State,

    /// The byte cursor within the current rate block: the fill point while
    /// absorbing, the read point while squeezing.
    offset: usize,
}

impl<const RATE: usize> Sponge<RATE> {
    /// Returns an empty sponge.
    pub(crate) const fn new() -> Self {
        Self {
            state: State::zeroed(),
            offset: 0,
        }
    }

    /// Absorbs `data`, permuting after each full rate block.
    pub(crate) fn absorb(&mut self, data: &[u8]) {
        for &byte in data {
            self.xor_byte(self.offset, byte);
            self.offset += 1;

            if self.offset == RATE {
                self.state.permute();
                self.offset = 0;
            }
        }
    }

    /// Applies pad10*1 with the given domain-separation byte and permutes,
    /// switching the sponge to squeezing.
    pub(crate) fn finalize(&mut self, domain: u8) {
        self.xor_byte(self.offset, domain);
        self.xor_byte(RATE - 1, 0x80);

        self.state.permute();
        self.offset = 0;
    }

    /// Squeezes `out.len()` bytes, permuting between rate blocks.
    ///
    /// Call only after [`finalize`][Sponge::finalize]; may be called repeatedly
    /// to extend the output (the XOF contract).
    pub(crate) fn squeeze(&mut self, out: &mut [u8]) {
        for slot in out.iter_mut() {
            if self.offset == RATE {
                self.state.permute();
                self.offset = 0;
            }

            let lane = self.state.lane(self.offset / 8);
            *slot = (lane >> (8 * (self.offset % 8))) as u8;
            self.offset += 1;
        }
    }

    /// XORs `byte` into the state at byte position `pos` (little-endian within
    /// its lane).
    fn xor_byte(&mut self, pos: usize, byte: u8) {
        self.state
            .xor_lane(pos / 8, u64::from(byte) << (8 * (pos % 8)));
    }
}

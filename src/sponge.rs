//! The Keccak sponge: absorb and squeeze over a [`State`], lane-at-a-time
//! wherever the byte cursor allows, with the rate a const generic so each
//! SHA-3 and SHAKE instance is a distinct type.

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

    /// Rebuilds a sponge from a state and byte cursor (a batched lane leaving
    /// lockstep).
    pub(crate) const fn from_parts(state: State, offset: usize) -> Self {
        Self { state, offset }
    }

    /// Absorbs `data`, permuting after each full rate block.
    ///
    /// Walks a rate block at a time: the cursor arithmetic and the boundary
    /// check then amortize over the whole block rather than over every eight
    /// bytes.
    pub(crate) fn absorb(&mut self, data: &[u8]) {
        let mut data = data;

        while !data.is_empty() {
            let run = (RATE - self.offset).min(data.len());
            let (block, rest) = data.split_at(run);

            self.state.xor_block(self.offset, block);
            self.offset += run;
            data = rest;

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
    /// to extend the output (the XOF contract). Block-at-a-time, as
    /// [`absorb`][Sponge::absorb].
    pub(crate) fn squeeze(&mut self, out: &mut [u8]) {
        let mut out = out;

        while !out.is_empty() {
            if self.offset == RATE {
                self.state.permute();
                self.offset = 0;
            }

            let run = (RATE - self.offset).min(out.len());
            let (block, rest) = core::mem::take(&mut out).split_at_mut(run);

            self.state.read_block(self.offset, block);
            self.offset += run;
            out = rest;
        }
    }

    /// XORs `byte` into the state at byte position `pos` (little-endian within
    /// its lane).
    fn xor_byte(&mut self, pos: usize, byte: u8) {
        self.state
            .xor_lane(pos / 8, u64::from(byte) << (8 * (pos % 8)));
    }
}

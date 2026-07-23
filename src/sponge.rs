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
    /// Whole 8-byte lanes are XORed at once wherever the cursor is
    /// lane-aligned (`RATE` is always a multiple of 8, so an aligned lane
    /// never straddles the rate boundary); ragged head and tail bytes go
    /// through the byte path.
    pub(crate) fn absorb(&mut self, data: &[u8]) {
        let mut data = data;

        while self.offset % 8 != 0 {
            let Some((&byte, rest)) = data.split_first() else {
                return;
            };
            self.absorb_byte(byte);
            data = rest;
        }

        while let Some((lane_bytes, rest)) = data.split_first_chunk::<8>() {
            self.state
                .xor_lane(self.offset / 8, u64::from_le_bytes(*lane_bytes));
            self.offset += 8;
            data = rest;

            if self.offset == RATE {
                self.state.permute();
                self.offset = 0;
            }
        }

        for &byte in data {
            self.absorb_byte(byte);
        }
    }

    /// Absorbs one byte at the cursor, permuting on a full rate block.
    fn absorb_byte(&mut self, byte: u8) {
        self.xor_byte(self.offset, byte);
        self.offset += 1;

        if self.offset == RATE {
            self.state.permute();
            self.offset = 0;
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
    /// to extend the output (the XOF contract). Whole lanes are copied at once
    /// wherever the cursor is lane-aligned, as in [`absorb`][Sponge::absorb].
    pub(crate) fn squeeze(&mut self, out: &mut [u8]) {
        let mut out = out;

        while !out.is_empty() {
            if self.offset == RATE {
                self.state.permute();
                self.offset = 0;
            }

            let taken = core::mem::take(&mut out);
            if self.offset % 8 == 0 && taken.len() >= 8 {
                let (slot, rest) = taken.split_at_mut(8);
                slot.copy_from_slice(&self.state.lane(self.offset / 8).to_le_bytes());
                self.offset += 8;
                out = rest;
            } else {
                let lane = self.state.lane(self.offset / 8);
                let Some((slot, rest)) = taken.split_first_mut() else {
                    return;
                };
                *slot = (lane >> (8 * (self.offset % 8))) as u8;
                self.offset += 1;
                out = rest;
            }
        }
    }

    /// XORs `byte` into the state at byte position `pos` (little-endian within
    /// its lane).
    fn xor_byte(&mut self, pos: usize, byte: u8) {
        self.state
            .xor_lane(pos / 8, u64::from(byte) << (8 * (pos % 8)));
    }
}

//! Raw `Keccak-f[1600]` entry points, behind the `expose-internals` feature.
//!
//! The sponge is what this crate offers; these are the bare permutations under
//! it, published only so `benches/permutation.rs` and cross-implementation
//! comparisons can time the kernel without a sponge around it. `#[doc(hidden)]`
//! and outside the semver contract — the arch dispatch behind them is free to
//! change.

use crate::backend::{self, Batch};

/// Applies the 24-round permutation to one state, lane `(x, y)` at index
/// `x + 5*y`, each lane little-endian.
pub fn keccak_f1600(lanes: &mut [u64; 25]) {
    backend::permute(lanes);
}

/// Applies the 24-round permutation to two independent states at once — the
/// batched path behind [`Shake128X2`](crate::Shake128X2) and
/// [`Shake256X2`](crate::Shake256X2).
pub fn keccak_f1600_x2(states: &mut [[u64; 25]; 2]) {
    states.permute();
}

/// Applies the 24-round permutation to eight independent states at once — the
/// batched path behind [`Shake128X8`](crate::Shake128X8) and
/// [`Shake256X8`](crate::Shake256X8).
pub fn keccak_f1600_x8(states: &mut [[u64; 25]; 8]) {
    states.permute();
}

/// Applies the 24-round permutation to four independent states at once — the
/// batched path behind [`Shake128X4`](crate::Shake128X4) and
/// [`Shake256X4`](crate::Shake256X4).
pub fn keccak_f1600_x4(states: &mut [[u64; 25]; 4]) {
    states.permute();
}

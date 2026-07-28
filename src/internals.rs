//! Raw `Keccak-f[1600]` entry points, behind the `expose-internals` feature.
//!
//! The sponge is what this crate offers; these are the bare permutations under
//! it, published only so `benches/permutation.rs` and cross-implementation
//! comparisons can time the kernel without a sponge around it. `#[doc(hidden)]`
//! and outside the semver contract — the arch dispatch behind them is free to
//! change.

use crate::backend;

/// Applies the 24-round permutation to one state, lane `(x, y)` at index
/// `x + 5*y`, each lane little-endian.
pub fn keccak_f1600(lanes: &mut [u64; 25]) {
    backend::permute(lanes);
}

/// Applies the 24-round permutation to four independent states at once — the
/// batched path behind [`Shake128X4`](crate::Shake128X4) and
/// [`Shake256X4`](crate::Shake256X4).
pub fn keccak_f1600_x4(states: &mut [[u64; 25]; 4]) {
    backend::permute_x4(states);
}

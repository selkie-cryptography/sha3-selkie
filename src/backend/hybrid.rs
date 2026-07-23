//! Hybrid scalar/NEON four-way `Keccak-f[1600]` backend for non-Apple
//! aarch64 cores.
//!
//! Cores before Cortex-X4 (and Graviton-class servers) issue the SHA-3
//! instructions on a subset of the SIMD units, leaving the scalar pipes
//! idle during a pure-NEON batched permutation. The kernel in
//! `keccak_x4_hybrid.s` advances states 0 and 1 in NEON woven with states
//! 2 and 3 in general-purpose registers, two scalar rounds per vector
//! round, one scalar state per pass. The scalar rounds keep every rho
//! rotation on a logical's free `ror`-operand under a stationary per-lane
//! frame assignment with zero materialized rotates per steady round.
//! Apple cores never dispatch here: their SHA-3 instructions issue on all
//! four SIMD units and the pure-NEON pairs win.

use core::arch::global_asm;

use super::scalar::ROUND_CONSTANTS;

global_asm!(include_str!("keccak_x4_hybrid.s"));

extern "C" {
    /// The generated kernel: `state` points to four sequential 25-lane
    /// states (100 `u64`s), `rc` to the 24 round constants.
    fn keccak_f1600_x4_hybrid(state: *mut u64, rc: *const u64);
}

/// Permutes four independent states at once: two in NEON, two in scalar
/// registers, in one interleaved kernel.
pub(crate) fn permute_x4(states: &mut [[u64; 25]; 4]) {
    // SAFETY: `states` is exactly the contiguous 100-u64 buffer the kernel
    // reads and writes; `sha3_selkie_hybrid` implies NEON + FEAT_SHA3.
    unsafe {
        keccak_f1600_x4_hybrid(states.as_mut_ptr().cast::<u64>(), ROUND_CONSTANTS.as_ptr());
    }
}

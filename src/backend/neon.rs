//! Arm SHA-3 extension `Keccak-f[1600]` backends.
//!
//! Single-stream stays on the scalar permutation: rho's 25 rotation offsets are
//! all distinct, so `XAR` (one shared rotate immediate per vector) cannot
//! parallelize it, and Apple's scalar rotates already saturate that step.
//!
//! [`permute_pair`] takes the batched path: two independent Keccak states
//! packed into the two lanes of every vector, where the same lane position
//! shares a rho offset. `EOR3`, `RAX1`, `XAR`, and `BCAX` then each advance
//! both states at once with no cross-lane shuffles — the two-way permutation
//! behind the `Shake128X4` / `Shake256X4` matrix-expansion and PRF paths.

use core::arch::aarch64::{
    uint64x2_t, vbcaxq_u64, vdupq_n_u64, veor3q_u64, veorq_u64, vgetq_lane_u64, vrax1q_u64,
    vsetq_lane_u64, vxarq_u64,
};

use super::scalar::ROUND_CONSTANTS;

/// Applies the single-stream 24-round permutation in place.
///
/// Delegates to the scalar backend: a single-stream `XAR` wastes a lane, so it
/// cannot beat the scalar rotates on this microarchitecture.
pub(crate) fn permute(lanes: &mut [u64; 25]) {
    super::scalar::permute(lanes);
}

/// Permutes two independent states together, one per vector lane.
///
/// Packs `a` into lane 0 and `b` into lane 1, runs the two-way permutation, and
/// writes the results back. The pack/unpack is amortized over the 24 rounds.
#[allow(
    clippy::indexing_slicing,
    reason = "every index is a compile-time lane constant `< 25`"
)]
pub(crate) fn permute_pair(a: &mut [u64; 25], b: &mut [u64; 25]) {
    // SAFETY: `sha3_selkie_ext` is set only when the target enables the `sha3`
    // feature, so the FEAT_SHA3 intrinsics below are always available here.
    unsafe {
        let mut s = [vdupq_n_u64(0); 25];
        for i in 0..25 {
            s[i] = vsetq_lane_u64::<1>(b[i], vdupq_n_u64(a[i]));
        }

        keccak_f1600_x2(&mut s);

        for i in 0..25 {
            a[i] = vgetq_lane_u64::<0>(s[i]);
            b[i] = vgetq_lane_u64::<1>(s[i]);
        }
    }
}

/// The two-way batched 24-round permutation over the packed state.
///
/// # Safety
///
/// Requires the `sha3` target feature (guaranteed by the `sha3_selkie_ext` cfg
/// gating this module).
#[target_feature(enable = "sha3")]
#[allow(
    clippy::indexing_slicing,
    reason = "every index is a compile-time lane constant `< 25`"
)]
unsafe fn keccak_f1600_x2(s: &mut [uint64x2_t; 25]) {
    for &rc in &ROUND_CONSTANTS {
        // theta: column parities via EOR3, then D via RAX1 (a ^ rol(b, 1)).
        let c0 = veor3q_u64(veor3q_u64(s[0], s[5], s[10]), s[15], s[20]);
        let c1 = veor3q_u64(veor3q_u64(s[1], s[6], s[11]), s[16], s[21]);
        let c2 = veor3q_u64(veor3q_u64(s[2], s[7], s[12]), s[17], s[22]);
        let c3 = veor3q_u64(veor3q_u64(s[3], s[8], s[13]), s[18], s[23]);
        let c4 = veor3q_u64(veor3q_u64(s[4], s[9], s[14]), s[19], s[24]);

        let d0 = vrax1q_u64(c4, c1);
        let d1 = vrax1q_u64(c0, c2);
        let d2 = vrax1q_u64(c1, c3);
        let d3 = vrax1q_u64(c2, c4);
        let d4 = vrax1q_u64(c3, c0);

        // theta fold + rho + pi via XAR: b[pi(x,y)] = ror(s[x,y] ^ d[x], 64 - rho).
        let mut b = [vdupq_n_u64(0); 25];
        b[0] = vxarq_u64::<0>(s[0], d0);
        b[10] = vxarq_u64::<63>(s[1], d1);
        b[20] = vxarq_u64::<2>(s[2], d2);
        b[5] = vxarq_u64::<36>(s[3], d3);
        b[15] = vxarq_u64::<37>(s[4], d4);
        b[16] = vxarq_u64::<28>(s[5], d0);
        b[1] = vxarq_u64::<20>(s[6], d1);
        b[11] = vxarq_u64::<58>(s[7], d2);
        b[21] = vxarq_u64::<9>(s[8], d3);
        b[6] = vxarq_u64::<44>(s[9], d4);
        b[7] = vxarq_u64::<61>(s[10], d0);
        b[17] = vxarq_u64::<54>(s[11], d1);
        b[2] = vxarq_u64::<21>(s[12], d2);
        b[12] = vxarq_u64::<39>(s[13], d3);
        b[22] = vxarq_u64::<25>(s[14], d4);
        b[23] = vxarq_u64::<23>(s[15], d0);
        b[8] = vxarq_u64::<19>(s[16], d1);
        b[18] = vxarq_u64::<49>(s[17], d2);
        b[3] = vxarq_u64::<43>(s[18], d3);
        b[13] = vxarq_u64::<56>(s[19], d4);
        b[14] = vxarq_u64::<46>(s[20], d0);
        b[24] = vxarq_u64::<62>(s[21], d1);
        b[9] = vxarq_u64::<3>(s[22], d2);
        b[19] = vxarq_u64::<8>(s[23], d3);
        b[4] = vxarq_u64::<50>(s[24], d4);

        // chi via BCAX: A[x] = B[x] ^ (~B[x+1] & B[x+2]) = bcax(B[x], B[x+2], B[x+1]).
        for row in 0..5 {
            let base = 5 * row;
            s[base] = vbcaxq_u64(b[base], b[base + 2], b[base + 1]);
            s[base + 1] = vbcaxq_u64(b[base + 1], b[base + 3], b[base + 2]);
            s[base + 2] = vbcaxq_u64(b[base + 2], b[base + 4], b[base + 3]);
            s[base + 3] = vbcaxq_u64(b[base + 3], b[base], b[base + 4]);
            s[base + 4] = vbcaxq_u64(b[base + 4], b[base + 1], b[base]);
        }

        // iota: the round constant is identical in both lanes.
        s[0] = veorq_u64(s[0], vdupq_n_u64(rc));
    }
}

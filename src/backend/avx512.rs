//! AVX-512 four-way and eight-way batched `Keccak-f[1600]` backends.
//!
//! Four independent states, one per 64-bit lane of each `__m256i`, as in
//! the AVX2 backend. `vpternlogq` computes any three-input boolean in one
//! instruction: chi is one ternlog (truth table `0xD2`), a three-way xor
//! one (`0x96`). `vprolq` rotates natively. With no rotate fusions,
//! theta's D-lanes and the theta-fold + rho stay two ops: ~95 instructions
//! per round against AVX2's ~180. 256 bits (VL) rather than 512, which the
//! four-way layout does not need and which downclocks older Intel cores.
//!
//! The eight-way path runs that same round body at 512 bits, eight states in
//! the 64-bit lanes of each register, packed by three 8x8 transposes. Twice
//! the streams advance for an unchanged per-round instruction count.

#![allow(
    clippy::incompatible_msrv,
    reason = "the AVX-512 intrinsics stabilized in Rust 1.89; this module \
              compiles only when the avx512 target features are enabled, \
              above the default-config MSRV"
)]

use core::arch::x86_64::{
    __m256i, __m512i, _mm256_loadu_si256, _mm256_permute2x128_si256, _mm256_rol_epi64,
    _mm256_set_epi64x, _mm256_set1_epi64x, _mm256_setzero_si256, _mm256_storeu_si256,
    _mm256_ternarylogic_epi64, _mm256_unpackhi_epi64, _mm256_unpacklo_epi64, _mm256_xor_si256,
    _mm512_loadu_si512, _mm512_rol_epi64, _mm512_set_epi64, _mm512_set1_epi64,
    _mm512_setzero_si512, _mm512_shuffle_i64x2, _mm512_storeu_si512, _mm512_ternarylogic_epi64,
    _mm512_unpackhi_epi64, _mm512_unpacklo_epi64, _mm512_xor_si512,
};

use super::scalar::ROUND_CONSTANTS;

/// Three-way xor in one `vpternlogq` (truth table `0x96`).
///
/// # Safety
///
/// AVX-512F + VL only.
#[inline]
unsafe fn xor3(a: __m256i, b: __m256i, c: __m256i) -> __m256i {
    _mm256_ternarylogic_epi64::<0x96>(a, b, c)
}

/// Chi's `a ^ (!b & c)` in one `vpternlogq` (truth table `0xD2`).
///
/// # Safety
///
/// AVX-512F + VL only.
#[inline]
unsafe fn chi(a: __m256i, b: __m256i, c: __m256i) -> __m256i {
    _mm256_ternarylogic_epi64::<0xD2>(a, b, c)
}

/// Applies the 24-round permutation to four independent states at once, one
/// per 64-bit lane of each vector.
#[allow(
    clippy::indexing_slicing,
    reason = "every index is a compile-time lane constant `< 25`"
)]
pub(crate) fn permute_x4(states: &mut [[u64; 25]; 4]) {
    // SAFETY: `sha3_selkie_avx512` is set only when the target enables
    // AVX-512F and VL, so these intrinsics are available; every load and
    // store below stays within the four 25-lane states.
    unsafe {
        // Pack via 4x4 transposes, as in the AVX2 backend (the network is
        // its own inverse; the odd lane 24 packs alone).
        let mut s = [_mm256_setzero_si256(); 25];
        for i in (0..24).step_by(4) {
            let r0 = _mm256_loadu_si256(states[0][i..].as_ptr().cast());
            let r1 = _mm256_loadu_si256(states[1][i..].as_ptr().cast());
            let r2 = _mm256_loadu_si256(states[2][i..].as_ptr().cast());
            let r3 = _mm256_loadu_si256(states[3][i..].as_ptr().cast());
            let t0 = _mm256_unpacklo_epi64(r0, r1);
            let t1 = _mm256_unpackhi_epi64(r0, r1);
            let t2 = _mm256_unpacklo_epi64(r2, r3);
            let t3 = _mm256_unpackhi_epi64(r2, r3);
            s[i] = _mm256_permute2x128_si256::<0x20>(t0, t2);
            s[i + 1] = _mm256_permute2x128_si256::<0x20>(t1, t3);
            s[i + 2] = _mm256_permute2x128_si256::<0x31>(t0, t2);
            s[i + 3] = _mm256_permute2x128_si256::<0x31>(t1, t3);
        }
        s[24] = _mm256_set_epi64x(
            states[3][24] as i64,
            states[2][24] as i64,
            states[1][24] as i64,
            states[0][24] as i64,
        );

        for &rc in &ROUND_CONSTANTS {
            // theta: column parities, then D = C[x-1] ^ rol(C[x+1], 1).
            let c0 = xor3(xor3(s[0], s[5], s[10]), s[15], s[20]);
            let c1 = xor3(xor3(s[1], s[6], s[11]), s[16], s[21]);
            let c2 = xor3(xor3(s[2], s[7], s[12]), s[17], s[22]);
            let c3 = xor3(xor3(s[3], s[8], s[13]), s[18], s[23]);
            let c4 = xor3(xor3(s[4], s[9], s[14]), s[19], s[24]);

            let d0 = _mm256_xor_si256(c4, _mm256_rol_epi64::<1>(c1));
            let d1 = _mm256_xor_si256(c0, _mm256_rol_epi64::<1>(c2));
            let d2 = _mm256_xor_si256(c1, _mm256_rol_epi64::<1>(c3));
            let d3 = _mm256_xor_si256(c2, _mm256_rol_epi64::<1>(c4));
            let d4 = _mm256_xor_si256(c3, _mm256_rol_epi64::<1>(c0));

            // theta fold + rho + pi: b[pi(x, y)] = rol(s ^ d, rho); lane 0's
            // zero rotate drops out.
            let mut b = [_mm256_setzero_si256(); 25];
            b[0] = _mm256_xor_si256(s[0], d0);
            b[10] = _mm256_rol_epi64::<1>(_mm256_xor_si256(s[1], d1));
            b[20] = _mm256_rol_epi64::<62>(_mm256_xor_si256(s[2], d2));
            b[5] = _mm256_rol_epi64::<28>(_mm256_xor_si256(s[3], d3));
            b[15] = _mm256_rol_epi64::<27>(_mm256_xor_si256(s[4], d4));
            b[16] = _mm256_rol_epi64::<36>(_mm256_xor_si256(s[5], d0));
            b[1] = _mm256_rol_epi64::<44>(_mm256_xor_si256(s[6], d1));
            b[11] = _mm256_rol_epi64::<6>(_mm256_xor_si256(s[7], d2));
            b[21] = _mm256_rol_epi64::<55>(_mm256_xor_si256(s[8], d3));
            b[6] = _mm256_rol_epi64::<20>(_mm256_xor_si256(s[9], d4));
            b[7] = _mm256_rol_epi64::<3>(_mm256_xor_si256(s[10], d0));
            b[17] = _mm256_rol_epi64::<10>(_mm256_xor_si256(s[11], d1));
            b[2] = _mm256_rol_epi64::<43>(_mm256_xor_si256(s[12], d2));
            b[12] = _mm256_rol_epi64::<25>(_mm256_xor_si256(s[13], d3));
            b[22] = _mm256_rol_epi64::<39>(_mm256_xor_si256(s[14], d4));
            b[23] = _mm256_rol_epi64::<41>(_mm256_xor_si256(s[15], d0));
            b[8] = _mm256_rol_epi64::<45>(_mm256_xor_si256(s[16], d1));
            b[18] = _mm256_rol_epi64::<15>(_mm256_xor_si256(s[17], d2));
            b[3] = _mm256_rol_epi64::<21>(_mm256_xor_si256(s[18], d3));
            b[13] = _mm256_rol_epi64::<8>(_mm256_xor_si256(s[19], d4));
            b[14] = _mm256_rol_epi64::<18>(_mm256_xor_si256(s[20], d0));
            b[24] = _mm256_rol_epi64::<2>(_mm256_xor_si256(s[21], d1));
            b[9] = _mm256_rol_epi64::<61>(_mm256_xor_si256(s[22], d2));
            b[19] = _mm256_rol_epi64::<56>(_mm256_xor_si256(s[23], d3));
            b[4] = _mm256_rol_epi64::<14>(_mm256_xor_si256(s[24], d4));

            // chi: one ternlog per lane.
            for row in 0..5 {
                let base = 5 * row;
                s[base] = chi(b[base], b[base + 1], b[base + 2]);
                s[base + 1] = chi(b[base + 1], b[base + 2], b[base + 3]);
                s[base + 2] = chi(b[base + 2], b[base + 3], b[base + 4]);
                s[base + 3] = chi(b[base + 3], b[base + 4], b[base]);
                s[base + 4] = chi(b[base + 4], b[base], b[base + 1]);
            }

            // iota: broadcast the round constant into all four lanes.
            s[0] = _mm256_xor_si256(s[0], _mm256_set1_epi64x(rc as i64));
        }

        // Unpack: the same transpose network back to state-major rows.
        for i in (0..24).step_by(4) {
            let t0 = _mm256_unpacklo_epi64(s[i], s[i + 1]);
            let t1 = _mm256_unpackhi_epi64(s[i], s[i + 1]);
            let t2 = _mm256_unpacklo_epi64(s[i + 2], s[i + 3]);
            let t3 = _mm256_unpackhi_epi64(s[i + 2], s[i + 3]);
            _mm256_storeu_si256(
                states[0][i..].as_mut_ptr().cast(),
                _mm256_permute2x128_si256::<0x20>(t0, t2),
            );
            _mm256_storeu_si256(
                states[1][i..].as_mut_ptr().cast(),
                _mm256_permute2x128_si256::<0x20>(t1, t3),
            );
            _mm256_storeu_si256(
                states[2][i..].as_mut_ptr().cast(),
                _mm256_permute2x128_si256::<0x31>(t0, t2),
            );
            _mm256_storeu_si256(
                states[3][i..].as_mut_ptr().cast(),
                _mm256_permute2x128_si256::<0x31>(t1, t3),
            );
        }
        let mut last = [0u64; 4];
        _mm256_storeu_si256(last.as_mut_ptr().cast(), s[24]);
        states[0][24] = last[0];
        states[1][24] = last[1];
        states[2][24] = last[2];
        states[3][24] = last[3];
    }
}

/// Transposes an 8x8 block of 64-bit lanes.
///
/// Three stages: interleave within 128-bit lanes, then combine 128-bit lanes,
/// then 256-bit halves. The network is its own inverse, so packing and
/// unpacking share it.
///
/// # Safety
///
/// AVX-512F only.
#[inline]
unsafe fn transpose8(r: [__m512i; 8]) -> [__m512i; 8] {
    let [r0, r1, r2, r3, r4, r5, r6, r7] = r;

    // Interleave within each 128-bit lane.
    let t0 = _mm512_unpacklo_epi64(r0, r1);
    let t1 = _mm512_unpackhi_epi64(r0, r1);
    let t2 = _mm512_unpacklo_epi64(r2, r3);
    let t3 = _mm512_unpackhi_epi64(r2, r3);
    let t4 = _mm512_unpacklo_epi64(r4, r5);
    let t5 = _mm512_unpackhi_epi64(r4, r5);
    let t6 = _mm512_unpacklo_epi64(r6, r7);
    let t7 = _mm512_unpackhi_epi64(r6, r7);

    // Combine 128-bit lanes.
    let u0 = _mm512_shuffle_i64x2::<0x88>(t0, t2);
    let u1 = _mm512_shuffle_i64x2::<0x88>(t1, t3);
    let u2 = _mm512_shuffle_i64x2::<0xDD>(t0, t2);
    let u3 = _mm512_shuffle_i64x2::<0xDD>(t1, t3);
    let u4 = _mm512_shuffle_i64x2::<0x88>(t4, t6);
    let u5 = _mm512_shuffle_i64x2::<0x88>(t5, t7);
    let u6 = _mm512_shuffle_i64x2::<0xDD>(t4, t6);
    let u7 = _mm512_shuffle_i64x2::<0xDD>(t5, t7);

    // Combine 256-bit halves.
    [
        _mm512_shuffle_i64x2::<0x88>(u0, u4),
        _mm512_shuffle_i64x2::<0x88>(u1, u5),
        _mm512_shuffle_i64x2::<0x88>(u2, u6),
        _mm512_shuffle_i64x2::<0x88>(u3, u7),
        _mm512_shuffle_i64x2::<0xDD>(u0, u4),
        _mm512_shuffle_i64x2::<0xDD>(u1, u5),
        _mm512_shuffle_i64x2::<0xDD>(u2, u6),
        _mm512_shuffle_i64x2::<0xDD>(u3, u7),
    ]
}

/// Three-way xor over eight lanes, one `vpternlogq`.
///
/// # Safety
///
/// AVX-512F only.
#[inline]
unsafe fn xor3_x8(a: __m512i, b: __m512i, c: __m512i) -> __m512i {
    _mm512_ternarylogic_epi64::<0x96>(a, b, c)
}

/// Chi's `a ^ (!b & c)` over eight lanes, one `vpternlogq`.
///
/// # Safety
///
/// AVX-512F only.
#[inline]
unsafe fn chi_x8(a: __m512i, b: __m512i, c: __m512i) -> __m512i {
    _mm512_ternarylogic_epi64::<0xD2>(a, b, c)
}

/// Applies the 24-round permutation to eight independent states at once, one
/// per 64-bit lane of each 512-bit vector.
///
/// The same round body as [`permute_x4`] at twice the width: a 512-bit
/// register holds eight Keccak states, so the per-round instruction count is
/// unchanged while twice the streams advance.
#[allow(
    clippy::indexing_slicing,
    reason = "every index is a compile-time lane constant `< 25`"
)]
pub(crate) fn permute_x8(states: &mut [[u64; 25]; 8]) {
    // SAFETY: `sha3_selkie_avx512` is set only when the target enables
    // AVX-512F, so these intrinsics are available; every load and store below
    // stays within the eight 25-lane states.
    unsafe {
        // Pack lanes 0..24 as three 8x8 transposes; lane 24 packs alone.
        let mut s = [_mm512_setzero_si512(); 25];
        for i in (0..24).step_by(8) {
            let rows: [__m512i; 8] =
                core::array::from_fn(|j| _mm512_loadu_si512(states[j][i..].as_ptr().cast()));
            let packed = transpose8(rows);

            for (k, lane) in packed.into_iter().enumerate() {
                s[i + k] = lane;
            }
        }
        s[24] = _mm512_set_epi64(
            states[7][24] as i64,
            states[6][24] as i64,
            states[5][24] as i64,
            states[4][24] as i64,
            states[3][24] as i64,
            states[2][24] as i64,
            states[1][24] as i64,
            states[0][24] as i64,
        );

        for &rc in &ROUND_CONSTANTS {
            // theta: column parities, then D = C[x-1] ^ rol(C[x+1], 1).
            let c0 = xor3_x8(xor3_x8(s[0], s[5], s[10]), s[15], s[20]);
            let c1 = xor3_x8(xor3_x8(s[1], s[6], s[11]), s[16], s[21]);
            let c2 = xor3_x8(xor3_x8(s[2], s[7], s[12]), s[17], s[22]);
            let c3 = xor3_x8(xor3_x8(s[3], s[8], s[13]), s[18], s[23]);
            let c4 = xor3_x8(xor3_x8(s[4], s[9], s[14]), s[19], s[24]);

            let d0 = _mm512_xor_si512(c4, _mm512_rol_epi64::<1>(c1));
            let d1 = _mm512_xor_si512(c0, _mm512_rol_epi64::<1>(c2));
            let d2 = _mm512_xor_si512(c1, _mm512_rol_epi64::<1>(c3));
            let d3 = _mm512_xor_si512(c2, _mm512_rol_epi64::<1>(c4));
            let d4 = _mm512_xor_si512(c3, _mm512_rol_epi64::<1>(c0));

            // theta fold + rho + pi: b[pi(x, y)] = rol(s ^ d, rho); lane 0's
            // zero rotate drops out.
            let mut b = [_mm512_setzero_si512(); 25];
            b[0] = _mm512_xor_si512(s[0], d0);
            b[10] = _mm512_rol_epi64::<1>(_mm512_xor_si512(s[1], d1));
            b[20] = _mm512_rol_epi64::<62>(_mm512_xor_si512(s[2], d2));
            b[5] = _mm512_rol_epi64::<28>(_mm512_xor_si512(s[3], d3));
            b[15] = _mm512_rol_epi64::<27>(_mm512_xor_si512(s[4], d4));
            b[16] = _mm512_rol_epi64::<36>(_mm512_xor_si512(s[5], d0));
            b[1] = _mm512_rol_epi64::<44>(_mm512_xor_si512(s[6], d1));
            b[11] = _mm512_rol_epi64::<6>(_mm512_xor_si512(s[7], d2));
            b[21] = _mm512_rol_epi64::<55>(_mm512_xor_si512(s[8], d3));
            b[6] = _mm512_rol_epi64::<20>(_mm512_xor_si512(s[9], d4));
            b[7] = _mm512_rol_epi64::<3>(_mm512_xor_si512(s[10], d0));
            b[17] = _mm512_rol_epi64::<10>(_mm512_xor_si512(s[11], d1));
            b[2] = _mm512_rol_epi64::<43>(_mm512_xor_si512(s[12], d2));
            b[12] = _mm512_rol_epi64::<25>(_mm512_xor_si512(s[13], d3));
            b[22] = _mm512_rol_epi64::<39>(_mm512_xor_si512(s[14], d4));
            b[23] = _mm512_rol_epi64::<41>(_mm512_xor_si512(s[15], d0));
            b[8] = _mm512_rol_epi64::<45>(_mm512_xor_si512(s[16], d1));
            b[18] = _mm512_rol_epi64::<15>(_mm512_xor_si512(s[17], d2));
            b[3] = _mm512_rol_epi64::<21>(_mm512_xor_si512(s[18], d3));
            b[13] = _mm512_rol_epi64::<8>(_mm512_xor_si512(s[19], d4));
            b[14] = _mm512_rol_epi64::<18>(_mm512_xor_si512(s[20], d0));
            b[24] = _mm512_rol_epi64::<2>(_mm512_xor_si512(s[21], d1));
            b[9] = _mm512_rol_epi64::<61>(_mm512_xor_si512(s[22], d2));
            b[19] = _mm512_rol_epi64::<56>(_mm512_xor_si512(s[23], d3));
            b[4] = _mm512_rol_epi64::<14>(_mm512_xor_si512(s[24], d4));

            // chi: one ternlog per lane.
            for row in 0..5 {
                let base = 5 * row;
                s[base] = chi_x8(b[base], b[base + 1], b[base + 2]);
                s[base + 1] = chi_x8(b[base + 1], b[base + 2], b[base + 3]);
                s[base + 2] = chi_x8(b[base + 2], b[base + 3], b[base + 4]);
                s[base + 3] = chi_x8(b[base + 3], b[base + 4], b[base]);
                s[base + 4] = chi_x8(b[base + 4], b[base], b[base + 1]);
            }

            // iota: broadcast the round constant into all eight lanes.
            s[0] = _mm512_xor_si512(s[0], _mm512_set1_epi64(rc as i64));
        }

        // Unpack: the same transpose network back to state-major rows.
        for i in (0..24).step_by(8) {
            let lanes: [__m512i; 8] = core::array::from_fn(|k| s[i + k]);
            let rows = transpose8(lanes);

            for (j, row) in rows.into_iter().enumerate() {
                _mm512_storeu_si512(states[j][i..].as_mut_ptr().cast(), row);
            }
        }
        let mut last = [0u64; 8];
        _mm512_storeu_si512(last.as_mut_ptr().cast(), s[24]);
        for (state, lane) in states.iter_mut().zip(last) {
            state[24] = lane;
        }
    }
}

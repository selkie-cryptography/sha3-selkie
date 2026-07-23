//! AVX2 four-way batched `Keccak-f[1600]` backend.
//!
//! Four independent states occupy the four 64-bit lanes of every `__m256i`, so
//! one permutation advances all four lanes of `Shake128X4` / `Shake256X4` at
//! once. AVX2 has no three-way XOR, no bit-clear-XOR, and no 64-bit vector
//! rotate, so theta is plain XORs, chi is `andnot` + `xor`, and a general
//! rotate is a shift-left / shift-right / or — except where rho lands on a
//! multiple of 8 (lanes 19 and 23), where one `vpshufb` byte shuffle rotates
//! in a single op, and lane 0's zero rotate, which drops out entirely. The
//! structure mirrors the two-way NEON permutation, cross-checked lane for
//! lane against the scalar reference.

use core::arch::x86_64::{
    __m256i, _mm256_andnot_si256, _mm256_extract_epi64, _mm256_loadu_si256, _mm256_or_si256,
    _mm256_permute2x128_si256, _mm256_set_epi8, _mm256_set_epi64x, _mm256_set1_epi64x,
    _mm256_setzero_si256, _mm256_shuffle_epi8, _mm256_slli_epi64, _mm256_srli_epi64,
    _mm256_storeu_si256, _mm256_unpackhi_epi64, _mm256_unpacklo_epi64, _mm256_xor_si256,
};

use super::scalar::ROUND_CONSTANTS;

/// Rotates each 64-bit lane left by `SHL`, with `SHR` = `64 - SHL` supplied by
/// the caller (stable Rust cannot compute `64 - SHL` in const-generic
/// position).
///
/// # Safety
///
/// AVX2 only.
#[inline]
unsafe fn rol<const SHL: i32, const SHR: i32>(v: __m256i) -> __m256i {
    _mm256_or_si256(_mm256_slli_epi64::<SHL>(v), _mm256_srli_epi64::<SHR>(v))
}

/// Rotates each 64-bit lane left by 8: whole bytes move, so one `vpshufb`
/// replaces the three-op shift pair. `vpshufb` indexes within each 128-bit
/// half, and a qword's bytes stay in their half, so the shuffle never crosses.
///
/// # Safety
///
/// AVX2 only.
#[inline]
unsafe fn rol8(v: __m256i) -> __m256i {
    #[rustfmt::skip]
    let idx = _mm256_set_epi8(
        14, 13, 12, 11, 10, 9, 8, 15, 6, 5, 4, 3, 2, 1, 0, 7,
        14, 13, 12, 11, 10, 9, 8, 15, 6, 5, 4, 3, 2, 1, 0, 7,
    );
    _mm256_shuffle_epi8(v, idx)
}

/// Rotates each 64-bit lane left by 56 (right by 8) via one `vpshufb`; see
/// [`rol8`].
///
/// # Safety
///
/// AVX2 only.
#[inline]
unsafe fn rol56(v: __m256i) -> __m256i {
    #[rustfmt::skip]
    let idx = _mm256_set_epi8(
        8, 15, 14, 13, 12, 11, 10, 9, 0, 7, 6, 5, 4, 3, 2, 1,
        8, 15, 14, 13, 12, 11, 10, 9, 0, 7, 6, 5, 4, 3, 2, 1,
    );
    _mm256_shuffle_epi8(v, idx)
}

/// Applies the 24-round permutation to four independent states at once, one per
/// 64-bit lane of each vector.
#[allow(
    clippy::indexing_slicing,
    reason = "every index is a compile-time lane constant `< 25`"
)]
pub(crate) fn permute_x4(states: &mut [[u64; 25]; 4]) {
    // SAFETY: `sha3_selkie_avx2` is set only when the target enables AVX2, so
    // the whole crate is built with AVX2 and these intrinsics are available.
    unsafe {
        // Pack via 4x4 transposes: four lanes of each state load as one
        // vector, unpack + cross-half permute turn state-major rows into
        // lane-major columns (the network is its own inverse; the odd lane
        // 24 packs alone).
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
            let c0 = xor5(s[0], s[5], s[10], s[15], s[20]);
            let c1 = xor5(s[1], s[6], s[11], s[16], s[21]);
            let c2 = xor5(s[2], s[7], s[12], s[17], s[22]);
            let c3 = xor5(s[3], s[8], s[13], s[18], s[23]);
            let c4 = xor5(s[4], s[9], s[14], s[19], s[24]);

            let d0 = _mm256_xor_si256(c4, rol::<1, 63>(c1));
            let d1 = _mm256_xor_si256(c0, rol::<1, 63>(c2));
            let d2 = _mm256_xor_si256(c1, rol::<1, 63>(c3));
            let d3 = _mm256_xor_si256(c2, rol::<1, 63>(c4));
            let d4 = _mm256_xor_si256(c3, rol::<1, 63>(c0));

            // theta fold + rho + pi: b[pi(x,y)] = rol(s[x,y] ^ d[x], rho); the
            // second const is 64 - rho. Lane 0's rho is 0 (no rotate), and the
            // byte-aligned rho at lanes 19 and 23 take the vpshufb helpers.
            let mut b = [_mm256_setzero_si256(); 25];
            b[0] = _mm256_xor_si256(s[0], d0);
            b[10] = rol::<1, 63>(_mm256_xor_si256(s[1], d1));
            b[20] = rol::<62, 2>(_mm256_xor_si256(s[2], d2));
            b[5] = rol::<28, 36>(_mm256_xor_si256(s[3], d3));
            b[15] = rol::<27, 37>(_mm256_xor_si256(s[4], d4));
            b[16] = rol::<36, 28>(_mm256_xor_si256(s[5], d0));
            b[1] = rol::<44, 20>(_mm256_xor_si256(s[6], d1));
            b[11] = rol::<6, 58>(_mm256_xor_si256(s[7], d2));
            b[21] = rol::<55, 9>(_mm256_xor_si256(s[8], d3));
            b[6] = rol::<20, 44>(_mm256_xor_si256(s[9], d4));
            b[7] = rol::<3, 61>(_mm256_xor_si256(s[10], d0));
            b[17] = rol::<10, 54>(_mm256_xor_si256(s[11], d1));
            b[2] = rol::<43, 21>(_mm256_xor_si256(s[12], d2));
            b[12] = rol::<25, 39>(_mm256_xor_si256(s[13], d3));
            b[22] = rol::<39, 25>(_mm256_xor_si256(s[14], d4));
            b[23] = rol::<41, 23>(_mm256_xor_si256(s[15], d0));
            b[8] = rol::<45, 19>(_mm256_xor_si256(s[16], d1));
            b[18] = rol::<15, 49>(_mm256_xor_si256(s[17], d2));
            b[3] = rol::<21, 43>(_mm256_xor_si256(s[18], d3));
            b[13] = rol8(_mm256_xor_si256(s[19], d4));
            b[14] = rol::<18, 46>(_mm256_xor_si256(s[20], d0));
            b[24] = rol::<2, 62>(_mm256_xor_si256(s[21], d1));
            b[9] = rol::<61, 3>(_mm256_xor_si256(s[22], d2));
            b[19] = rol56(_mm256_xor_si256(s[23], d3));
            b[4] = rol::<14, 50>(_mm256_xor_si256(s[24], d4));

            // chi: A[x] = B[x] ^ (~B[x+1] & B[x+2]) = B[x] ^ andnot(B[x+1], B[x+2]).
            for row in 0..5 {
                let base = 5 * row;
                s[base] = _mm256_xor_si256(b[base], _mm256_andnot_si256(b[base + 1], b[base + 2]));
                s[base + 1] =
                    _mm256_xor_si256(b[base + 1], _mm256_andnot_si256(b[base + 2], b[base + 3]));
                s[base + 2] =
                    _mm256_xor_si256(b[base + 2], _mm256_andnot_si256(b[base + 3], b[base + 4]));
                s[base + 3] =
                    _mm256_xor_si256(b[base + 3], _mm256_andnot_si256(b[base + 4], b[base]));
                s[base + 4] =
                    _mm256_xor_si256(b[base + 4], _mm256_andnot_si256(b[base], b[base + 1]));
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
        states[0][24] = _mm256_extract_epi64::<0>(s[24]) as u64;
        states[1][24] = _mm256_extract_epi64::<1>(s[24]) as u64;
        states[2][24] = _mm256_extract_epi64::<2>(s[24]) as u64;
        states[3][24] = _mm256_extract_epi64::<3>(s[24]) as u64;
    }
}

/// XORs five vectors (a theta column parity).
///
/// # Safety
///
/// AVX2 only.
#[inline]
unsafe fn xor5(a: __m256i, b: __m256i, c: __m256i, d: __m256i, e: __m256i) -> __m256i {
    _mm256_xor_si256(
        _mm256_xor_si256(_mm256_xor_si256(a, b), _mm256_xor_si256(c, d)),
        e,
    )
}

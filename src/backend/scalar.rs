//! Portable scalar `Keccak-f[1600]` permutation.

/// The 24 `Keccak-f[1600]` round constants ([FIPS 202 Section 3.2.5]).
///
/// [FIPS 202 Section 3.2.5]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf#subsubsection.3.2.5
pub(super) const ROUND_CONSTANTS: [u64; 24] = [
    0x0000_0000_0000_0001,
    0x0000_0000_0000_8082,
    0x8000_0000_0000_808A,
    0x8000_0000_8000_8000,
    0x0000_0000_0000_808B,
    0x0000_0000_8000_0001,
    0x8000_0000_8000_8081,
    0x8000_0000_0000_8009,
    0x0000_0000_0000_008A,
    0x0000_0000_0000_0088,
    0x0000_0000_8000_8009,
    0x0000_0000_8000_000A,
    0x0000_0000_8000_808B,
    0x8000_0000_0000_008B,
    0x8000_0000_0000_8089,
    0x8000_0000_0000_8003,
    0x8000_0000_0000_8002,
    0x8000_0000_0000_0080,
    0x0000_0000_0000_800A,
    0x8000_0000_8000_000A,
    0x8000_0000_8000_8081,
    0x8000_0000_0000_8080,
    0x0000_0000_8000_0001,
    0x8000_0000_8000_8008,
];

/// Applies the 24-round permutation in place.
///
/// Fully unrolled with the rho rotation amounts ([FIPS 202 Section 3.2.2])
/// as literals; the looped form spent about as many instructions on loop
/// and index bookkeeping as on the permutation. The structure matches the
/// vector backends: theta parities and D-lanes named, the fold + rho + pi
/// scatter into `b`, chi per row, iota.
///
/// [FIPS 202 Section 3.2.2]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf#subsubsection.3.2.2
// On Apple `sha3_selkie_ext` builds single-stream dispatches to
// `neon::permute`; this stays as the cross-check reference.
#[cfg_attr(
    all(sha3_selkie_ext, not(sha3_selkie_hybrid)),
    allow(dead_code, reason = "the vector single-stream path replaces this")
)]
#[allow(
    clippy::indexing_slicing,
    reason = "every index is a compile-time lane constant `< 25`"
)]
pub(crate) fn permute(lanes: &mut [u64; 25]) {
    for &rc in &ROUND_CONSTANTS {
        // theta: column parities, then D = C[x-1] ^ rol(C[x+1], 1).
        let c0 = lanes[0] ^ lanes[5] ^ lanes[10] ^ lanes[15] ^ lanes[20];
        let c1 = lanes[1] ^ lanes[6] ^ lanes[11] ^ lanes[16] ^ lanes[21];
        let c2 = lanes[2] ^ lanes[7] ^ lanes[12] ^ lanes[17] ^ lanes[22];
        let c3 = lanes[3] ^ lanes[8] ^ lanes[13] ^ lanes[18] ^ lanes[23];
        let c4 = lanes[4] ^ lanes[9] ^ lanes[14] ^ lanes[19] ^ lanes[24];

        let d0 = c4 ^ c1.rotate_left(1);
        let d1 = c0 ^ c2.rotate_left(1);
        let d2 = c1 ^ c3.rotate_left(1);
        let d3 = c2 ^ c4.rotate_left(1);
        let d4 = c3 ^ c0.rotate_left(1);

        // theta fold + rho + pi: b[pi(x, y)] = rol(lane ^ d[x], rho).
        let mut b = [0u64; 25];
        b[0] = lanes[0] ^ d0;
        b[10] = (lanes[1] ^ d1).rotate_left(1);
        b[20] = (lanes[2] ^ d2).rotate_left(62);
        b[5] = (lanes[3] ^ d3).rotate_left(28);
        b[15] = (lanes[4] ^ d4).rotate_left(27);
        b[16] = (lanes[5] ^ d0).rotate_left(36);
        b[1] = (lanes[6] ^ d1).rotate_left(44);
        b[11] = (lanes[7] ^ d2).rotate_left(6);
        b[21] = (lanes[8] ^ d3).rotate_left(55);
        b[6] = (lanes[9] ^ d4).rotate_left(20);
        b[7] = (lanes[10] ^ d0).rotate_left(3);
        b[17] = (lanes[11] ^ d1).rotate_left(10);
        b[2] = (lanes[12] ^ d2).rotate_left(43);
        b[12] = (lanes[13] ^ d3).rotate_left(25);
        b[22] = (lanes[14] ^ d4).rotate_left(39);
        b[23] = (lanes[15] ^ d0).rotate_left(41);
        b[8] = (lanes[16] ^ d1).rotate_left(45);
        b[18] = (lanes[17] ^ d2).rotate_left(15);
        b[3] = (lanes[18] ^ d3).rotate_left(21);
        b[13] = (lanes[19] ^ d4).rotate_left(8);
        b[14] = (lanes[20] ^ d0).rotate_left(18);
        b[24] = (lanes[21] ^ d1).rotate_left(2);
        b[9] = (lanes[22] ^ d2).rotate_left(61);
        b[19] = (lanes[23] ^ d3).rotate_left(56);
        b[4] = (lanes[24] ^ d4).rotate_left(14);

        // chi: A[x] = B[x] ^ (!B[x+1] & B[x+2]), row by row.
        lanes[0] = b[0] ^ (!b[1] & b[2]);
        lanes[1] = b[1] ^ (!b[2] & b[3]);
        lanes[2] = b[2] ^ (!b[3] & b[4]);
        lanes[3] = b[3] ^ (!b[4] & b[0]);
        lanes[4] = b[4] ^ (!b[0] & b[1]);
        lanes[5] = b[5] ^ (!b[6] & b[7]);
        lanes[6] = b[6] ^ (!b[7] & b[8]);
        lanes[7] = b[7] ^ (!b[8] & b[9]);
        lanes[8] = b[8] ^ (!b[9] & b[5]);
        lanes[9] = b[9] ^ (!b[5] & b[6]);
        lanes[10] = b[10] ^ (!b[11] & b[12]);
        lanes[11] = b[11] ^ (!b[12] & b[13]);
        lanes[12] = b[12] ^ (!b[13] & b[14]);
        lanes[13] = b[13] ^ (!b[14] & b[10]);
        lanes[14] = b[14] ^ (!b[10] & b[11]);
        lanes[15] = b[15] ^ (!b[16] & b[17]);
        lanes[16] = b[16] ^ (!b[17] & b[18]);
        lanes[17] = b[17] ^ (!b[18] & b[19]);
        lanes[18] = b[18] ^ (!b[19] & b[15]);
        lanes[19] = b[19] ^ (!b[15] & b[16]);
        lanes[20] = b[20] ^ (!b[21] & b[22]);
        lanes[21] = b[21] ^ (!b[22] & b[23]);
        lanes[22] = b[22] ^ (!b[23] & b[24]);
        lanes[23] = b[23] ^ (!b[24] & b[20]);
        lanes[24] = b[24] ^ (!b[20] & b[21]);

        // iota: break the round symmetry.
        lanes[0] ^= rc;
    }
}

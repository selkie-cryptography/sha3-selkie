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

/// The rho rotation offset per lane `x + 5*y` ([FIPS 202 Section 3.2.2]).
///
/// [FIPS 202 Section 3.2.2]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf#subsubsection.3.2.2
pub(super) const RHO: [u32; 25] = [
    0, 1, 62, 28, 27, //
    36, 44, 6, 55, 20, //
    3, 10, 43, 25, 39, //
    41, 45, 15, 21, 8, //
    18, 2, 61, 56, 14,
];

/// Applies the 24-round permutation in place.
///
/// Every index below is a compile-time-bounded lane coordinate (`x, y < 5`), so
/// the accesses are provably in bounds; the fully-unrolled fixed-index form is
/// ~5x longer and hides the theta/rho/pi/chi/iota structure.
// On `sha3_selkie_ext` builds production dispatches to `neon::permute`; this
// stays as the cross-check reference the backend tests compare against.
#[cfg_attr(sha3_selkie_ext, allow(dead_code))]
#[allow(
    clippy::indexing_slicing,
    reason = "the loop indices are `x + 5*y` with `x, y < 5`"
)]
pub(crate) fn permute(lanes: &mut [u64; 25]) {
    for &rc in &ROUND_CONSTANTS {
        // theta: fold the column parities back into every lane.
        let mut parity = [0u64; 5];
        for x in 0..5 {
            parity[x] = lanes[x] ^ lanes[x + 5] ^ lanes[x + 10] ^ lanes[x + 15] ^ lanes[x + 20];
        }
        let mut theta = [0u64; 5];
        for x in 0..5 {
            theta[x] = parity[(x + 4) % 5] ^ parity[(x + 1) % 5].rotate_left(1);
        }
        for y in 0..5 {
            for x in 0..5 {
                lanes[x + 5 * y] ^= theta[x];
            }
        }

        // rho + pi: rotate each lane, then scatter to its permuted position.
        let mut b = [0u64; 25];
        for y in 0..5 {
            for x in 0..5 {
                b[y + 5 * ((2 * x + 3 * y) % 5)] = lanes[x + 5 * y].rotate_left(RHO[x + 5 * y]);
            }
        }

        // chi: the nonlinear row map.
        for y in 0..5 {
            for x in 0..5 {
                lanes[x + 5 * y] =
                    b[x + 5 * y] ^ ((!b[(x + 1) % 5 + 5 * y]) & b[(x + 2) % 5 + 5 * y]);
            }
        }

        // iota: break the round symmetry.
        lanes[0] ^= rc;
    }
}

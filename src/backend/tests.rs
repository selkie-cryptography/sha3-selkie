//! Backend tests: a raw `Keccak-f[1600]` known-answer vector that exercises the
//! permutation in isolation from the sponge, and a cross-check of the
//! accelerated backend against the portable scalar reference.

use super::scalar;

/// `Keccak-f[1600]` applied to the all-zero state, lane `x + 5*y`, little-endian
/// — the canonical Keccak team test vector. Failing this localizes a permutation
/// bug without the sponge's byte-packing in the way.
#[rustfmt::skip]
const KECCAK_F1600_ZERO_STATE: [u64; 25] = [
    0xF125_8F79_40E1_DDE7, 0x84D5_CCF9_33C0_478A, 0xD598_261E_A65A_A9EE,
    0xBD15_4730_6F80_494D, 0x8B28_4E05_6253_D057, 0xFF97_A42D_7F8E_6FD4,
    0x90FE_E5A0_A446_47C4, 0x8C5B_DA0C_D619_2E76, 0xAD30_A6F7_1B19_059C,
    0x3093_5AB7_D08F_FC64, 0xEB5A_A93F_2317_D635, 0xA9A6_E626_0D71_2103,
    0x81A5_7C16_DBCF_555F, 0x43B8_31CD_0347_C826, 0x01F2_2F1A_11A5_569F,
    0x05E5_635A_21D9_AE61, 0x64BE_FEF2_8CC9_70F2, 0x6136_7095_7BC4_6611,
    0xB87C_5A55_4FD0_0ECB, 0x8C3E_E88A_1CCF_32C8, 0x940C_7922_AE3A_2614,
    0x1841_F924_A2C5_09E4, 0x16F5_3526_E704_65C2, 0x75F6_44E9_7F30_A13B,
    0xEAF1_FF7B_5CEC_A249,
];

/// The scalar permutation reproduces the canonical zero-state vector.
#[test]
fn keccak_f1600_zero_state_kat() {
    let mut state = [0u64; 25];
    scalar::permute(&mut state);

    assert_eq!(state, KECCAK_F1600_ZERO_STATE);
}

/// The accelerated backend must produce bit-identical output to the scalar
/// reference on every state.
///
/// This is the harness that makes vector bring-up tractable: a mis-shuffled
/// SIMD lane fails here, on a raw state, rather than as an opaque wrong digest
/// three layers up in a sponge-level test. It runs wherever `sha3_selkie_ext`
/// is set (the Arm SHA-3 extension, baseline on Apple silicon and on the macOS
/// CI leg). Today the backend delegates to scalar, so it passes trivially and
/// stands ready for the real permutation.
#[cfg(sha3_selkie_ext)]
#[test]
fn ext_backend_matches_scalar() {
    use super::neon;

    // A deterministic xorshift64 so the states are reproducible without a dep.
    let mut seed: u64 = 0x2545_F491_4F6C_DD1D;
    let mut next = || {
        seed ^= seed << 13;
        seed ^= seed >> 7;
        seed ^= seed << 17;
        seed
    };

    for _ in 0..256 {
        let mut state = [0u64; 25];
        for lane in &mut state {
            *lane = next();
        }

        let mut accelerated = state;
        scalar::permute(&mut state);
        neon::permute(&mut accelerated);

        assert_eq!(state, accelerated);
    }
}

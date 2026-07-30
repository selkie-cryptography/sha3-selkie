//! Backend tests: a raw `Keccak-f[1600]` known-answer vector that exercises the
//! permutation in isolation from the sponge, and a cross-check of the
//! accelerated backend against the portable scalar reference.

use core::mem::MaybeUninit;

use super::{Batch, State, scalar, zero_out};

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

/// The four-way batched permutation reproduces the scalar reference on each of
/// its four states, whichever backend it dispatches to (AVX2, two NEON pairs,
/// or four scalar permutes).
#[test]
fn permute_x4_matches_scalar() {
    let mut seed: u64 = 0x243F_6A88_85A3_08D3;
    let mut next = || {
        seed ^= seed << 13;
        seed ^= seed >> 7;
        seed ^= seed << 17;
        seed
    };

    for _ in 0..64 {
        let mut states = [[0u64; 25]; 4];
        for state in &mut states {
            for lane in state.iter_mut() {
                *lane = next();
            }
        }

        let mut expected = states;
        states.permute();
        for state in &mut expected {
            scalar::permute(state);
        }

        assert_eq!(states, expected);
    }
}

/// The two-way batched permutation reproduces the scalar reference on both of
/// its states, whichever backend it dispatches to (the NEON pair kernel, a
/// padded four-way AVX2 permutation, or two scalar permutes).
///
/// Distinct from `batched_pair_matches_scalar`, which pins the NEON kernel
/// itself: this one covers the `Batch` dispatch that `Shake128X2` and
/// `Shake256X2` actually reach, including the x86-64 padding path where a
/// mis-copied lane would otherwise surface only as a wrong digest.
#[test]
fn permute_x2_matches_scalar() {
    let mut seed: u64 = 0xB5AD_4ECE_DA1C_E2A9;
    let mut next = || {
        seed ^= seed << 13;
        seed ^= seed >> 7;
        seed ^= seed << 17;
        seed
    };

    for _ in 0..64 {
        let mut states = [[0u64; 25]; 2];
        for state in &mut states {
            for lane in state.iter_mut() {
                *lane = next();
            }
        }

        let mut expected = states;
        states.permute();
        for state in &mut expected {
            scalar::permute(state);
        }

        assert_eq!(states, expected);
    }
}

/// The eight-way batched permutation reproduces the scalar reference on each
/// of its eight states.
///
/// On AVX-512 this is the only check on the 8x8 transpose that packs the
/// states into 512-bit lanes and unpacks them again: a mis-wired stage would
/// permute whole states against each other, which every state-independent
/// property would otherwise miss. Elsewhere it covers the split into two
/// four-way halves.
#[test]
fn permute_x8_matches_scalar() {
    let mut seed: u64 = 0x0F1E_2D3C_4B5A_6978;
    let mut next = || {
        seed ^= seed << 13;
        seed ^= seed >> 7;
        seed ^= seed << 17;
        seed
    };

    for _ in 0..64 {
        let mut states = [[0u64; 25]; 8];
        for state in &mut states {
            for lane in state.iter_mut() {
                *lane = next();
            }
        }

        let mut expected = states;
        states.permute();
        for state in &mut expected {
            scalar::permute(state);
        }

        assert_eq!(states, expected);
    }
}

/// Eight *distinct* states stay distinct and land in their own slots.
///
/// `permute_x8_matches_scalar` would still pass if the packing transposed the
/// states consistently but assigned them to the wrong output rows, since every
/// state is compared against its own scalar reference only after the fact.
/// Seeding each state with a distinguishable constant catches a permuted
/// assignment directly.
#[test]
fn permute_x8_keeps_states_in_their_lanes() {
    let mut states = [[0u64; 25]; 8];
    for (index, state) in states.iter_mut().enumerate() {
        state[0] = index as u64 + 1;
    }

    let mut expected = states;
    states.permute();
    for state in &mut expected {
        scalar::permute(state);
    }

    for (index, (got, want)) in states.iter().zip(&expected).enumerate() {
        assert_eq!(got, want, "state {index} landed in the wrong lane");
    }
}

/// The single-stream vector backend (the dead-lane two-way kernel) matches
/// the scalar reference on every state.
#[cfg(sha3_selkie_ext)]
#[test]
fn ext_backend_matches_scalar() {
    use super::neon;

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

/// Both states of the two-way batched permutation reproduce the scalar
/// reference on their own lane.
///
/// This is the harness for the batched vector code: a mis-packed or
/// wrong-rotation lane fails here on a raw state pair, rather than as an opaque
/// wrong digest in a `Shake128X4` output.
#[cfg(sha3_selkie_ext)]
#[test]
fn batched_pair_matches_scalar() {
    use super::neon;

    let mut seed: u64 = 0x9E37_79B9_7F4A_7C15;
    let mut next = || {
        seed ^= seed << 13;
        seed ^= seed >> 7;
        seed ^= seed << 17;
        seed
    };

    for _ in 0..256 {
        let mut a = [0u64; 25];
        let mut b = [0u64; 25];
        for (lane_a, lane_b) in a.iter_mut().zip(b.iter_mut()) {
            *lane_a = next();
            *lane_b = next();
        }

        let mut expected_a = a;
        let mut expected_b = b;
        neon::permute_pair(&mut a, &mut b);
        scalar::permute(&mut expected_a);
        scalar::permute(&mut expected_b);

        assert_eq!(a, expected_a);
        assert_eq!(b, expected_b);
    }
}

#[test]
fn zero_out_clears_every_lane() {
    let mut lanes = [0xDEAD_BEEF_DEAD_BEEFu64; 25];

    zero_out(&mut lanes);

    assert_eq!(lanes, [0u64; 25]);
}

#[test]
fn zero_out_clears_a_partial_slice() {
    let mut lanes = [1u64; 4];

    zero_out(&mut lanes[..2]);

    assert_eq!(lanes, [0, 0, 1, 1]);
}

/// Drops `state` where the test can still see its bytes, and returns the lanes
/// left at that address.
///
/// The drop leaves the storage alive: `MaybeUninit` owns it, and the lanes are
/// plain `u64` that the drop glue neither deallocates nor invalidates. So the
/// read afterwards observes what `Drop` wrote, which is the point.
#[allow(
    unsafe_code,
    reason = "checking the drop means reading the address it wrote to"
)]
fn lanes_after_drop(state: State) -> [u64; 25] {
    let mut slot = MaybeUninit::new(state);

    // SAFETY: `slot` holds an initialized, aligned `State`, dropped once. The
    // read copies a `[u64; 25]` out of that storage without naming the dropped
    // `State` itself.
    unsafe {
        slot.assume_init_drop();
        (*slot.as_ptr()).lanes
    }
}

/// Dropping a `State` zeros its lanes.
#[test]
fn state_is_zeroed_on_drop() {
    let state = State::from([0xDEAD_BEEF_DEAD_BEEFu64; 25]);

    assert_eq!(lanes_after_drop(state), [0u64; 25]);
}

//! Differential tests: each batched lane matches the per-stream hasher.

use super::*;
use crate::shake::{Shake128, Shake256};

/// Every `Shake128X4` lane squeezes the same bytes as a scalar `Shake128` on
/// that lane's seed, across a multi-block read.
#[test]
fn shake128_x4_matches_scalar() {
    let seeds: [[u8; 34]; 4] =
        core::array::from_fn(|i| core::array::from_fn(|k| (i * 7 + k) as u8));

    let [s0, s1, s2, s3] = &seeds;
    let mut batched = Shake128X4::absorb([s0, s1, s2, s3]);
    let mut lanes = [[0u8; 400]; 4];
    let [l0, l1, l2, l3] = &mut lanes;
    batched.squeeze([l0, l1, l2, l3]);

    for (lane, seed) in lanes.iter().zip(&seeds) {
        assert_eq!(*lane, Shake128::digest::<400>(seed));
    }
}

/// The batched path holds across multi-block absorb and squeeze: equal-length
/// seeds longer than the rate cross absorb-block boundaries in lockstep, and a
/// long read crosses squeeze-block boundaries, still matching scalar.
#[test]
fn shake128_x4_multiblock_matches_scalar() {
    let seeds: [[u8; 200]; 4] =
        core::array::from_fn(|i| core::array::from_fn(|k| (i * 31 + k * 3) as u8));

    let [s0, s1, s2, s3] = &seeds;
    let mut batched = Shake128X4::absorb([s0, s1, s2, s3]);
    let mut lanes = [[0u8; 500]; 4];
    let [l0, l1, l2, l3] = &mut lanes;
    batched.squeeze([l0, l1, l2, l3]);

    for (lane, seed) in lanes.iter().zip(&seeds) {
        assert_eq!(*lane, Shake128::digest::<500>(seed));
    }
}

/// Unequal-length seeds take the scalar fallback and still match per-stream.
#[test]
fn shake128_x4_unequal_lengths_match_scalar() {
    let seeds: [&[u8]; 4] = [b"a", b"bb", b"ccc", b"dddd"];

    let mut batched = Shake128X4::absorb(seeds);
    let mut lanes = [[0u8; 200]; 4];
    let [l0, l1, l2, l3] = &mut lanes;
    batched.squeeze([l0, l1, l2, l3]);

    for (lane, seed) in lanes.iter().zip(&seeds) {
        assert_eq!(*lane, Shake128::digest::<200>(seed));
    }
}

/// Chunked `update` calls match the one-shot absorb: the incremental
/// `XOF.Absorb` contract (FIPS 203 Eq. 4.6), across a rate-block boundary.
#[test]
#[allow(
    clippy::indexing_slicing,
    reason = "chunk bounds are compile-time constants within the seed length"
)]
fn shake128_x4_incremental_update_matches_one_shot() {
    let seeds: [[u8; 200]; 4] =
        core::array::from_fn(|i| core::array::from_fn(|k| (i * 13 + k) as u8));

    let mut incremental = Shake128X4::new();
    for chunk_start in (0..200).step_by(40) {
        let [s0, s1, s2, s3] = &seeds;
        incremental.update([
            &s0[chunk_start..chunk_start + 40],
            &s1[chunk_start..chunk_start + 40],
            &s2[chunk_start..chunk_start + 40],
            &s3[chunk_start..chunk_start + 40],
        ]);
    }

    let mut reader = incremental.finalize_xof();
    let mut lanes = [[0u8; 300]; 4];
    let [l0, l1, l2, l3] = &mut lanes;
    reader.squeeze([l0, l1, l2, l3]);

    for (lane, seed) in lanes.iter().zip(&seeds) {
        assert_eq!(*lane, Shake128::digest::<300>(seed));
    }
}

/// An unequal-length `update` after a lockstep one degrades to scalar lanes
/// mid-stream and still matches per-stream hashers.
#[test]
fn shake128_x4_mid_stream_degrade_matches_scalar() {
    let equal: [[u8; 50]; 4] = core::array::from_fn(|i| [(i as u8) * 3; 50]);
    let unequal: [&[u8]; 4] = [b"a", b"bb", b"ccc", b"dddd"];

    let mut batched = Shake128X4::new();
    let [e0, e1, e2, e3] = &equal;
    batched.update([e0, e1, e2, e3]);
    batched.update(unequal);

    let mut reader = batched.finalize_xof();
    let mut lanes = [[0u8; 200]; 4];
    let [l0, l1, l2, l3] = &mut lanes;
    reader.squeeze([l0, l1, l2, l3]);

    for ((lane, prefix), tail) in lanes.iter().zip(&equal).zip(&unequal) {
        let mut scalar = Shake128::new();
        scalar.update(prefix);
        scalar.update(tail);

        let mut expected = [0u8; 200];
        scalar.finalize_xof().read(&mut expected);
        assert_eq!(*lane, expected);
    }
}

/// Every `Shake256X4` lane matches a scalar `Shake256` on that lane's input.
#[test]
fn shake256_x4_matches_scalar() {
    let inputs: [[u8; 33]; 4] = core::array::from_fn(|i| [(i as u8 + 1) * 10; 33]);

    let [i0, i1, i2, i3] = &inputs;
    let mut batched = Shake256X4::absorb([i0, i1, i2, i3]);
    let mut lanes = [[0u8; 192]; 4];
    let [l0, l1, l2, l3] = &mut lanes;
    batched.squeeze([l0, l1, l2, l3]);

    for (lane, input) in lanes.iter().zip(&inputs) {
        assert_eq!(*lane, Shake256::digest::<192>(input));
    }
}

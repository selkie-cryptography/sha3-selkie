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

//! Tests for the raw permutation entry points.
//!
//! These wrappers are thin, but they are the crate's only published view of
//! the permutation, and a benchmark calling one that quietly did nothing would
//! report a very good number.
#![allow(
    clippy::indexing_slicing,
    reason = "tests index fixed-size arrays by compile-time-bounded lane, and \
              a panic here is the assertion mechanism"
)]

use super::*;

/// A deterministic non-zero state, so a permutation that does nothing is
/// distinguishable from one that works.
fn seeded() -> [u64; 25] {
    let mut seed: u64 = 0x0123_4567_89AB_CDEF;

    core::array::from_fn(|_| {
        seed ^= seed << 13;
        seed ^= seed >> 7;
        seed ^= seed << 17;
        seed
    })
}

/// The single-stream entry point permutes: its output differs from its input.
#[test]
fn keccak_f1600_permutes() {
    let input = seeded();
    let mut state = input;
    keccak_f1600(&mut state);

    assert_ne!(state, input);
}

/// Each batched entry point agrees with the single-stream one on every lane.
///
/// Pinning the widths against `keccak_f1600` rather than against a vector
/// catches a wrapper that permutes nothing, dispatches to the wrong width, or
/// leaves some lanes untouched, without restating a known-answer vector the
/// backend tests already own.
#[test]
fn batched_entry_points_agree_with_single_stream() {
    let input = seeded();
    let mut expected = input;
    keccak_f1600(&mut expected);

    let mut two = [input; 2];
    keccak_f1600_x2(&mut two);
    for lane in two {
        assert_eq!(lane, expected, "x2");
    }

    let mut four = [input; 4];
    keccak_f1600_x4(&mut four);
    for lane in four {
        assert_eq!(lane, expected, "x4");
    }

    let mut eight = [input; 8];
    keccak_f1600_x8(&mut eight);
    for lane in eight {
        assert_eq!(lane, expected, "x8");
    }
}

/// The batched entry points keep independent states independent.
///
/// Feeding every lane the same input would not notice a kernel that broadcast
/// one lane over the rest, so give each lane its own state and check each
/// against its own single-stream result.
#[test]
fn batched_entry_points_keep_lanes_independent() {
    let states: [[u64; 25]; 8] = core::array::from_fn(|i| {
        let mut state = seeded();
        state[0] ^= i as u64 + 1;

        state
    });

    let expected: [[u64; 25]; 8] = core::array::from_fn(|i| {
        let mut state = states[i];
        keccak_f1600(&mut state);

        state
    });

    let mut eight = states;
    keccak_f1600_x8(&mut eight);
    assert_eq!(eight, expected);

    let mut four = [states[0], states[1], states[2], states[3]];
    keccak_f1600_x4(&mut four);
    assert_eq!(four, [expected[0], expected[1], expected[2], expected[3]]);

    let mut two = [states[0], states[1]];
    keccak_f1600_x2(&mut two);
    assert_eq!(two, [expected[0], expected[1]]);
}

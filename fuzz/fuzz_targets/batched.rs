//! Fuzzing the batched `Shake128X4` against the scalar hasher.
//!
//! Each of the four lanes must reproduce the single-stream SHAKE128 over its
//! own seed, for any seed lengths and squeeze length. This is the invariant the
//! eventual vectorized permutation must preserve; wiring it up now makes a
//! lane-shuffle regression a fuzz failure rather than a silent wrong answer.

#![no_main]

use arbitrary::Arbitrary;
use libfuzzer_sys::fuzz_target;

/// Four independent seeds and a shared squeeze length.
#[derive(Debug, Arbitrary)]
struct Input {
    /// One seed per lane.
    seeds: [Vec<u8>; 4],

    /// The per-lane squeeze length (bounded by `u16` so a run stays cheap).
    out_len: u16,
}

fuzz_target!(|input: Input| {
    let out_len = usize::from(input.out_len);
    let [s0, s1, s2, s3] = &input.seeds;

    let mut batched = sha3_selkie::Shake128X4::absorb([s0, s1, s2, s3]);
    let mut lanes = [
        vec![0u8; out_len],
        vec![0u8; out_len],
        vec![0u8; out_len],
        vec![0u8; out_len],
    ];
    let [l0, l1, l2, l3] = &mut lanes;
    batched.squeeze([l0, l1, l2, l3]);

    for (lane, seed) in lanes.iter().zip(&input.seeds) {
        let mut scalar = vec![0u8; out_len];
        let mut xof = sha3_selkie::Shake128::new();
        xof.update(seed);
        xof.finalize_xof().read(&mut scalar);

        assert_eq!(lane, &scalar);
    }
});

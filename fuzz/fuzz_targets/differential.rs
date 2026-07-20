//! Differential and self-consistency fuzzing of the single-stream hashers.
//!
//! The fuzzer chooses an absorb pattern (a list of chunks) and a squeeze
//! length, then coverage-guided search drives inputs toward rate-block edges
//! the fixed CAVP vectors and bounded proptests do not reach. Each run asserts
//! agreement with the independent `libcrux-sha3` and that incremental absorb
//! equals the one-shot.

#![no_main]

use arbitrary::Arbitrary;
use libfuzzer_sys::fuzz_target;

/// A fuzzer-chosen absorb pattern and squeeze length.
#[derive(Debug, Arbitrary)]
struct Input {
    /// The message, absorbed in these chunks; their concatenation is the input.
    chunks: Vec<Vec<u8>>,

    /// The SHAKE squeeze length (bounded by `u16` so a run stays cheap).
    out_len: u16,
}

fuzz_target!(|input: Input| {
    let whole: Vec<u8> = input.chunks.concat();

    // Fixed-output hashes agree with the reference.
    assert_eq!(
        &sha3_selkie::Sha3_256::digest(&whole)[..],
        &libcrux_sha3::sha256(&whole)[..],
    );
    assert_eq!(
        &sha3_selkie::Sha3_512::digest(&whole)[..],
        &libcrux_sha3::sha512(&whole)[..],
    );

    // Incremental absorb equals the one-shot over the concatenation.
    let mut hasher = sha3_selkie::Sha3_256::new();
    for chunk in &input.chunks {
        hasher.update(chunk);
    }
    assert_eq!(hasher.finalize(), sha3_selkie::Sha3_256::digest(&whole));

    // SHAKE128 agrees with the reference across the chosen output length.
    let out_len = usize::from(input.out_len);
    let mut ours = vec![0u8; out_len];
    let mut xof = sha3_selkie::Shake128::new();
    xof.update(&whole);
    xof.finalize_xof().read(&mut ours);

    let mut reference = vec![0u8; out_len];
    libcrux_sha3::shake128_ema(&mut reference, &whole);

    assert_eq!(ours, reference);
});

//! Property tests: differential checks against an independent SHA-3
//! implementation, and the sponge's absorb/squeeze invariants.

use proptest::prelude::*;

/// Reads `n` bytes from this crate's SHAKE128 over `data`.
fn selkie_shake128(data: &[u8], n: usize) -> Vec<u8> {
    let mut hasher = sha3_selkie::Shake128::new();
    hasher.update(data);

    let mut reader = hasher.finalize_xof();
    let mut out = vec![0u8; n];
    reader.read(&mut out);

    out
}

/// Reads `n` bytes from the independent `libcrux-sha3` SHAKE128 over `data`.
fn libcrux_shake128(data: &[u8], n: usize) -> Vec<u8> {
    let mut out = vec![0u8; n];
    libcrux_sha3::shake128_ema(&mut out, data);

    out
}

proptest! {
    /// SHA3-256 matches `libcrux-sha3` on arbitrary inputs.
    #[test]
    fn sha3_256_matches_reference(data: Vec<u8>) {
        prop_assert_eq!(sha3_selkie::Sha3_256::digest(&data), libcrux_sha3::sha256(&data));
    }

    /// SHA3-512 matches `libcrux-sha3` on arbitrary inputs.
    #[test]
    fn sha3_512_matches_reference(data: Vec<u8>) {
        prop_assert_eq!(sha3_selkie::Sha3_512::digest(&data), libcrux_sha3::sha512(&data));
    }

    /// SHAKE128 matches `libcrux-sha3` across arbitrary inputs and output
    /// lengths (crossing rate-block boundaries).
    #[test]
    fn shake128_matches_reference(data: Vec<u8>, out_len in 0usize..1024) {
        prop_assert_eq!(
            selkie_shake128(&data, out_len),
            libcrux_shake128(&data, out_len),
        );
    }

    /// Absorbing in arbitrary chunks hashes identically to a one-shot over the
    /// concatenation.
    #[test]
    fn incremental_matches_one_shot(chunks: Vec<Vec<u8>>) {
        let mut hasher = sha3_selkie::Sha3_256::new();
        let mut whole = Vec::new();
        for chunk in &chunks {
            hasher.update(chunk);
            whole.extend_from_slice(chunk);
        }

        prop_assert_eq!(hasher.finalize(), sha3_selkie::Sha3_256::digest(&whole));
    }

    /// Reading a XOF stream in arbitrary chunk sizes yields the same bytes as
    /// one bulk read.
    #[test]
    fn streaming_matches_bulk(data: Vec<u8>, chunk_sizes in prop::collection::vec(1usize..40, 0..40)) {
        let total: usize = chunk_sizes.iter().sum();
        let bulk = selkie_shake128(&data, total);

        let mut hasher = sha3_selkie::Shake128::new();
        hasher.update(&data);
        let mut reader = hasher.finalize_xof();
        let mut piecemeal = Vec::with_capacity(total);
        for size in chunk_sizes {
            let mut chunk = vec![0u8; size];
            reader.read(&mut chunk);
            piecemeal.extend_from_slice(&chunk);
        }

        prop_assert_eq!(piecemeal, bulk);
    }

    /// Each batched `Shake128X4` lane matches the scalar hasher on that lane's
    /// seed.
    #[test]
    fn shake128_x4_matches_scalar(
        seeds in prop::array::uniform4(prop::collection::vec(any::<u8>(), 0..64)),
        out_len in 0usize..300,
    ) {
        let [s0, s1, s2, s3] = &seeds;
        let mut batched = sha3_selkie::Shake128X4::absorb([s0, s1, s2, s3]);
        let mut lanes = [vec![0u8; out_len], vec![0u8; out_len], vec![0u8; out_len], vec![0u8; out_len]];
        let [l0, l1, l2, l3] = &mut lanes;
        batched.squeeze([l0, l1, l2, l3]);

        for (lane, seed) in lanes.iter().zip(&seeds) {
            let expected = selkie_shake128(seed, out_len);
            prop_assert_eq!(lane, &expected);
        }
    }
}

/// A deterministic pseudo-random buffer of `len` bytes, so the large-input
/// tests are reproducible and need no external data.
fn pattern(len: usize) -> Vec<u8> {
    let mut out = Vec::with_capacity(len);
    let mut x: u32 = 0x9E37_79B9;
    for _ in 0..len {
        x = x.wrapping_mul(1_664_525).wrapping_add(1_013_904_223);
        out.push((x >> 24) as u8);
    }

    out
}

/// Hashing a multi-megabyte input — thousands of rate blocks, far past what the
/// CAVP short-message vectors and the proptest inputs reach — matches the
/// reference on both the absorb (fixed-output) and squeeze (XOF) paths.
#[test]
fn large_input_matches_reference() {
    let data = pattern(1 << 20);

    assert_eq!(
        sha3_selkie::Sha3_256::digest(&data),
        libcrux_sha3::sha256(&data)
    );
    assert_eq!(
        sha3_selkie::Sha3_512::digest(&data),
        libcrux_sha3::sha512(&data)
    );

    let squeeze_len = 1 << 18;
    assert_eq!(
        selkie_shake128(&data, squeeze_len),
        libcrux_shake128(&data, squeeze_len),
    );
}

/// Absorbing a large input in irregular chunks whose sizes straddle the rate
/// equals a one-shot over the whole, exercising cross-block buffering at scale.
#[test]
fn large_incremental_matches_one_shot() {
    let data = pattern(1 << 20);

    let mut hasher = sha3_selkie::Sha3_256::new();
    let mut offset = 0;
    let mut step = 1;
    while offset < data.len() {
        let end = (offset + step).min(data.len());
        hasher.update(&data[offset..end]);
        offset = end;
        step = step % 137 + 1;
    }

    assert_eq!(hasher.finalize(), sha3_selkie::Sha3_256::digest(&data));
}

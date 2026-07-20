//! Known-answer and streaming-consistency tests for the XOFs.

use super::*;

/// Decodes a hex string into a fixed-size byte array.
fn unhex<const N: usize>(hex: &str) -> [u8; N] {
    let mut out = [0u8; N];
    hex::decode_to_slice(hex, &mut out).expect("valid hex vector");

    out
}

/// SHAKE128 matches the known-answer vector for the empty input.
#[test]
fn shake128_kat() {
    assert_eq!(
        Shake128::digest::<32>(b""),
        unhex("7f9c2ba4e88f827d616045507605853ed73b8093f6efbc88eb1a6eacfa66ef26"),
    );
}

/// SHAKE256 matches the known-answer vector for the empty input.
#[test]
fn shake256_kat() {
    assert_eq!(
        Shake256::digest::<32>(b""),
        unhex("46b9dd2b0ba88d13233b3feb743eeb243fcd52ea62b81b82b50c27646ed5762f"),
    );
}

/// Reading a long output byte by byte matches reading it all at once, across
/// rate-block boundaries.
#[test]
fn streaming_matches_bulk() {
    let bulk = Shake128::digest::<400>(b"stream me");

    let mut reader = {
        let mut hasher = Shake128::new();
        hasher.update(b"stream me");
        hasher.finalize_xof()
    };
    let mut piecemeal = [0u8; 400];
    for slot in &mut piecemeal {
        reader.read(core::slice::from_mut(slot));
    }

    assert_eq!(bulk, piecemeal);
}

/// The `Default` constructor yields a fresh XOF equivalent to `new`.
#[test]
fn default_matches_new() {
    let mut from_default = [0u8; 32];
    Shake128::default().finalize_xof().read(&mut from_default);
    assert_eq!(from_default, Shake128::digest::<32>(b""));

    let mut from_default = [0u8; 32];
    Shake256::default().finalize_xof().read(&mut from_default);
    assert_eq!(from_default, Shake256::digest::<32>(b""));
}

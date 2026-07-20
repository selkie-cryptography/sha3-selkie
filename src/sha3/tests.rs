//! Known-answer tests for the fixed-output SHA-3 hashes.

use super::*;

/// Decodes a hex string into a fixed-size byte array.
fn unhex<const N: usize>(hex: &str) -> [u8; N] {
    let mut out = [0u8; N];
    hex::decode_to_slice(hex, &mut out).expect("valid hex vector");

    out
}

/// SHA3-256 matches the FIPS 202 known-answer vectors for the empty input and
/// `"abc"`.
#[test]
fn sha3_256_kat() {
    assert_eq!(
        Sha3_256::digest(b""),
        unhex("a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a"),
    );

    assert_eq!(
        Sha3_256::digest(b"abc"),
        unhex("3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532"),
    );
}

/// SHA3-512 matches the FIPS 202 known-answer vector for the empty input.
#[test]
fn sha3_512_kat() {
    assert_eq!(
        Sha3_512::digest(b""),
        unhex(
            "a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a6\
             15b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26",
        ),
    );
}

/// Incremental updates hash identically to a one-shot over the concatenation.
#[test]
fn incremental_matches_one_shot() {
    let mut hasher = Sha3_256::new();
    hasher.update(b"hello ");
    hasher.update(b"world");

    assert_eq!(hasher.finalize(), Sha3_256::digest(b"hello world"));
}

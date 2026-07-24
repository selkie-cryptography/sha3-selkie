//! ACVP-style Large Data Tests: gigabyte-scale messages hashed by streaming a
//! repeating pattern, never materializing the whole input.
//!
//! The pattern is 251 bytes (prime, so it misaligns with the 136- and
//! 168-byte rates and the 8-byte lane granularity), streamed in odd-sized
//! chunks so rate-block boundaries fall at a different sequence than the
//! reference generator used. This stresses the incremental absorb across
//! millions of permutations and every intra-block offset, catching a block-
//! boundary or offset-arithmetic bug that the short vectors miss.
//!
//! Reference digests were generated independently with Python's `hashlib`.
//! Ignored by default (the 1 GiB case runs for seconds to minutes); the CI
//! constant-time / stress leg runs them with `--ignored`.

use sha3_selkie::{Sha3_256, Sha3_512, Shake128, Shake256};

/// The repeating message pattern: bytes `0..251`.
const PATTERN: [u8; 251] = {
    let mut p = [0u8; 251];
    let mut i = 0;
    while i < 251 {
        p[i] = i as u8;
        i += 1;
    }
    p
};

/// Feeds `absorb` the first `total` bytes of the repeating pattern in
/// odd-sized chunks (deliberately not a rate multiple).
fn stream(total: usize, mut absorb: impl FnMut(&[u8])) {
    // 4093 is prime: chunk boundaries never coincide with a rate block, so
    // the absorb loop's partial-block handling runs on every call.
    const CHUNK: usize = 4093;

    let mut written = 0;
    let mut buf = [0u8; CHUNK];
    while written < total {
        let n = (total - written).min(CHUNK);
        for (k, slot) in buf[..n].iter_mut().enumerate() {
            *slot = PATTERN[(written + k) % 251];
        }
        absorb(&buf[..n]);
        written += n;
    }
}

/// Reference digests for `(total_bytes, sha3_256, sha3_512, shake128_32,
/// shake256_32)`, generated with Python `hashlib`.
#[rustfmt::skip]
const VECTORS: &[(usize, &str, &str, &str, &str)] = &[
    (1 << 20, // 1 MiB
     "eec77e4d80484c04a505e6203c3822c67e13ce186fec1ea01e56961dcd7261ca",
     "d4f59cf8ca6f21828cd4310889c984f2ad2fec66fb953c3999e8c00903c8cbbd5fd12a4779b775822ff8ef28bbc796af9af4a1d4ab49d43d1b2bdd9e86461371",
     "af1f491eea755a72fec52897f5dfb89dac9d4f8462ad1a734caf1897395fa829",
     "9d850d9e9f8fa6f3363f0d65cff9f6278fd1f46ce82b89814fe5902f5f38c075"),
    (1 << 24, // 16 MiB
     "acade24d564f1dae78e26ca4615bc8061dda3835de1bb7afde3ef0d32a931191",
     "314cd6d2e1cc05dfc4c8429541a2877becd82e9def2333f26a4eb7f72cffe758289f9185ddae4bb5017ad7019933404f241787ac650e505530f2973d3233a88d",
     "8a38dce3e6592d50867536f5f352abd74e486bdbfe48c43b8372d55e6547110a",
     "525fa10737fa7538afe5df929cfadb606e52a2b2e2f0e4c5626510e720319b73"),
    (1 << 30, // 1 GiB
     "ee6b2058bcf3320e3b843e0c2b635477c5ed0e66e9672a122fd4e2d60318d894",
     "6f3976bbb332832e6529a736efde1b043bfab89f34ffdc40e030b385584dfbd2f862d5159e80c530e234bd6232e1b49ac971b7e14cd026145503ebf357af3a3a",
     "7d7b31524f30d280b0e44eb1f2ff4e817b8df9b9c7d9074d52098eaea921fae8",
     "44c1a820ec3c8c6b3a07f359b71061b07d7894cbd2758508847f173d3f48728e"),
];

#[test]
#[ignore = "gigabyte-scale; run with --ignored"]
fn large_data_matches_reference() {
    for &(total, sha256_hex, sha512_hex, shake128_hex, shake256_hex) in VECTORS {
        let mut sha256 = Sha3_256::new();
        stream(total, |chunk| sha256.update(chunk));
        assert_eq!(
            hex(&sha256.finalize()),
            sha256_hex,
            "sha3_256 at {total} bytes"
        );

        let mut sha512 = Sha3_512::new();
        stream(total, |chunk| sha512.update(chunk));
        assert_eq!(
            hex(&sha512.finalize()),
            sha512_hex,
            "sha3_512 at {total} bytes"
        );

        let mut shake128 = Shake128::new();
        stream(total, |chunk| shake128.update(chunk));
        let mut out128 = [0u8; 32];
        shake128.finalize_xof().read(&mut out128);
        assert_eq!(hex(&out128), shake128_hex, "shake128 at {total} bytes");

        let mut shake256 = Shake256::new();
        stream(total, |chunk| shake256.update(chunk));
        let mut out256 = [0u8; 32];
        shake256.finalize_xof().read(&mut out256);
        assert_eq!(hex(&out256), shake256_hex, "shake256 at {total} bytes");
    }
}

/// Lowercase hex of a byte slice.
fn hex(bytes: &[u8]) -> String {
    let mut s = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        s.push_str(&format!("{b:02x}"));
    }
    s
}

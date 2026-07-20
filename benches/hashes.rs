//! Wall-clock benchmarks for the SHA-3 hashers and the raw permutation.
//!
//! `cargo bench --bench hashes`. The message sizes bracket the rate blocks: 32
//! bytes is one absorb block, 4096 crosses many, so the per-byte cost and the
//! fixed setup cost are both visible.

use divan::{Bencher, black_box};
use sha3_selkie::{Sha3_256, Sha3_512, Shake128, Shake256};

fn main() {
    divan::main();
}

/// A deterministic input buffer of `n` bytes.
fn message(n: usize) -> Vec<u8> {
    (0..n).map(|i| i as u8).collect()
}

const SIZES: [usize; 4] = [32, 136, 1024, 4096];

/// SHA3-256 one-shot digest of `size` bytes.
#[divan::bench(args = SIZES)]
fn sha3_256(bencher: Bencher<'_, '_>, size: usize) {
    let input = message(size);

    bencher.bench(|| Sha3_256::digest(black_box(&input)));
}

/// SHA3-512 one-shot digest of `size` bytes.
#[divan::bench(args = SIZES)]
fn sha3_512(bencher: Bencher<'_, '_>, size: usize) {
    let input = message(size);

    bencher.bench(|| Sha3_512::digest(black_box(&input)));
}

/// SHAKE128 absorbing `size` bytes and squeezing 32.
#[divan::bench(args = SIZES)]
fn shake128(bencher: Bencher<'_, '_>, size: usize) {
    let input = message(size);

    bencher.bench(|| {
        let mut hasher = Shake128::new();
        hasher.update(black_box(&input));

        let mut reader = hasher.finalize_xof();
        let mut out = [0u8; 32];
        reader.read(&mut out);

        out
    });
}

/// SHAKE256 absorbing 32 bytes and squeezing `size` (the seed-expansion
/// pattern).
#[divan::bench(args = SIZES)]
fn shake256_squeeze(bencher: Bencher<'_, '_>, size: usize) {
    let input = message(32);

    bencher.bench(|| {
        let mut hasher = Shake256::new();
        hasher.update(black_box(&input));

        let mut reader = hasher.finalize_xof();
        let mut out = vec![0u8; size];
        reader.read(&mut out);

        out
    });
}

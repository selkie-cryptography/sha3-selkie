//! Wall-clock benchmarks for the bare `Keccak-f[1600]` permutation, single
//! stream and 4-way batched.
//!
//! `cargo bench --bench permutation`. No sponge, no padding, no byte packing:
//! just the 24-round kernel, so a regression in the backend shows up here
//! before it is diluted by absorb/squeeze bookkeeping in
//! `benches/hash_functions.rs`.
//!
//! Each iteration permutes the state left by the previous one. That serial
//! chain is deliberate — it matches how a sponge squeezes, and it keeps the
//! measurement latency-bound rather than letting the CPU overlap independent
//! permutations that a real caller never has.
//!
//! Every counter is in streams, not calls, so the rows are directly
//! comparable per stream: the ratio between them is what each batched width
//! actually buys.

use divan::{Bencher, black_box, counter::ItemsCount};
use sha3_selkie::{keccak_f1600, keccak_f1600_x2, keccak_f1600_x4};

fn main() {
    divan::main();
}

/// One `Keccak-f[1600]` permutation of a single state.
#[divan::bench]
fn f1600(bencher: Bencher<'_, '_>) {
    let mut state = [0u64; 25];

    bencher
        .counter(ItemsCount::new(1usize))
        .bench_local(|| keccak_f1600(black_box(&mut state)));
}

/// One batched permutation of two independent states, counted per stream.
#[divan::bench]
fn f1600_x2(bencher: Bencher<'_, '_>) {
    let mut states = [[0u64; 25]; 2];

    bencher
        .counter(ItemsCount::new(2usize))
        .bench_local(|| keccak_f1600_x2(black_box(&mut states)));
}

/// One batched permutation of four independent states, counted per stream.
#[divan::bench]
fn f1600_x4(bencher: Bencher<'_, '_>) {
    let mut states = [[0u64; 25]; 4];

    bencher
        .counter(ItemsCount::new(4usize))
        .bench_local(|| keccak_f1600_x4(black_box(&mut states)));
}

/// Two streams forced through the four-way path, wasting two lanes — what a
/// two-stream caller pays without [`f1600_x2`]. The gap between this row and
/// `f1600_x2` is the whole reason the two-way entry points exist.
#[divan::bench]
fn f1600_two_streams_via_x4(bencher: Bencher<'_, '_>) {
    let mut states = [[0u64; 25]; 4];

    bencher
        .counter(ItemsCount::new(2usize))
        .bench_local(|| keccak_f1600_x4(black_box(&mut states)));
}

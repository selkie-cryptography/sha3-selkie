# sha3-selkie

FIPS 202 (SHA-3 and SHAKE) for beautiful, secure code.

The SHA-3 family over `Keccak-f[1600]`: the fixed-output hashes `Sha3_256`
and `Sha3_512`, and the extendable-output functions `Shake128` and
`Shake256`. Each is an incremental hasher (`new` / `update` / `finalize`)
with a one-shot associated constructor (`digest`). The batched `Shake128X4`
and `Shake256X4` squeeze four independent streams at once, `Shake128X2` /
`Shake256X2` two, and `Shake128X8` / `Shake256X8` eight — so a caller picks
the width its stream count fills rather than running lanes nobody reads.

```rust
use sha3_selkie::{Sha3_256, Shake128};

let digest = Sha3_256::digest("Maighdean mhara mo mháithrín ard".as_bytes());

let mut xof = Shake128::new();
xof.update(b"seed");
let mut reader = xof.finalize_xof();
let mut out = [0u8; 64];
reader.read(&mut out);
```

## Backends

The permutation is dispatched at compile time by `build.rs` (the
`sha3_selkie_ext`, `sha3_selkie_hybrid`, `sha3_selkie_avx2`, and
`sha3_selkie_avx512` cfgs):

- **scalar** — portable reference and fallback; drives the single-stream
  hashers wherever nothing faster exists.
- **neon (two-way)** — aarch64 with the Arm `sha3` extension: two states per
  vector through `EOR3` / `RAX1` / `XAR` / `BCAX`. The whole permutation for
  `*X2`, and run twice for `*X4` on Apple cores. Apple issues SHA-3 ops on
  every SIMD unit, so the single-stream hashers run it too, with a dead
  second lane.
- **hybrid (four-way, scalar/NEON)** — non-Apple aarch64 with `sha3`
  (Neoverse/Cortex before X4, Graviton class), where the SHA-3 instructions
  issue on a subset of the SIMD units: two states in NEON woven with two in
  general-purpose registers, every scalar rho riding a logical's free
  `ror`-operand under a stationary per-lane frame assignment with zero
  materialized rotates per steady round. The weave and the lazy rotations are
  from [Becker-Kannwischer]; the frame assignment and the kernel are derived
  here rather than ported.
- **avx2 (four-way)** — x86-64 with AVX2: chi via `vpandn`, general rotates as
  shift/shift/or, and the byte-aligned rho on lanes 19 and 23 as single
  `vpshufb` shuffles.
- **avx512 (eight- and four-way)** — x86-64 with AVX-512F + VL. `*X8` holds
  eight states in the 64-bit lanes of a 512-bit register, packed by three 8x8
  transposes, running the four-way round body at twice the width. The four-way
  path keeps that layout at 256 bits with the richer menu: chi is one
  `vpternlogq` (truth table `0xD2`), three-way xors one each (`0x96`), and
  `vprolq` rotates natively — roughly half the AVX2 round's instructions. CI
  gates it under Intel SDE, so it is exercised regardless of runner CPU.

A width above what the target implements decomposes: `*X8` runs as two
four-way permutations without AVX-512, and `*X2` on x86-64 pads to four rather
than running scalar lanes, so asking for two never costs more than asking for
four. A batch stays on the vector path only while its lanes move in lockstep:
the first unequal-length `update` or read splits it into per-lane scalar
sponges, each resuming its own stream.

## Constant-time

Keccak has no data-dependent branches, memory indexing, or rotation amounts,
so every hasher here is constant-time in its input, suitable for computing
over secret values. Checked mechanically under Valgrind (`ct/`) on the scalar
and AVX2 backends; Valgrind decodes neither FEAT_SHA3 nor AVX-512, so the
remaining kernels rest on the same structural argument.

## Testing

- **NIST CAVP known-answer vectors** (`tests/cavp/`): the byte-oriented
  ShortMsg vectors for SHA3-256/512 and the ShortMsg plus VariableOut vectors
  for SHAKE128/256, spanning every message length across the rate-block
  boundaries, plus the Monte Carlo files, whose 100 checkpoints each chain
  1000 hashes to catch sponge-state carryover bugs a one-shot digest can't.
- **Differential property tests** (`tests/properties.rs`): every hasher is
  cross-checked against `libcrux-sha3` on arbitrary inputs and output lengths,
  alongside the sponge invariants (chunked absorb equals one-shot, chunked
  squeeze equals bulk, each batched lane equals the scalar hasher).
- **Large data tests** (`tests/large_data.rs`): gigabyte-scale streamed hashes
  over a 251-byte pattern misaligned with both rates and the 8-byte lane,
  stressing incremental absorb across millions of permutations.
- **Mutation tested** with `cargo-mutants`.

## Status

The full public API with NIST CAVP conformance on every backend: scalar,
two-way NEON, four-way hybrid scalar/NEON, four-way AVX2, and four- and
eight-way AVX-512, plus hash-function and raw-permutation benchmarks. MSRV
1.89, set by the AVX-512 intrinsics' stabilization.

[Becker-Kannwischer]: https://eprint.iacr.org/2022/1243

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or
[MIT license](LICENSE-MIT) at your option.

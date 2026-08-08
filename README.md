# sha3-selkie

FIPS 202 (SHA-3 and SHAKE) for beautiful, secure code. Pretty fast.

The SHA-3 family over `Keccak-f[1600]`: the fixed-output hashes `Sha3_256`
and `Sha3_512`, and the extendable-output functions `Shake128` and
`Shake256`. Each is an incremental hash (`new` / `update` / `finalize`) with
a one-shot associated constructor (`digest`). The batched `Shake128X4` and
`Shake256X4` squeeze four independent streams at once, `Shake128X2` /
`Shake256X2` two, and `Shake128X8` / `Shake256X8` eight; caller picks the
width its stream count fills.

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

Detected at compile time by `build.rs`:

- **scalar** — portable reference and default fallback; drives the
  single-stream hashes wherever nothing faster (we think) exists.
- **neon (two-way, +sha3)** — aarch64 with the Arm `sha3` extension: two
  states per vector through `EOR3` / `RAX1` / `XAR` / `BCAX`. Runs the whole
  permutation for `*X2`, runs twice for `*X4` on Apple cores. Apple issues
  SHA-3 ops on every SIMD unit, so the single-stream also runs it but with a
  dead second lane.
- **avx2 (four-way, +avx2)** — x86-64 with AVX2: chi via `vpandn`, general
  rotates as shift/shift/or, and the byte-aligned rho on lanes 19 and 23 as
  single `vpshufb` shuffles.
- **avx512 (eight- and four-way, +avx2,+avx512f,+avx512vl)** — x86-64 with
  AVX-512F + VL. `*X8` holds eight states in the 64-bit lanes of a 512-bit
  register, packed by three 8x8 transposes, running the four-way round body
  at twice the width. `*X4` keeps that layout at 256 bits whre chi is one
  `vpternlogq` (truth table `0xD2`), three-way xors one each (`0x96`), and
  `vprolq` rotates natively — roughly half the AVX2 round's instructions.
- **hybrid (four-way, scalar/NEON, +sha3)** — non-Apple aarch64 with `sha3`
  (Neoverse/Cortex before X4, Graviton class), where the SHA-3 instructions
  issue on a subset of the SIMD units: two states in NEON woven with two in
  general-purpose registers, every scalar rho riding a logical's free
  `ror`-operand under a stationary per-lane frame assignment with zero
  materialized rotates per steady round.

## Constant-time

Keccak has no data-dependent branches, memory indexing, or rotation amounts,
so every hasher here is constant-time in its input, suitable for computing
over secret values.

Our `ct/` tests run Valgrind memcheck over every public hasher with the
message bytes marked secret, so memcheck errors on any branch or address
depending on them. Only the scalar and AVX2 kernels are traced, since
Valgrind decodes neither the FEAT_SHA3 vector ops nor AVX-512.

## Zeroization

`State` and the batched `SpongeX` clear their lanes on drop, with volatile
stores and a compiler fence so the optimizer can't delete them.

Not covered:

- **Moves.** `finalize`, `finalize_xof`, and `Clone` memcpy the state; the
  source stays.
- **Stack spills.** The NEON kernel spills none; 25 lanes fit in vector
  registers. The scalar kernel spills state to its frame, 48 stores per call
  on x86-64 and 8 on aarch64.
- **Registers.** State stays in caller-saved registers.
- **Skipped drops.** `mem::forget`, `ManuallyDrop`, abort.
- **Output.** `finalize` returns the digest by value.

This bounds how long state lives at its last address, not whether copies
remain elsewhere.

## Testing

Every test runs on five backend configurations: portable, AVX2, AVX-512 under
Intel SDE, NEON, and hybrid.

- NIST CAVP known-answer vectors, including the Monte Carlo chains.
- Property tests and two fuzz targets, checked differentially against
  `libcrux-sha3`.
- Each accelerated kernel cross-checked against the scalar reference.
- Miri covers the portable backend for UB.
- An s390x `cross test` is the only proof the sponge's byte packing is
  endian-correct.
- A release-mode job streams gigabytes through the incremental absorb.
- `cargo-mutants` for mutation testing, `cargo-semver-checks` for the API.

## Status

The full public API with NIST CAVP conformance on every backend: scalar,
two-way NEON, four-way hybrid scalar/NEON, four-way AVX2, and four- and
eight-way AVX-512, plus hash-function and raw-permutation benchmarks. MSRV
1.89, set by the AVX-512 intrinsics' stabilization.

[Becker-Kannwischer]: https://eprint.iacr.org/2022/1243

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or
[MIT license](LICENSE-MIT) at your option.

# sha3-selkie

FIPS 202 (SHA-3 and SHAKE) for beautiful, secure code.

The SHA-3 family over `Keccak-f[1600]`: fixed-output `Sha3_256` and
`Sha3_512`, extendable-output `Shake128` and `Shake256`. Each is an
incremental hasher (`new` / `update` / `finalize`) with a one-shot `digest`
constructor.

Batched SHAKE squeezes independent streams in lockstep: `*X2` two lanes,
`*X4` four, `*X8` eight. A caller picks the width its stream count fills
rather than running lanes nobody reads.

`no_std`, no runtime dependencies.

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

`build.rs` dispatches the permutation at compile time, through the
`sha3_selkie_ext`, `sha3_selkie_hybrid`, `sha3_selkie_avx2`, and
`sha3_selkie_avx512` cfgs. Each backend's module doc carries the details.

- **scalar** — portable reference and fallback, and the single-stream hashers
  wherever nothing faster exists.
- **neon (two-way)** — aarch64 with the Arm `sha3` extension: two states per
  vector through `EOR3` / `RAX1` / `XAR` / `BCAX`.
- **hybrid (four-way, scalar/NEON)** — non-Apple aarch64 with `sha3`: two
  states in NEON woven with two in general-purpose registers, after
  [Becker-Kannwischer].
- **avx2 (four-way)** — x86-64 with AVX2: four states per `__m256i`, chi via
  `vpandn`, general rotates as shift/shift/or.
- **avx512 (eight- and four-way)** — x86-64 with AVX-512F + VL: chi in one
  `vpternlogq`, native `vprolq` rotates, eight states per 512-bit register.

## Constant-time

Keccak has no data-dependent branches, memory indexing, or rotation amounts.
Every hasher here is constant-time in its input, so it is suitable for
computing over secret values.

The `ct/` harness runs Valgrind memcheck over every public hasher with the
message bytes marked secret, so memcheck errors on any branch or address
depending on them. It traces the scalar and AVX2 kernels only: Valgrind
decodes neither the FEAT_SHA3 vector ops nor AVX-512.

## Zeroization

`State` and the batched `SpongeX` clear their lanes on drop, with volatile
stores and a compiler fence so the optimizer can't delete them.

Not covered: moves (`finalize`, `finalize_xof`, and `Clone` memcpy the
state), stack spills, caller-saved registers, skipped drops (`mem::forget`,
`ManuallyDrop`, abort), and the digest `finalize` returns by value.

This bounds how long state lives at its last address, not whether copies
remain elsewhere.

## Testing

Every test runs on five backend configurations: portable, AVX2, AVX-512
under Intel SDE, NEON, and hybrid.

- NIST CAVP known-answer vectors, including the Monte Carlo chains.
- Property tests and two fuzz targets, checked differentially against
  `libcrux-sha3`.
- Each accelerated kernel cross-checked against the scalar reference.
- Miri covers the portable backend for UB.
- An s390x `cross test` is the only proof the sponge's byte packing is
  endian-correct.
- A release-mode job streams gigabytes through the incremental absorb.
- `cargo-mutants` for mutation testing, `cargo-semver-checks` for the API.

## Minimum supported Rust version

1.89, set by the AVX-512 intrinsics' stabilization.

## Status

The public API is complete, and every backend passes NIST CAVP: scalar,
two-way NEON, four-way hybrid scalar/NEON, four-way AVX2, and four- and
eight-way AVX-512. Hash-function and raw-permutation benchmarks live in
`benches/`.

No external security audit.

[Becker-Kannwischer]: https://eprint.iacr.org/2022/1243

## License

Licensed under either of [Apache License, Version 2.0][apache] or
[MIT license][mit] at your option.

Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in the work by you, as defined in the Apache-2.0
license, shall be dual licensed as above, without any additional terms or
conditions.

[apache]: https://github.com/selkie-cryptography/sha3-selkie/blob/main/LICENSE-APACHE
[mit]: https://github.com/selkie-cryptography/sha3-selkie/blob/main/LICENSE-MIT

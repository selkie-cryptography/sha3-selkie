# sha3-selkie

FIPS 202 (SHA-3 and SHAKE) for beautiful, secure code.

The SHA-3 family over Keccak-*f*[1600]: the fixed-output hashes `Sha3_256`
and `Sha3_512`, and the extendable-output functions `Shake128` and
`Shake256`. Each is an incremental hasher (`new` / `update` / `finalize`)
with a one-shot associated constructor (`digest`). The batched `Shake128X4`
and `Shake256X4` squeeze four independent streams at once.

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

The Keccak permutation impl is dispatched at compile time (the
`sha3_selkie_ext` cfg from `build.rs`):

- **scalar** — portable, the reference and fallback.
- **neon** — selected on aarch64 targets with the Arm `sha3` extension;
  delegates to the scalar permutation.

## Constant-time

Keccak has no data-dependent branches, memory indexing, or rotation amounts,
so every hasher here is constant-time in its input, suitable for the
secret-derived preimages of a KEM's `H`/`G`/`J`/`PRF`.

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
- **Mutation tested** with `cargo-mutants`.

Project Wycheproof has no raw SHA-3 or SHAKE test vectors (it targets
constructions that *use* hashes, such as HMAC and signatures), so there is
nothing there to pull for a bare hash.

## Status

Working scalar core with the full public API, NIST CAVP conformance, and
`hashes` benchmarks.

## License

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or
[MIT license](LICENSE-MIT) at your option.

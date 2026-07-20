//! FIPS 202 (SHA-3 and SHAKE) with single-stream and batched Keccak.
//!
//! The [SHA-3 family][FIPS 202] over the `Keccak-f[1600]` permutation: the
//! fixed-output hashes [`Sha3_256`] and [`Sha3_512`], and the extendable-output
//! functions [`Shake128`] and [`Shake256`]. Each is an incremental hasher
//! ([`Sha3_256::new`] / [`update`][Sha3_256::update] /
//! [`finalize`][Sha3_256::finalize]) with a one-shot associated constructor
//! ([`Sha3_256::digest`]).
//!
//! # Backends
//!
//! The Keccak permutation dispatches at compile time (the `sha3_selkie_ext`
//! cfg from `build.rs`):
//!
//! - **scalar** (`backend::scalar`): portable, the reference and fallback.
//! - **neon** (`backend::neon`): selected on aarch64 targets with the Arm
//!   `sha3` extension; delegates to the scalar permutation.
//!
//! The batched types ([`Shake128X4`], [`Shake256X4`]) run four independent
//! streams at once, each over the scalar permutation; their output is
//! bit-identical to the per-stream hashers.
//!
//! # Constant-time
//!
//! Keccak has no data-dependent branches, memory indexing, or rotation
//! amounts: every round applies the same fixed sequence of word operations.
//! Every hasher here is therefore constant-time in its input, suitable for the
//! secret-derived preimages of a KEM's `H`/`G`/`J`/`PRF`.
//!
//! [FIPS 202]: https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.202.pdf

#![no_std]
#![deny(missing_docs, clippy::missing_docs_in_private_items)]
#![deny(clippy::indexing_slicing, clippy::unwrap_used)]
#![warn(rust_2018_idioms, unused_lifetimes, unused_qualifications)]

mod backend;
mod batched;
mod sha3;
mod shake;
mod sponge;

pub use batched::{Shake128X4, Shake256X4};
pub use sha3::{Sha3_256, Sha3_512};
pub use shake::{Shake128, Shake128Reader, Shake256, Shake256Reader};

#![doc = include_str!("../README.md")]
#![no_std]
#![deny(missing_docs, clippy::missing_docs_in_private_items)]
#![deny(clippy::indexing_slicing, clippy::unwrap_used)]
#![warn(rust_2018_idioms, unused_lifetimes, unused_qualifications)]

mod backend;
mod batched;
#[cfg(feature = "expose-internals")]
mod internals;
mod sha3;
mod shake;
mod sponge;

pub use batched::{Shake128X4, Shake128X4Reader, Shake256X4, Shake256X4Reader};
#[cfg(feature = "expose-internals")]
#[doc(hidden)]
pub use internals::{keccak_f1600, keccak_f1600_x4};
pub use sha3::{Sha3_256, Sha3_512};
pub use shake::{Shake128, Shake128Reader, Shake256, Shake256Reader};

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

pub use batched::{
    Shake128X2, Shake128X2Reader, Shake128X4, Shake128X4Reader, Shake128X8, Shake128X8Reader,
    Shake256X2, Shake256X2Reader, Shake256X4, Shake256X4Reader, Shake256X8, Shake256X8Reader,
};
#[cfg(feature = "expose-internals")]
#[doc(hidden)]
pub use internals::{keccak_f1600, keccak_f1600_x2, keccak_f1600_x4, keccak_f1600_x8};
pub use sha3::{Sha3_256, Sha3_512};
pub use shake::{Shake128, Shake128Reader, Shake256, Shake256Reader};

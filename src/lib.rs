#![doc = include_str!("../README.md")]
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

//! Arm SHA-3 extension `Keccak-f[1600]` backend.
//!
//! Selected on aarch64 targets with the Arm `sha3` target feature; delegates
//! to the portable scalar permutation.

/// Applies the 24-round permutation in place.
pub(crate) fn permute(lanes: &mut [u64; 25]) {
    super::scalar::permute(lanes);
}

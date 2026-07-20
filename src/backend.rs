//! Compile-time-dispatched `Keccak-f[1600]` permutation backends.
//!
//! [`State`] is the 1600-bit permutation state shared by every hasher; its
//! [`permute`][State::permute] method is the arch-dispatched hot path. The
//! byte-to-lane packing of the sponge lives in [`crate::sponge`], so a backend
//! only implements the 24-round permutation over `[u64; 25]`.

#[cfg(test)]
mod tests;

mod scalar;

#[cfg(sha3_selkie_ext)]
mod neon;

/// The `Keccak-f[1600]` permutation state: 25 lanes of 64 bits, lane `(x, y)`
/// at index `x + 5*y`, each stored little-endian.
#[derive(Clone)]
pub(crate) struct State {
    /// The 25 lanes in row-major `x + 5*y` order.
    lanes: [u64; 25],
}

impl State {
    /// Returns the all-zero state.
    pub(crate) const fn zeroed() -> Self {
        Self { lanes: [0; 25] }
    }

    /// XORs `value` into lane `index`.
    ///
    /// # Panics
    ///
    /// Never: `index` is always a sponge lane index `< 25`; release builds
    /// compile the bounds check out.
    pub(crate) fn xor_lane(&mut self, index: usize, value: u64) {
        #[allow(
            clippy::indexing_slicing,
            reason = "`index < 25` holds for every caller (rate <= 168 bytes = 21 lanes); \
                      fallible `get_mut` handling would obscure the sponge loop"
        )]
        {
            self.lanes[index] ^= value;
        }
    }

    /// Returns lane `index`.
    pub(crate) fn lane(&self, index: usize) -> u64 {
        #[allow(clippy::indexing_slicing, reason = "as `xor_lane`")]
        {
            self.lanes[index]
        }
    }

    /// Applies the 24-round `Keccak-f[1600]` permutation in place, dispatching
    /// to the accelerated backend selected at compile time.
    pub(crate) fn permute(&mut self) {
        #[cfg(sha3_selkie_ext)]
        neon::permute(&mut self.lanes);

        #[cfg(not(sha3_selkie_ext))]
        scalar::permute(&mut self.lanes);
    }
}

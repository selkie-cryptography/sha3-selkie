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
#[allow(
    unsafe_code,
    reason = "the accelerated backend needs FEAT_SHA3 intrinsics"
)]
mod neon;

#[cfg(sha3_selkie_avx2)]
#[allow(unsafe_code, reason = "the batched backend needs AVX2 intrinsics")]
mod avx2;

#[cfg(sha3_selkie_hybrid)]
#[allow(
    unsafe_code,
    reason = "the hybrid backend is a generated scalar/NEON asm kernel"
)]
mod hybrid;

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
    ///
    /// Single-stream goes vector only on Apple cores (SHA-3 ops on every SIMD
    /// unit make the dead-lane two-way kernel ~26% faster than scalar there);
    /// hybrid targets keep scalar, where the constrained SHA-3 pipes lose to
    /// the scalar ALUs on a single stream.
    pub(crate) fn permute(&mut self) {
        #[cfg(all(sha3_selkie_ext, not(sha3_selkie_hybrid)))]
        neon::permute(&mut self.lanes);

        #[cfg(not(all(sha3_selkie_ext, not(sha3_selkie_hybrid))))]
        scalar::permute(&mut self.lanes);
    }
}

impl From<[u64; 25]> for State {
    fn from(lanes: [u64; 25]) -> Self {
        Self { lanes }
    }
}

/// Permutes four independent states at once, for the batched sponge.
///
/// Dispatches at compile time: the four-way AVX2 permutation on x86-64, the
/// hybrid scalar/NEON kernel on non-Apple aarch64 with the SHA-3 extension,
/// two two-way NEON permutations on Apple cores, and four scalar
/// permutations otherwise — one function, so every mutation of it is
/// exercised on every CI leg regardless of which branch that leg compiles.
pub(crate) fn permute_x4(states: &mut [[u64; 25]; 4]) {
    #[cfg(sha3_selkie_avx2)]
    avx2::permute_x4(states);

    #[cfg(sha3_selkie_hybrid)]
    hybrid::permute_x4(states);

    #[cfg(all(sha3_selkie_ext, not(sha3_selkie_hybrid)))]
    {
        let [a, b, c, d] = states;
        neon::permute_pair(a, b);
        neon::permute_pair(c, d);
    }

    #[cfg(not(any(sha3_selkie_avx2, sha3_selkie_ext)))]
    {
        let [a, b, c, d] = states;
        scalar::permute(a);
        scalar::permute(b);
        scalar::permute(c);
        scalar::permute(d);
    }
}

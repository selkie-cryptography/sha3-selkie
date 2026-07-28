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

#[cfg(all(sha3_selkie_avx2, not(sha3_selkie_avx512)))]
#[allow(unsafe_code, reason = "the batched backend needs AVX2 intrinsics")]
mod avx2;

#[cfg(sha3_selkie_avx512)]
#[allow(unsafe_code, reason = "the batched backend needs AVX-512 intrinsics")]
mod avx512;

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

    /// Applies the 24-round `Keccak-f[1600]` permutation in place.
    pub(crate) fn permute(&mut self) {
        permute(&mut self.lanes);
    }
}

impl From<[u64; 25]> for State {
    fn from(lanes: [u64; 25]) -> Self {
        Self { lanes }
    }
}

/// Permutes one state, for the single-stream sponge.
///
/// Dispatches at compile time: the dead-lane vector kernel on Apple cores,
/// scalar elsewhere (constrained SHA-3 pipes lose to the scalar ALUs on a
/// single stream).
pub(crate) fn permute(lanes: &mut [u64; 25]) {
    #[cfg(all(sha3_selkie_ext, not(sha3_selkie_hybrid)))]
    neon::permute(lanes);

    #[cfg(not(all(sha3_selkie_ext, not(sha3_selkie_hybrid))))]
    scalar::permute(lanes);
}

/// A batch of independent states permuted together, for the batched sponge.
///
/// Implemented per batch width so [`SpongeX`](crate::batched) can be generic
/// over its lane count while each width still reaches the kernel that suits
/// it.
pub(crate) trait Batch {
    /// Applies the 24-round `Keccak-f[1600]` permutation to every state in the
    /// batch.
    fn permute(&mut self);
}

impl Batch for [[u64; 25]; 2] {
    /// The two-way NEON kernel wherever the SHA-3 extension is available, one
    /// padded four-way permutation on x86-64, two scalar permutations
    /// otherwise.
    ///
    /// x86-64 has no two-way AVX2/AVX-512 kernel, so it pads to four and
    /// wastes two lanes. That is the conservative choice: it makes a two-lane
    /// batch cost exactly what a four-lane one costs, so asking for two can
    /// never be slower than asking for four. Whether two scalar permutations
    /// would beat it there is unmeasured.
    fn permute(&mut self) {
        #[cfg(sha3_selkie_ext)]
        {
            let [a, b] = self;
            neon::permute_pair(a, b);
        }

        #[cfg(sha3_selkie_avx2)]
        {
            let [a, b] = self;
            let mut padded = [*a, *b, [0u64; 25], [0u64; 25]];
            padded.permute();

            let [permuted_a, permuted_b, _, _] = padded;
            *a = permuted_a;
            *b = permuted_b;
        }

        #[cfg(not(any(sha3_selkie_ext, sha3_selkie_avx2)))]
        for state in self {
            permute(state);
        }
    }
}

impl Batch for [[u64; 25]; 4] {
    /// The four-way AVX-512 or AVX2 permutation on x86-64, the hybrid
    /// scalar/NEON kernel on non-Apple aarch64 with the SHA-3 extension, two
    /// two-way NEON permutations on Apple cores, and four scalar permutations
    /// otherwise.
    fn permute(&mut self) {
        #[cfg(sha3_selkie_avx512)]
        avx512::permute_x4(self);

        #[cfg(all(sha3_selkie_avx2, not(sha3_selkie_avx512)))]
        avx2::permute_x4(self);

        #[cfg(sha3_selkie_hybrid)]
        hybrid::permute_x4(self);

        #[cfg(all(sha3_selkie_ext, not(sha3_selkie_hybrid)))]
        {
            let [a, b, c, d] = self;
            neon::permute_pair(a, b);
            neon::permute_pair(c, d);
        }

        #[cfg(not(any(sha3_selkie_avx2, sha3_selkie_ext)))]
        for state in self {
            permute(state);
        }
    }
}

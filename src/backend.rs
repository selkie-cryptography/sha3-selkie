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

    /// Applies the 24-round `Keccak-f[1600]` permutation in place.
    pub(crate) fn permute(&mut self) {
        permute(&mut self.lanes);
    }

    /// XORs `data` into the state starting at byte `pos`, little-endian within
    /// each lane.
    pub(crate) fn xor_block(&mut self, pos: usize, data: &[u8]) {
        xor_block(&mut self.lanes, pos, data);
    }

    /// Fills `out` from the state starting at byte `pos`.
    pub(crate) fn read_block(&self, pos: usize, out: &mut [u8]) {
        read_block(&self.lanes, pos, out);
    }
}

impl From<[u64; 25]> for State {
    fn from(lanes: [u64; 25]) -> Self {
        Self { lanes }
    }
}

impl Batch for [[u64; 25]; 8] {
    /// The eight-way AVX-512 permutation, which fills a 512-bit register with
    /// eight states; every other backend splits into two four-way halves and
    /// dispatches each through [`Batch`] again.
    fn permute(&mut self) {
        #[cfg(sha3_selkie_avx512)]
        avx512::permute_x8(self);

        #[cfg(not(sha3_selkie_avx512))]
        if let Some((first, rest)) = self.split_first_chunk_mut::<4>() {
            first.permute();

            if let Some((second, _)) = rest.split_first_chunk_mut::<4>() {
                second.permute();
            }
        }
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

/// XORs `data` into `lanes`'s rate block starting at byte `pos`, little-endian
/// within each lane.
///
/// Splits into a ragged head that finishes the partially-filled word, a run of
/// whole words, and a ragged tail, so a block-length call touches each state
/// word once.
#[allow(
    clippy::indexing_slicing,
    reason = "callers bound `pos + data.len()` by `RATE <= 200`, so `pos / 8 < 25`"
)]
pub(crate) fn xor_block(lanes: &mut [u64; 25], pos: usize, data: &[u8]) {
    let mut data = data;
    let mut pos = pos;

    while pos % 8 != 0 {
        let Some((&byte, rest)) = data.split_first() else {
            return;
        };
        lanes[pos / 8] ^= u64::from(byte) << (8 * (pos % 8));
        pos += 1;
        data = rest;
    }

    let (words, tail) = data.split_at(data.len() - data.len() % 8);
    for (index, word) in words.chunks_exact(8).enumerate() {
        let mut buffer = [0u8; 8];
        buffer.copy_from_slice(word);
        lanes[pos / 8 + index] ^= u64::from_le_bytes(buffer);
    }
    pos += words.len();

    for (index, &byte) in tail.iter().enumerate() {
        lanes[pos / 8] ^= u64::from(byte) << (8 * index);
    }
}

/// Fills `out` from `lanes`'s rate block starting at byte `pos`, the inverse of
/// [`xor_block`] and split the same three ways.
#[allow(
    clippy::indexing_slicing,
    reason = "callers bound `pos + out.len()` by `RATE <= 200`, so `pos / 8 < 25`"
)]
pub(crate) fn read_block(lanes: &[u64; 25], pos: usize, out: &mut [u8]) {
    let mut out = out;
    let mut pos = pos;

    while pos % 8 != 0 {
        let Some((slot, rest)) = out.split_first_mut() else {
            return;
        };
        *slot = (lanes[pos / 8] >> (8 * (pos % 8))) as u8;
        pos += 1;
        out = rest;
    }

    let (words, tail) = out.split_at_mut(out.len() - out.len() % 8);
    for (index, word) in words.chunks_exact_mut(8).enumerate() {
        word.copy_from_slice(&lanes[pos / 8 + index].to_le_bytes());
    }
    pos += words.len();

    for (index, slot) in tail.iter_mut().enumerate() {
        *slot = (lanes[pos / 8] >> (8 * index)) as u8;
    }
}

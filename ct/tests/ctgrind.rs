// Linux-only: crabgrind needs <valgrind/valgrind.h>, absent on macOS. Compiles
// to an empty test binary elsewhere.
#![cfg(target_os = "linux")]
//! Secret-dependent branch and memory-access tests via Valgrind memcheck.
//!
//! Marks the hashed message undefined, then hashes it; Valgrind errors on any
//! branch or address depending on the tainted bytes. Keccak is data-oblivious,
//! so every case must report clean.
//!
//! ```text
//! cargo test --test ctgrind --no-run
//! valgrind --tool=memcheck --error-exitcode=1 \
//!   target/debug/deps/ctgrind-* --test-threads=1
//! ```

use core::ffi::c_void;

use crabgrind::memcheck::{self, MemState};
use sha3_selkie::{
    Sha3_256, Sha3_512, Shake128, Shake128X2, Shake128X4, Shake128X8, Shake256, Shake256X2,
    Shake256X4, Shake256X8,
};

/// Marks `data` secret (undefined) for Valgrind.
fn mark_secret(data: &[u8]) {
    let _ = memcheck::mark_memory(
        data.as_ptr().cast::<c_void>(),
        data.len(),
        MemState::Undefined,
    );
}

/// Marks `data` public (defined), declassifying an output.
fn mark_public(data: &[u8]) {
    let _ = memcheck::mark_memory(
        data.as_ptr().cast::<c_void>(),
        data.len(),
        MemState::Defined,
    );
}

#[test]
fn sha3_256_secret_independent() {
    let msg = [0x42u8; 200];
    mark_secret(&msg);

    let digest = Sha3_256::digest(&msg);

    mark_public(&digest);
}

#[test]
fn sha3_512_secret_independent() {
    let msg = [0x42u8; 200];
    mark_secret(&msg);

    let digest = Sha3_512::digest(&msg);

    mark_public(&digest);
}

#[test]
fn shake128_secret_independent() {
    let msg = [0x42u8; 200];
    mark_secret(&msg);

    let mut hasher = Shake128::new();
    hasher.update(&msg);
    let mut reader = hasher.finalize_xof();
    let mut out = [0u8; 512];
    reader.read(&mut out);

    mark_public(&out);
}

#[test]
fn shake256_secret_independent() {
    let msg = [0x42u8; 200];
    mark_secret(&msg);

    let mut hasher = Shake256::new();
    hasher.update(&msg);
    let mut reader = hasher.finalize_xof();
    let mut out = [0u8; 512];
    reader.read(&mut out);

    mark_public(&out);
}

#[test]
fn shake128_x4_secret_independent() {
    let msgs = [[0x11u8; 200], [0x22; 200], [0x33; 200], [0x44; 200]];
    for msg in &msgs {
        mark_secret(msg);
    }

    let [m0, m1, m2, m3] = &msgs;
    let mut reader = Shake128X4::absorb([m0, m1, m2, m3]);
    let mut out = [[0u8; 512]; 4];
    let [o0, o1, o2, o3] = &mut out;
    reader.squeeze([o0, o1, o2, o3]);

    for lane in &out {
        mark_public(lane);
    }
}

#[test]
fn shake256_x4_secret_independent() {
    let msgs = [[0x11u8; 200], [0x22; 200], [0x33; 200], [0x44; 200]];
    for msg in &msgs {
        mark_secret(msg);
    }

    let [m0, m1, m2, m3] = &msgs;
    let mut reader = Shake256X4::absorb([m0, m1, m2, m3]);
    let mut out = [[0u8; 512]; 4];
    let [o0, o1, o2, o3] = &mut out;
    reader.squeeze([o0, o1, o2, o3]);

    for lane in &out {
        mark_public(lane);
    }
}

#[test]
fn shake128_x2_secret_independent() {
    let msgs = [[0x11u8; 200], [0x22; 200]];
    for msg in &msgs {
        mark_secret(msg);
    }

    let [m0, m1] = &msgs;
    let mut reader = Shake128X2::absorb([m0, m1]);
    let mut out = [[0u8; 512]; 2];
    let [o0, o1] = &mut out;
    reader.squeeze([o0, o1]);

    for lane in &out {
        mark_public(lane);
    }
}

#[test]
fn shake256_x2_secret_independent() {
    let msgs = [[0x11u8; 200], [0x22; 200]];
    for msg in &msgs {
        mark_secret(msg);
    }

    let [m0, m1] = &msgs;
    let mut reader = Shake256X2::absorb([m0, m1]);
    let mut out = [[0u8; 512]; 2];
    let [o0, o1] = &mut out;
    reader.squeeze([o0, o1]);

    for lane in &out {
        mark_public(lane);
    }
}

// The eight-lane kernel is AVX-512 only, which Valgrind cannot decode; on the
// decodable backends these exercise the fallback that splits into two
// four-way permutations, and the scalar path underneath it.
#[test]
fn shake128_x8_secret_independent() {
    let msgs: [[u8; 200]; 8] = core::array::from_fn(|i| [(i as u8 + 1) * 0x11; 200]);
    for msg in &msgs {
        mark_secret(msg);
    }

    let [m0, m1, m2, m3, m4, m5, m6, m7] = &msgs;
    let mut reader = Shake128X8::absorb([m0, m1, m2, m3, m4, m5, m6, m7]);
    let mut out = [[0u8; 512]; 8];
    let [o0, o1, o2, o3, o4, o5, o6, o7] = &mut out;
    reader.squeeze([o0, o1, o2, o3, o4, o5, o6, o7]);

    for lane in &out {
        mark_public(lane);
    }
}

#[test]
fn shake256_x8_secret_independent() {
    let msgs: [[u8; 200]; 8] = core::array::from_fn(|i| [(i as u8 + 1) * 0x11; 200]);
    for msg in &msgs {
        mark_secret(msg);
    }

    let [m0, m1, m2, m3, m4, m5, m6, m7] = &msgs;
    let mut reader = Shake256X8::absorb([m0, m1, m2, m3, m4, m5, m6, m7]);
    let mut out = [[0u8; 512]; 8];
    let [o0, o1, o2, o3, o4, o5, o6, o7] = &mut out;
    reader.squeeze([o0, o1, o2, o3, o4, o5, o6, o7]);

    for lane in &out {
        mark_public(lane);
    }
}

// Gated to Linux because crabgrind's build step looks up
// <valgrind/valgrind.h> on the system include paths, absent on a stock macOS
// install. CI runs this on the Linux image with Valgrind installed; on every
// other target the file compiles to an empty test binary.
#![cfg(target_os = "linux")]
//! Secret-dependent branch and memory-access tests via Valgrind memcheck.
//!
//! Marks the hashed message as "undefined" through Valgrind client requests,
//! then hashes it. Valgrind reports an error if any branch or memory address
//! depends on the tainted (secret) bytes. Keccak is data-oblivious by
//! construction (no secret-dependent branch, index, or rotation amount), so
//! every case here must report clean.
//!
//! Run with:
//! ```text
//! cargo test --test ctgrind --no-run
//! valgrind --tool=memcheck --error-exitcode=1 \
//!   target/debug/deps/ctgrind-* --test-threads=1
//! ```

use core::ffi::c_void;

use crabgrind::memcheck::{self, MemState};
use sha3_selkie::{Sha3_256, Sha3_512, Shake128, Shake128X4, Shake256, Shake256X4};

/// Marks `data` as secret (undefined) for Valgrind; a no-op outside Valgrind.
fn mark_secret(data: &[u8]) {
    let _ = memcheck::mark_memory(
        data.as_ptr().cast::<c_void>(),
        data.len(),
        MemState::Undefined,
    );
}

/// Marks `data` as public (defined) for Valgrind, declassifying an output so
/// its bytes do not taint unrelated test-cleanup code.
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

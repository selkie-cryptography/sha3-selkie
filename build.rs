//! Emits the backend-selection cfgs: `sha3_selkie_ext` selects the Arm SHA-3
//! extension backend, and `sha3_selkie_arch` records the target's SIMD class.
//!
//! `neon` on aarch64 (NEON is baseline on the architecture) and `avx2` on
//! x86_64 when the target features include it (raise the baseline with
//! `-C target-cpu=...` in a `.cargo/config.toml`). Absent `sha3_selkie_ext`,
//! the portable scalar permutation in `src/backend/scalar.rs` is used.
//!
//! `sha3_selkie_ext` requires the Arm `sha3` target feature on top of NEON:
//! the SHA-3 extension instructions are baseline on Apple silicon but not on
//! every aarch64 target.

use std::env;

fn main() {
    println!("cargo::rustc-check-cfg=cfg(sha3_selkie_arch, values(\"neon\", \"avx2\"))");
    println!("cargo::rustc-check-cfg=cfg(sha3_selkie_ext)");
    println!("cargo::rerun-if-env-changed=CARGO_CFG_TARGET_ARCH");
    println!("cargo::rerun-if-env-changed=CARGO_CFG_TARGET_FEATURE");

    let target_arch = env::var("CARGO_CFG_TARGET_ARCH").unwrap_or_default();
    let target_features = env::var("CARGO_CFG_TARGET_FEATURE").unwrap_or_default();
    let has_feature = |name: &str| target_features.split(',').any(|f| f == name);

    match target_arch.as_str() {
        "aarch64" if has_feature("neon") => {
            println!("cargo::rustc-cfg=sha3_selkie_arch=\"neon\"");

            if has_feature("sha3") {
                println!("cargo::rustc-cfg=sha3_selkie_ext");
            }
        }
        "x86_64" if has_feature("avx2") => {
            println!("cargo::rustc-cfg=sha3_selkie_arch=\"avx2\"");
        }
        _ => {}
    }
}

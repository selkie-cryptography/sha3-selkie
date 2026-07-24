//! Empirical constant-time timing analysis of the hashers.
//!
//! `cargo bench --bench tacet`. For each hasher, tacet times two input
//! classes (an all-zero message and a random one) and reports whether their
//! timing distributions are distinguishable under several attacker models.
//! Keccak is data-oblivious, so every case is expected to pass; a failure is
//! a real regression (a secret-dependent branch or table lookup that crept
//! into a backend). Exits nonzero on any `Fail`, so CI can gate on it.

use rand_core::RngCore;
use sha3_selkie::{Sha3_256, Sha3_512, Shake128, Shake256};
use tacet::{AttackerModel, Outcome, TimingOracle, helpers::InputPair};

/// Draws `N` random bytes from the OS RNG.
fn random_bytes<const N: usize>() -> [u8; N] {
    let mut buf = [0u8; N];
    rand_core::OsRng.fill_bytes(&mut buf);

    buf
}

/// The attacker models to evaluate each hasher under.
const MODELS: &[(&str, AttackerModel)] = &[
    ("shared_hw", AttackerModel::SharedHardware),
    ("pq_sentinel", AttackerModel::PostQuantumSentinel),
    ("adjacent", AttackerModel::AdjacentNetwork),
];

/// Prints a one-line verdict, returning whether it counts as a failure.
fn report(name: &str, model_name: &str, outcome: &Outcome) -> bool {
    match outcome {
        Outcome::Pass {
            leak_probability, ..
        } => {
            println!("PASS  {name:<12} [{model_name:<12}] leak_prob={leak_probability:.4}");
            false
        }
        Outcome::Fail {
            leak_probability,
            exploitability,
            ..
        } => {
            println!(
                "FAIL  {name:<12} [{model_name:<12}] leak_prob={leak_probability:.4} exploit={exploitability:?}"
            );
            true
        }
        Outcome::Inconclusive { reason, .. } => {
            println!("SKIP  {name:<12} [{model_name:<12}] inconclusive: {reason:?}");
            false
        }
        Outcome::Unmeasurable { recommendation, .. } => {
            println!("SKIP  {name:<12} [{model_name:<12}] unmeasurable: {recommendation}");
            false
        }
        _ => {
            println!("????  {name:<12} [{model_name:<12}]");
            false
        }
    }
}

/// A 200-byte message: crosses every hasher's rate-block boundary, so the
/// absorb loop and the permutation both run more than once.
const MSG_LEN: usize = 200;

fn main() {
    println!("tacet constant-time analysis");
    println!("============================\n");

    let mut failed = false;

    for &(model_name, model) in MODELS {
        let outcome = TimingOracle::for_attacker(model).test(
            InputPair::new(|| [0u8; MSG_LEN], random_bytes::<MSG_LEN>),
            |msg| {
                let _ = std::hint::black_box(Sha3_256::digest(msg));
            },
        );
        failed |= report("sha3_256", model_name, &outcome);
    }

    for &(model_name, model) in MODELS {
        let outcome = TimingOracle::for_attacker(model).test(
            InputPair::new(|| [0u8; MSG_LEN], random_bytes::<MSG_LEN>),
            |msg| {
                let _ = std::hint::black_box(Sha3_512::digest(msg));
            },
        );
        failed |= report("sha3_512", model_name, &outcome);
    }

    for &(model_name, model) in MODELS {
        let outcome = TimingOracle::for_attacker(model).test(
            InputPair::new(|| [0u8; MSG_LEN], random_bytes::<MSG_LEN>),
            |msg| {
                let mut hasher = Shake128::new();
                hasher.update(msg);
                let mut out = [0u8; 64];
                hasher.finalize_xof().read(&mut out);

                let _ = std::hint::black_box(out);
            },
        );
        failed |= report("shake128", model_name, &outcome);
    }

    for &(model_name, model) in MODELS {
        let outcome = TimingOracle::for_attacker(model).test(
            InputPair::new(|| [0u8; MSG_LEN], random_bytes::<MSG_LEN>),
            |msg| {
                let mut hasher = Shake256::new();
                hasher.update(msg);
                let mut out = [0u8; 64];
                hasher.finalize_xof().read(&mut out);

                let _ = std::hint::black_box(out);
            },
        );
        failed |= report("shake256", model_name, &outcome);
    }

    println!("\ntacet analysis complete");

    if failed {
        std::process::exit(1);
    }
}

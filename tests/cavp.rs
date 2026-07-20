//! FIPS 202 conformance against the NIST CAVP byte-oriented known-answer
//! vectors (`sha-3bytetestvectors`, `shakebytetestvectors`).
//!
//! Covers the short-message and `VariableOut` files plus the Monte Carlo
//! files, whose 100 checkpoints each chain 1000 hashes so that a bug in
//! sponge-state carryover — invisible to a single one-shot digest — shows up
//! as a mismatched checkpoint.

use sha3_selkie::{Sha3_256, Sha3_512, Shake128, Shake256};

/// One known-answer record: an input message and its expected output.
struct Vector {
    /// The input message.
    message: Vec<u8>,

    /// The expected digest (fixed length) or XOF output.
    output: Vec<u8>,
}

/// Parses a CAVP `.rsp` file into its known-answer records.
///
/// Handles the fixed-output `Msg`/`MD` and `Msg`/`Output` short-message files
/// and the SHAKE `VariableOut` files. A `Len` of 0 denotes the empty message
/// (its `Msg = 00` byte is a placeholder), so the message is the first `Len/8`
/// bytes of the decoded `Msg`; `VariableOut` files carry no `Len` and use the
/// whole `Msg`.
fn parse(rsp: &str) -> Vec<Vector> {
    let mut vectors = Vec::new();
    let mut len_bits: Option<usize> = None;
    let mut message: Option<Vec<u8>> = None;

    for line in rsp.lines() {
        let Some((key, value)) = line.split_once('=') else {
            continue;
        };
        let (key, value) = (key.trim(), value.trim());

        match key {
            "Len" => len_bits = value.parse().ok(),
            "Msg" => message = hex::decode(value).ok(),
            "MD" | "Output" => {
                let output = hex::decode(value).expect("valid hex output");
                let mut msg = message.clone().expect("Msg precedes output");
                if let Some(bits) = len_bits.take() {
                    msg.truncate(bits / 8);
                }

                vectors.push(Vector {
                    message: msg,
                    output,
                });
            }
            _ => {}
        }
    }

    vectors
}

/// Reads `n` XOF bytes from a fresh SHAKE128 over `message`.
fn shake128(message: &[u8], n: usize) -> Vec<u8> {
    let mut hasher = Shake128::new();
    hasher.update(message);

    let mut reader = hasher.finalize_xof();
    let mut out = vec![0u8; n];
    reader.read(&mut out);

    out
}

/// Reads `n` XOF bytes from a fresh SHAKE256 over `message`.
fn shake256(message: &[u8], n: usize) -> Vec<u8> {
    let mut hasher = Shake256::new();
    hasher.update(message);

    let mut reader = hasher.finalize_xof();
    let mut out = vec![0u8; n];
    reader.read(&mut out);

    out
}

/// One SHA-3 Monte Carlo file: the seed digest and the 100 checkpoint digests.
struct Sha3Monte {
    /// `MD[0]`, the initial digest-length seed.
    seed: Vec<u8>,

    /// The expected `MD` at each of the 100 checkpoints, in order.
    checkpoints: Vec<Vec<u8>>,
}

/// Parses a SHA-3 `Monte.rsp` file: one `Seed`, then a run of `COUNT`/`MD`.
fn parse_sha3_monte(rsp: &str) -> Sha3Monte {
    let mut seed = Vec::new();
    let mut checkpoints = Vec::new();

    for line in rsp.lines() {
        let Some((key, value)) = line.split_once('=') else {
            continue;
        };
        let (key, value) = (key.trim(), value.trim());

        match key {
            "Seed" => seed = hex::decode(value).expect("valid hex seed"),
            "MD" => checkpoints.push(hex::decode(value).expect("valid hex MD")),
            _ => {}
        }
    }

    Sha3Monte { seed, checkpoints }
}

/// Runs the SHA-3 Monte Carlo Test (SHA3VS 6.2.2): each checkpoint is 1000
/// iterations of `MD[i] = hash(MD[i-1])`, and `MD[1000]` seeds the next.
fn run_sha3_monte(monte: &Sha3Monte, hash: impl Fn(&[u8]) -> Vec<u8>) {
    let mut md = monte.seed.clone();

    for (j, expected) in monte.checkpoints.iter().enumerate() {
        for _ in 0..1000 {
            md = hash(&md);
        }

        assert_eq!(&md, expected, "SHA-3 Monte checkpoint {j}");
    }
}

/// One SHAKE Monte Carlo file: the seed message, the output-length bounds, and
/// the 100 checkpoint outputs with their lengths.
struct ShakeMonte {
    /// The 128-bit seed message, `Output[0]`.
    seed: Vec<u8>,

    /// Minimum output length in bytes (`[Minimum Output Length]` / 8).
    min_bytes: usize,

    /// Maximum output length in bytes (`[Maximum Output Length]` / 8), the
    /// length of the first iteration's output.
    max_bytes: usize,

    /// The expected `Output` at each of the 100 checkpoints, in order; the
    /// length is carried in the bytes themselves.
    checkpoints: Vec<Vec<u8>>,
}

/// Parses a SHAKE `Monte.rsp` file: the bracketed length bounds, one `Msg`,
/// then a run of `COUNT`/`Outputlen`/`Output`.
fn parse_shake_monte(rsp: &str) -> ShakeMonte {
    let mut seed = Vec::new();
    let mut min_bytes = 0;
    let mut max_bytes = 0;
    let mut checkpoints = Vec::new();

    for line in rsp.lines() {
        let line = line.trim_start_matches('[').trim_end_matches(']');
        let Some((key, value)) = line.split_once('=') else {
            continue;
        };
        let (key, value) = (key.trim(), value.trim());

        match key {
            "Minimum Output Length (bits)" => {
                min_bytes = value.parse::<usize>().expect("min length") / 8;
            }
            "Maximum Output Length (bits)" => {
                max_bytes = value.parse::<usize>().expect("max length") / 8;
            }
            "Msg" => seed = hex::decode(value).expect("valid hex seed"),
            "Output" => checkpoints.push(hex::decode(value).expect("valid hex output")),
            _ => {}
        }
    }

    ShakeMonte {
        seed,
        min_bytes,
        max_bytes,
        checkpoints,
    }
}

/// Runs the SHAKE Monte Carlo Test (SHA3VS 6.2.3): each iteration squeezes
/// `out_len` bytes over the previous output's leftmost 16 bytes (zero-padded),
/// then derives the next length from that output's trailing 16 bits.
fn run_shake_monte(monte: &ShakeMonte, shake: impl Fn(&[u8], usize) -> Vec<u8>) {
    let range = monte.max_bytes - monte.min_bytes + 1;
    let mut output = monte.seed.clone();
    let mut out_len = monte.max_bytes;

    for (j, expected) in monte.checkpoints.iter().enumerate() {
        for _ in 0..1000 {
            let mut msg = [0u8; 16];
            let take = output.len().min(16);
            msg[..take].copy_from_slice(&output[..take]);

            output = shake(&msg, out_len);

            let tail = u16::from_be_bytes([output[output.len() - 2], output[output.len() - 1]]);
            out_len = monte.min_bytes + (tail as usize % range);
        }

        assert_eq!(&output, expected, "SHAKE Monte checkpoint {j}");
    }
}

#[test]
fn sha3_256_short_msg() {
    for v in parse(include_str!("cavp/SHA3_256ShortMsg.rsp")) {
        assert_eq!(Sha3_256::digest(&v.message).as_slice(), v.output.as_slice());
    }
}

#[test]
fn sha3_512_short_msg() {
    for v in parse(include_str!("cavp/SHA3_512ShortMsg.rsp")) {
        assert_eq!(Sha3_512::digest(&v.message).as_slice(), v.output.as_slice());
    }
}

#[test]
fn shake128_short_msg() {
    for v in parse(include_str!("cavp/SHAKE128ShortMsg.rsp")) {
        assert_eq!(shake128(&v.message, v.output.len()), v.output);
    }
}

#[test]
fn shake256_short_msg() {
    for v in parse(include_str!("cavp/SHAKE256ShortMsg.rsp")) {
        assert_eq!(shake256(&v.message, v.output.len()), v.output);
    }
}

#[test]
fn shake128_variable_out() {
    for v in parse(include_str!("cavp/SHAKE128VariableOut.rsp")) {
        assert_eq!(shake128(&v.message, v.output.len()), v.output);
    }
}

#[test]
fn shake256_variable_out() {
    for v in parse(include_str!("cavp/SHAKE256VariableOut.rsp")) {
        assert_eq!(shake256(&v.message, v.output.len()), v.output);
    }
}

#[test]
fn sha3_256_monte() {
    let monte = parse_sha3_monte(include_str!("cavp/SHA3_256Monte.rsp"));
    run_sha3_monte(&monte, |m| Sha3_256::digest(m).to_vec());
}

#[test]
fn sha3_512_monte() {
    let monte = parse_sha3_monte(include_str!("cavp/SHA3_512Monte.rsp"));
    run_sha3_monte(&monte, |m| Sha3_512::digest(m).to_vec());
}

#[test]
fn shake128_monte() {
    let monte = parse_shake_monte(include_str!("cavp/SHAKE128Monte.rsp"));
    run_shake_monte(&monte, shake128);
}

#[test]
fn shake256_monte() {
    let monte = parse_shake_monte(include_str!("cavp/SHAKE256Monte.rsp"));
    run_shake_monte(&monte, shake256);
}

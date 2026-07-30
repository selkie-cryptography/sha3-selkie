//! Build the dashboard's `kat.json` from a nextest run's JUnit output.
//!
//! Usage: kat-report <sha> <junit.xml>
//!
//! Reads a JUnit XML file produced by nextest (enabled via a
//! `[profile.<name>.junit]` section in `.config/nextest.toml`), filters
//! per-test results into two suites — `cavp` (the `tests/cavp.rs` binary,
//! NIST CAVP byte-oriented known-answer vectors) and `properties` (the
//! `tests/properties.rs` binary, differential tests against an independent
//! implementation plus the sponge invariants) — and emits the structured
//! JSON the CI dashboard consumes.
//!
//! `cavp` also carries a per-file breakdown of `tests/cavp/*.rsp`: record
//! counts per vector file, so the panel can show which of the ten files ran
//! and how many answers each pins.
//!
//! Compile: `rustc -O kat-report.rs -o kat-report`

use std::env;
use std::fs;
use std::io::{self, Write};
use std::time::SystemTime;

#[derive(Clone)]
struct TestResult {
    name: String,
    status: String, // "pass", "fail", "ignored"
    detail: String,
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    if args.len() != 3 {
        eprintln!("usage: kat-report <sha> <junit.xml>");
        std::process::exit(1);
    }
    let sha = &args[1];
    let junit_path = &args[2];

    let junit_xml = fs::read_to_string(junit_path).unwrap_or_else(|e| {
        eprintln!("[kat-report] cannot read {junit_path}: {e}");
        std::process::exit(1);
    });

    let (cavp_results, property_results) = parse_junit(&junit_xml);

    let cavp_files = parse_cavp_files();
    let cavp_vectors = cavp_files.iter().map(|f| f.records).sum();

    let all_results: Vec<(&str, &[TestResult], u64)> = vec![
        ("cavp", &cavp_results[..], cavp_vectors),
        // Property tests are generated, not enumerated from a vector file.
        ("properties", &property_results[..], 0),
    ];

    let out = io::stdout();
    let mut w = io::BufWriter::new(out.lock());

    writeln!(w, "{{")?;
    writeln!(w, "  \"sha\": {},", json_str(sha))?;
    writeln!(w, "  \"updated_at\": {},", json_str(&iso8601_now()))?;

    // Per-suite summary and results.
    writeln!(w, "  \"suites\": [")?;
    for (si, &(suite_name, results, vectors)) in all_results.iter().enumerate() {
        let pass = results.iter().filter(|r| r.status == "pass").count();
        let fail = results.iter().filter(|r| r.status == "fail").count();
        let ignored = results
            .iter()
            .filter(|r| r.status == "ignored" || r.status == "skip")
            .count();

        writeln!(w, "    {{")?;
        writeln!(w, "      \"name\": {},", json_str(suite_name))?;
        writeln!(w, "      \"pass\": {pass},")?;
        writeln!(w, "      \"fail\": {fail},")?;
        writeln!(w, "      \"ignored\": {ignored},")?;
        writeln!(w, "      \"skip\": {ignored},")?;
        writeln!(w, "      \"total\": {},", results.len())?;
        writeln!(w, "      \"vectors\": {vectors},")?;
        writeln!(w, "      \"tests\": [")?;

        for (i, r) in results.iter().enumerate() {
            write!(
                w,
                "        {{\"name\": {}, \"status\": {}",
                json_str(&r.name),
                json_str(&r.status)
            )?;
            if !r.detail.is_empty() {
                write!(w, ", \"detail\": {}", json_str(&r.detail))?;
            }
            write!(w, "}}")?;
            if i + 1 < results.len() {
                writeln!(w, ",")?;
            } else {
                writeln!(w)?;
            }
        }

        // Only cavp has a per-file vector breakdown.
        if suite_name == "cavp" && !cavp_files.is_empty() {
            writeln!(w, "      ],")?;
            writeln!(w, "      \"vector_files\": [")?;
            for (fi, vf) in cavp_files.iter().enumerate() {
                write!(w, "        {}", vf.json())?;
                if fi + 1 < cavp_files.len() {
                    writeln!(w, ",")?;
                } else {
                    writeln!(w)?;
                }
            }
            write!(w, "      ]\n    }}")?;
        } else {
            write!(w, "      ]\n    }}")?;
        }
        if si + 1 < all_results.len() {
            writeln!(w, ",")?;
        } else {
            writeln!(w)?;
        }
    }
    writeln!(w, "  ]")?;
    writeln!(w, "}}")?;

    Ok(())
}

/// Parse nextest's JUnit XML into (wycheproof, acvp, interop) suite results.
///
/// nextest emits one `<testcase classname="…" name="…" time="…"/>`
/// per test, optionally wrapping a `<failure>` or `<skipped/>` child
/// for non-passing outcomes. This walks the file line by line; we
/// don't need a full XML parser because the format is regular and
/// each `<testcase>` opens on its own line.
fn parse_junit(xml: &str) -> (Vec<TestResult>, Vec<TestResult>) {
    let mut cavp = Vec::new();
    let mut properties = Vec::new();

    let mut current: Option<(String, TestResult)> = None;

    for line in xml.lines() {
        let l = line.trim();

        if l.starts_with("<testcase ") {
            let classname = extract_xml_attr(l, "classname");
            let name = extract_xml_attr(l, "name");
            let r = TestResult {
                name,
                status: "pass".to_string(),
                detail: String::new(),
            };
            // Self-closing, or opened and closed on one line: complete as
            // read. Otherwise the status comes from a child element and the
            // case closes on a later line. A one-line form is valid XML, and
            // treating it as unterminated would drop the test silently.
            if l.ends_with("/>") || l.contains("</testcase>") {
                push_into_suite(classname, r, &mut cavp, &mut properties);
            } else {
                current = Some((classname, r));
            }
        } else if l.starts_with("<failure") {
            if let Some((_, r)) = current.as_mut() {
                r.status = "fail".to_string();
                if r.detail.is_empty() {
                    let msg = extract_xml_attr(l, "message");
                    if !msg.is_empty() {
                        r.detail = msg;
                    }
                }
            }
        } else if l.starts_with("<skipped") {
            if let Some((_, r)) = current.as_mut() {
                r.status = "ignored".to_string();
            }
        } else if l.starts_with("</testcase>") {
            if let Some((classname, r)) = current.take() {
                push_into_suite(classname, r, &mut cavp, &mut properties);
            }
        }
    }

    (cavp, properties)
}

/// Routes a test result into its suite by the integration binary the
/// classname encodes (`<crate>::<binary>`): `cavp` carries the NIST vectors,
/// `properties` the differential and invariant tests. Tests matching no suite
/// (the lib tests) are dropped — CI is the source of truth for whether they
/// passed; kat.json is just a per-suite view for the dashboard.
fn push_into_suite(
    classname: String,
    r: TestResult,
    cavp: &mut Vec<TestResult>,
    properties: &mut Vec<TestResult>,
) {
    if classname.ends_with("::cavp") || classname == "cavp" {
        cavp.push(r);
    } else if classname.ends_with("::properties") || classname == "properties" {
        properties.push(r);
    }
}

/// Pulls an XML attribute value out of a single `<tag …>` line.
/// Doesn't handle escaped quotes inside attribute values — fine for
/// nextest's output, which doesn't emit those for our test names.
fn extract_xml_attr(line: &str, key: &str) -> String {
    let needle = format!(" {key}=\"");
    let Some(start) = line.find(&needle) else {
        return String::new();
    };
    let rest = &line[start + needle.len()..];
    let end = rest.find('"').unwrap_or(rest.len());
    rest[..end].to_string()
}

fn json_str(s: &str) -> String {
    let mut out = String::with_capacity(s.len() + 2);
    out.push('"');
    for c in s.chars() {
        match c {
            '"' => out.push_str("\\\""),
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if (c as u32) < 0x20 => {
                out.push_str(&format!("\\u{:04x}", c as u32));
            }
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

fn iso8601_now() -> String {
    let secs = SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    // Quick ISO 8601 formatter without chrono.
    let (y, mo, d, h, mi, s) = epoch_to_ymdhms(secs);
    format!("{y:04}-{mo:02}-{d:02}T{h:02}:{mi:02}:{s:02}Z")
}

fn epoch_to_ymdhms(secs: u64) -> (u64, u64, u64, u64, u64, u64) {
    let s = secs % 60;
    let m = (secs / 60) % 60;
    let h = (secs / 3600) % 24;
    let mut days = secs / 86400;

    let mut year = 1970u64;
    loop {
        let dy = if is_leap(year) { 366 } else { 365 };
        if days < dy {
            break;
        }
        days -= dy;
        year += 1;
    }
    let mdays: [u64; 12] = [31, if is_leap(year) { 29 } else { 28 }, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    let mut month = 0u64;
    while month < 12 && days >= mdays[month as usize] {
        days -= mdays[month as usize];
        month += 1;
    }
    (year, month + 1, days + 1, h, m, s)
}

fn is_leap(y: u64) -> bool {
    (y % 4 == 0 && y % 100 != 0) || y % 400 == 0
}

/// One CAVP response file and how many known answers it pins.
struct CavpFile {
    /// File stem, e.g. `SHAKE128VariableOut`.
    name: String,

    /// Human-readable algorithm and test type, e.g. `SHAKE128 VariableOut`.
    algorithm: String,

    /// Number of answer records in the file.
    records: u64,
}

impl CavpFile {
    /// Renders the object the dashboard's per-file card reads.
    ///
    /// CAVP known answers are all positive, so `valid` is the record count and
    /// `invalid` is zero — the fields exist because the panel is shared with
    /// suites that carry negative vectors.
    fn json(&self) -> String {
        format!(
            "{{\n          \"file\": {},\n          \"algorithm\": {},\n          \"total\": {},\n          \"valid\": {},\n          \"invalid\": 0,\n          \"vectors\": []\n        }}",
            json_str(&self.name),
            json_str(&self.algorithm),
            self.records,
            self.records,
        )
    }
}

/// Reads `tests/cavp/*.rsp` and counts the answer records in each.
///
/// The three CAVS file shapes delimit records differently: ShortMsg by `Len =`,
/// Monte and VariableOut by `COUNT =`. Counting both and taking the larger
/// covers all three without parsing the bracketed headers.
fn parse_cavp_files() -> Vec<CavpFile> {
    let dir = match fs::read_dir("tests/cavp") {
        Ok(d) => d,
        Err(_) => return Vec::new(),
    };

    let mut files = Vec::new();
    for entry in dir.flatten() {
        let path = entry.path();
        if path.extension().map_or(true, |e| e != "rsp") {
            continue;
        }
        let content = match fs::read_to_string(&path) {
            Ok(c) => c,
            Err(_) => continue,
        };
        let name = path
            .file_stem()
            .map(|s| s.to_string_lossy().to_string())
            .unwrap_or_default();

        let count = |needle: &str| {
            content
                .lines()
                .filter(|l| l.trim_start().starts_with(needle))
                .count() as u64
        };
        let records = count("Len = ").max(count("COUNT = "));

        files.push(CavpFile {
            algorithm: describe_cavp(&name),
            name,
            records,
        });
    }

    // Deterministic order across filesystems.
    files.sort_by(|a, b| a.name.cmp(&b.name));
    files
}

/// Turns a CAVS file stem into `<algorithm> <test type>`, e.g.
/// `SHA3_256ShortMsg` into `SHA3-256 ShortMsg`.
fn describe_cavp(stem: &str) -> String {
    let (algorithm, kind) = if let Some(rest) = stem.strip_prefix("SHA3_") {
        let (bits, kind) = rest.split_at(rest.find(|c: char| !c.is_ascii_digit()).unwrap_or(rest.len()));
        (format!("SHA3-{bits}"), kind)
    } else if let Some(rest) = stem.strip_prefix("SHAKE") {
        let (bits, kind) = rest.split_at(rest.find(|c: char| !c.is_ascii_digit()).unwrap_or(rest.len()));
        (format!("SHAKE{bits}"), kind)
    } else {
        return stem.to_string();
    };

    if kind.is_empty() {
        algorithm
    } else {
        format!("{algorithm} {kind}")
    }
}

// Self-test against a baked-in JUnit fixture. Build and run with
// `rustc --test -O kat-report.rs && ./kat-report`. Fixture matches
// nextest's actual emitted format. If a future nextest changes the
// JUnit shape enough that the parser misroutes tests, this test
// fails before the parser's misbehavior reaches the dashboard.
#[cfg(test)]
mod tests {
    use super::*;

    /// Fixture: one passing and one failing cavp test, two passing
    /// property tests, and a lib test that should route into no suite.
    const FIXTURE: &str = r#"<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="nextest-run" tests="5" failures="1" errors="0" uuid="aaa" timestamp="2026-07-30T00:00:00.000-04:00" time="0.083">
    <testsuite name="sha3-selkie" tests="1" disabled="0" errors="0" failures="0">
        <testcase name="backend::tests::keccak_f1600_zero_state_kat" classname="sha3-selkie" timestamp="2026-07-30T00:00:00.000-04:00" time="0.001">
        </testcase>
    </testsuite>
    <testsuite name="sha3-selkie::cavp" tests="2" disabled="0" errors="0" failures="1">
        <testcase name="sha3_256_short_msg" classname="sha3-selkie::cavp" timestamp="2026-07-30T00:00:00.000-04:00" time="0.072">
        </testcase>
        <testcase name="shake128_variable_out" classname="sha3-selkie::cavp" timestamp="2026-07-30T00:00:00.000-04:00" time="0.072">
            <failure type="test failure" message="bad vector">trace</failure>
        </testcase>
    </testsuite>
    <testsuite name="sha3-selkie::properties" tests="2" disabled="0" errors="0" failures="0">
        <testcase name="shake128_matches_libcrux" classname="sha3-selkie::properties" timestamp="2026-07-30T00:00:00.000-04:00" time="0.072"></testcase>
        <testcase name="chunked_absorb_equals_one_shot" classname="sha3-selkie::properties" timestamp="2026-07-30T00:00:00.000-04:00" time="0.072">
        </testcase>
    </testsuite>
</testsuites>
"#;

    #[test]
    fn parse_junit_routes_and_statuses() {
        let (cavp, properties) = parse_junit(FIXTURE);

        // Routing: each integration binary's tests land in its suite; the lib
        // test appears in neither.
        let cavp_names: Vec<&str> = cavp.iter().map(|t| t.name.as_str()).collect();
        let property_names: Vec<&str> = properties.iter().map(|t| t.name.as_str()).collect();
        assert_eq!(
            cavp_names,
            vec!["sha3_256_short_msg", "shake128_variable_out"],
            "cavp suite tests + order"
        );
        assert_eq!(
            property_names,
            vec!["shake128_matches_libcrux", "chunked_absorb_equals_one_shot"],
            "properties suite tests + order"
        );
        for names in [&cavp_names, &property_names] {
            assert!(!names
                .iter()
                .any(|n| *n == "backend::tests::keccak_f1600_zero_state_kat"));
        }

        // Statuses: the `<failure>` child marks its enclosing testcase.
        assert_eq!(cavp[0].status, "pass");
        assert_eq!(cavp[1].status, "fail");
        assert_eq!(cavp[1].detail, "bad vector");
    }
}

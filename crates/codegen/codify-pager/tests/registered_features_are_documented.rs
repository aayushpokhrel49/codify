//! `FEATURES` is the source of truth and the operator tables are hand-maintained mirrors with no compile-time check of their own.
//! This test is that check.

use codify_shell::agent::config::FEATURES;
use std::fs;
use std::path::PathBuf;

/// Read one of the internal operator docs.
///
/// These docs are not part of the public source tree. `include_str!` would make
/// the whole test target fail to compile when they are absent, so read them at
/// runtime and skip the check instead.
fn internal_doc(name: &str) -> Option<String> {
    let path = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("docs/internal")
        .join(name);
    fs::read_to_string(path).ok()
}

#[test]
fn every_registered_feature_reaches_the_operator() {
    let (Some(enterprise), Some(env_vars)) = (
        internal_doc("25-enterprise.md"),
        internal_doc("22-environment-variables.md"),
    ) else {
        eprintln!("skipping: docs/internal is not present in this source tree");
        return;
    };

    for spec in FEATURES {
        assert!(
            enterprise.contains(&format!("`{}`", spec.key)),
            "{} has no row in the 25-enterprise.md pinning table",
            spec.key,
        );
        assert!(
            env_vars.contains(&format!("`{}`", spec.env)),
            "{} is undocumented in 22-environment-variables.md",
            spec.env,
        );
    }
}

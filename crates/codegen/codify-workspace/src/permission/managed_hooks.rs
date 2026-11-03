use std::path::Path;

use codify_permission_rules::managed_policy::ManagedSettings;

/// The disabled-hooks file under `grok_home` plus the `allow_managed_hooks_only` pin of `managed`.
pub fn disabled_hooks_snapshot(
    managed: &ManagedSettings,
    grok_home: Option<&Path>,
) -> codify_hooks::trust::DisabledHooks {
    codify_hooks::trust::DisabledHooks::load(grok_home, managed.non_managed_hooks.is_disabled())
}

//! Vendor compatibility configuration; `codify-config` owns it.

pub(crate) use codify_config::compat::INSTRUCTION_FILENAMES;
pub use codify_config::compat::{
    COMPAT_CELLS, CompatCell, CompatConfig, CompatConfigToml, CompatRemoteKey, CompatSurface,
    CompatVendor, VendorCompat, VendorCompatToml,
};

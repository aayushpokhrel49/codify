//! Session lifecycle event structs.
//!
//! The structs moved to `codify-telemetry` in the telemetry crate split.
//! This module re-exports them so the existing import path in shell keeps working.

pub(crate) use codify_telemetry::session_metrics::{
    DoomLoopDetected, DoomLoopRecovery, LongReasoningReminderTurn, SessionContextSnapshot,
    SessionStartKind, SessionStarted, TraceUploadAttempted, TraceUploadFailed, TraceUploadSkipped,
    TraceUploadSucceeded, Turn, TurnCompletedLifecycle,
};

//! Linux process monitor using procfs
//!
//! This module is only compiled on Linux targets.

use super::backend::{ProcessInfo, ProcessMonitor, ProcessStats, SystemMetrics};

/// Linux-specific process monitor using procfs
pub struct LinuxMonitor;

impl LinuxMonitor {
    /// Create a new Linux process monitor
    pub fn new() -> Self {
        LinuxMonitor
    }
}

impl Default for LinuxMonitor {
    fn default() -> Self {
        Self::new()
    }
}

impl ProcessMonitor for LinuxMonitor {
    fn find_by_port(&self, _port: u16) -> Option<ProcessInfo> {
        // TODO: Implement using /proc/net/tcp and /proc/{pid}/fd
        None
    }

    fn find_by_name(&self, _name: &str) -> Vec<ProcessInfo> {
        // TODO: Implement using /proc/{pid}/comm
        Vec::new()
    }

    fn get_process_stats(&self, _pid: u32) -> Option<ProcessStats> {
        // TODO: Implement using /proc/{pid}/stat
        None
    }

    fn get_system_metrics(&self) -> SystemMetrics {
        // TODO: Implement using /proc/stat, /proc/meminfo, /proc/loadavg
        SystemMetrics {
            cpu_percent: 0.0,
            memory_used_bytes: 0,
            memory_total_bytes: 0,
            memory_percent: 0.0,
            load_average_1m: 0.0,
            load_average_5m: 0.0,
            load_average_15m: 0.0,
        }
    }

    fn is_process_alive(&self, pid: u32) -> bool {
        // Check if /proc/{pid} exists
        std::path::Path::new(&format!("/proc/{}", pid)).exists()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_linux_monitor_creation() {
        let _monitor = LinuxMonitor::new();
    }
}

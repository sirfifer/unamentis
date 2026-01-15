//! Service templates - blueprints for creating service instances

use serde::{Deserialize, Serialize};

use super::ServiceInstance;

/// Category for organizing services in the UI
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum ServiceCategory {
    #[default]
    Core,
    Development,
    Database,
    Infrastructure,
    Custom,
}

/// A service template defines how to start/stop a type of service
///
/// Templates support variable substitution in commands:
/// - `{port}` - The instance's port number
/// - `{config}` - Path to the instance's config file
/// - `{working_dir}` - The instance's working directory
/// - `{pid}` - The process ID (for stop commands)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ServiceTemplate {
    /// Unique identifier for this template
    pub id: String,

    /// Human-readable name
    pub display_name: String,

    /// Optional description
    #[serde(default)]
    pub description: Option<String>,

    /// Default port for new instances
    pub default_port: u16,

    /// Valid port range for instances (min, max)
    #[serde(default)]
    pub port_range: Option<(u16, u16)>,

    /// Command template to start the service
    /// Supports: {port}, {config}, {working_dir}
    pub start_command: String,

    /// Optional custom stop command (defaults to SIGTERM)
    /// Supports: {pid}
    #[serde(default)]
    pub stop_command: Option<String>,

    /// Health check endpoint template
    /// Supports: {port}
    #[serde(default)]
    pub health_endpoint: Option<String>,

    /// Health check timeout in milliseconds
    #[serde(default = "default_health_timeout")]
    pub health_timeout_ms: u32,

    /// Category for UI organization
    #[serde(default)]
    pub category: ServiceCategory,

    /// Whether multiple instances can run simultaneously
    #[serde(default)]
    pub supports_multiple: bool,

    /// Whether this is a Docker Compose service
    #[serde(default)]
    pub is_docker: bool,

    /// Default environment variables
    #[serde(default)]
    pub default_env: std::collections::HashMap<String, String>,
}

fn default_health_timeout() -> u32 {
    5000
}

impl ServiceTemplate {
    /// Build the start command for a specific instance
    pub fn build_start_command(&self, instance: &ServiceInstance) -> String {
        let mut cmd = self.start_command.clone();

        cmd = cmd.replace("{port}", &instance.port.to_string());

        if let Some(ref config) = instance.config_path {
            cmd = cmd.replace("{config}", &config.display().to_string());
        } else {
            cmd = cmd.replace("{config}", "");
        }

        if let Some(ref working_dir) = instance.working_dir {
            cmd = cmd.replace("{working_dir}", &working_dir.display().to_string());
        } else {
            cmd = cmd.replace("{working_dir}", ".");
        }

        cmd
    }

    /// Build the health endpoint URL for a specific instance
    pub fn build_health_endpoint(&self, instance: &ServiceInstance) -> Option<String> {
        self.health_endpoint
            .as_ref()
            .map(|endpoint| endpoint.replace("{port}", &instance.port.to_string()))
    }

    /// Check if a port is within the valid range for this template
    pub fn is_port_valid(&self, port: u16) -> bool {
        match self.port_range {
            Some((min, max)) => port >= min && port <= max,
            None => true, // No range specified, any port is valid
        }
    }

    /// Get the next available port (simple increment from default)
    pub fn next_available_port(&self, used_ports: &[u16]) -> Option<u16> {
        let (min, max) = self
            .port_range
            .unwrap_or((self.default_port, self.default_port + 100));

        (min..=max).find(|port| !used_ports.contains(port))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn create_test_template() -> ServiceTemplate {
        ServiceTemplate {
            id: "test-service".to_string(),
            display_name: "Test Service".to_string(),
            description: Some("A test service".to_string()),
            default_port: 8000,
            port_range: Some((8000, 8099)),
            start_command: "python3 {working_dir}/server.py --port {port} --config {config}"
                .to_string(),
            stop_command: Some("kill {pid}".to_string()),
            health_endpoint: Some("http://localhost:{port}/health".to_string()),
            health_timeout_ms: 5000,
            category: ServiceCategory::Core,
            supports_multiple: true,
            is_docker: false,
            default_env: Default::default(),
        }
    }

    fn create_test_instance() -> ServiceInstance {
        use super::super::instance::ServiceStatus;

        ServiceInstance {
            id: "test-instance".to_string(),
            template_id: "test-service".to_string(),
            port: 8001,
            working_dir: Some(PathBuf::from("/opt/app")),
            config_path: Some(PathBuf::from("/etc/app/config.yaml")),
            version: Some("1.0.0".to_string()),
            git_branch: None,
            tags: vec!["production".to_string()],
            auto_start: false,
            env_vars: Default::default(),
            status: ServiceStatus::Stopped,
            pid: None,
            started_at: None,
            created_at: chrono::Utc::now(),
            created_via: "config".to_string(),
        }
    }

    #[test]
    fn test_build_start_command() {
        let template = create_test_template();
        let instance = create_test_instance();

        let cmd = template.build_start_command(&instance);
        assert_eq!(
            cmd,
            "python3 /opt/app/server.py --port 8001 --config /etc/app/config.yaml"
        );
    }

    #[test]
    fn test_build_health_endpoint() {
        let template = create_test_template();
        let instance = create_test_instance();

        let endpoint = template.build_health_endpoint(&instance);
        assert_eq!(endpoint, Some("http://localhost:8001/health".to_string()));
    }

    #[test]
    fn test_port_validation() {
        let template = create_test_template();

        assert!(template.is_port_valid(8000));
        assert!(template.is_port_valid(8050));
        assert!(template.is_port_valid(8099));
        assert!(!template.is_port_valid(7999));
        assert!(!template.is_port_valid(8100));
    }

    #[test]
    fn test_next_available_port() {
        let template = create_test_template();

        // No ports used
        assert_eq!(template.next_available_port(&[]), Some(8000));

        // First port used
        assert_eq!(template.next_available_port(&[8000]), Some(8001));

        // Multiple ports used
        assert_eq!(
            template.next_available_port(&[8000, 8001, 8002]),
            Some(8003)
        );
    }
}

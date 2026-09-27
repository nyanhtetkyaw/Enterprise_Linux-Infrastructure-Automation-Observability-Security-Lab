output "network_dmz" {
  value = podman_network.dmz.name
}

output "network_application" {
  value = podman_network.application.name
}

output "network_database" {
  value = podman_network.database.name
}

output "network_management" {
  value = podman_network.management.name
}

output "jenkins_url" {
  value = "http://localhost:8088"
}

output "sonarqube_url" {
  value = "http://localhost:9000"
}

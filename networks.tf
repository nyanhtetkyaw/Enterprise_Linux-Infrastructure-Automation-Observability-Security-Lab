resource "podman_network" "dmz" {
  name   = "lab-dmz"
  driver = "bridge"
}

resource "podman_network" "application" {
  name   = "lab-application"
  driver = "bridge"
}

resource "podman_network" "database" {
  name   = "lab-database"
  driver = "bridge"
}

resource "podman_network" "management" {
  name   = "lab-management"
  driver = "bridge"
}

variable "RELEASE" {
    default = "11.0.0"
}

variable "PUBLIC_KEY" {
    default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJEqaoZZg8VFmpTPpM8xdlmxKZMxg5icglE8oGYZG+ZQ the_dusky@icloud"
}

target "default" {
  platforms = ["linux/amd64"]
  dockerfile = "Dockerfile"
  tags = ["emprops/auto1111:image5"]
  contexts = {
    proxy = "proxy"
  }
  args = {
    PUBLIC_KEY = "${PUBLIC_KEY}"
  }
}

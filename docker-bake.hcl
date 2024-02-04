variable "RELEASE" {
    default = "11.0.0"
}

target "default" {
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64"]
  tags = ["emprops/auto1111:web-ui-${RELEASE}-v1"]
  contexts = {
    proxy = "proxy"
  }
  args = {
    WEBUI_VERSION = "v1.7.0"
  }
}
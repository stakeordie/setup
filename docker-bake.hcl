variable "RELEASE" {
    default = "11.0.0"
}

target "default" {
  dockerfile = "Dockerfile"
  platforms = ["linux/amd64"]
  tags = ["emprops/auto1111:v1"]
  contexts = {
    proxy = "proxy"
  }
  args = {
    WEBUI_VERSION = "v1.7.0"
    PYTHON_VERSION = "3.10"
    TORCH = "torch==2.1.0+cu118 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118"
  }
}
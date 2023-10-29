target "201-py310-cuda1180-devel" {
    dockerfile = "Dockerfile"
    tags = ["emprops/runpod:2.0.1-py3.10-cuda11.8.0-devel"]
    contexts = {
        scripts = "."
        proxy = "./proxy"
    }
    args = {
        BASE_IMAGE = "nvidia/cuda:11.8.0-devel-ubuntu22.04"
        PYTHON_VERSION = "3.10.6"
        TORCH = "torch==2.0.1+cu118 torchvision==0.15.2+cu118 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118"
    }
}
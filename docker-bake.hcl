target "210-py310-cuda1180-devel" {
    dockerfile = "Dockerfile"
    tags = ["emprops/auto1111:2.1.0-py3.10-cuda11.8.0"]
    contexts = {
        scripts = "."
        proxy = "./proxy"
    }
    args = {
        BASE_IMAGE = "runpod/pytorch:2.0.1-py3.10-cuda11.8.0-devel"
        PYTHON_VERSION = "3.10"
        TORCH = "torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118"
    }
    platforms = ["linux/arm64"]
}

target "210-py310-cuda1220-devel" {
    dockerfile = "Dockerfile"
    tags = ["emprops/pytorch:2.1.0-py3.10-cuda12.2.0"]
    contexts = {
        scripts = "."
        proxy = "./proxy"
    }
    args = {
        BASE_IMAGE = "nvcr.io/nvidia/cuda:12.2.0-devel-ubuntu22.04"
        PYTHON_VERSION = "3.10"
        TORCH = "torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121  --trusted-host download.pytorch.org"
    }
    platforms = ["linux/arm64"]
}

target "210-py310-cuda1222-devel" {
    dockerfile = "Dockerfile"
    tags = ["emprops/pytorch:2.1.0-py3.10-cuda12.2.2"]
    contexts = {
        scripts = "."
        proxy = "./proxy"
    }
    args = {
        BASE_IMAGE = "nvidia/cuda:12.2.2-devel-ubuntu22.04"
        PYTHON_VERSION = "3.10"
        TORCH = "torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121  --trusted-host download.pytorch.org"
    }
    platforms = ["linux/arm64"]
}
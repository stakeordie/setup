import json
import requests
import io
import base64
from PIL import Image

def load_input_image(path):
    with open(path, 'rb') as file:
        return base64.b64encode(file.read()).decode()

url = "http://127.0.0.1:3000"
payload = {
        "prompt": "A PURPLE VEST",
        "negative_prompt": "",
        "width": 1024,
        "height": 1024,
        "steps": 20,
        "cfg": 10,
        "sampler_index": "DPM++ 2S a Karras",
        "controlnet_input_images": [load_input_image('/root/setup/output.png')],
        "controlnet_module": 'canny',
        "controlnet_model": 'diffusers_xl_canny_full [2b69fca4]',
        "controlnet_guidance": 1.0,
    }

response = requests.post(url=f'{url}/sdapi/v1/txt2img', json=payload)

r = response.json()

image = Image.open(io.BytesIO(base64.b64decode(r['images'][0])))
image.save('cnet_output.png')
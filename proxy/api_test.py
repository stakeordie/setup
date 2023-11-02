import json
import requests
import io
import base64
import cv2
from PIL import Image

url = "http://127.0.0.1:3000"
img = cv2.imread('../output.png')
png_img = cv2.imencode('.png', img)
preproc_64 = base64.b64encode(png_img[1]).decode('utf-8')
payload = {
        "prompt": "A PURPLE VEST",
        "negative_prompt": "",
        "width": 1024,
        "height": 1024,
        "steps": 20,
        "cfg": 10,
        "sampler_index": "DPM++ 2S a Karras",
        "controlnet_units": [
            {
                "input_image": preproc_64,
                "mask": '',
                "module": "none",
                "model": "diffusers_xl_canny_full [2b69fca4]",
                "weight": 1.6,
                "resize_mode": "Scale to Fit (Inner Fit)",
                "lowvram": False,
                "processor_res": 1024,
                "threshold_a": 64,
                "threshold_b": 64,
                "guidance": 1,
                "guidance_start": 0,
                "guidance_end": 1,
                "guessmode": True
            }
        ]
    }

response = requests.post(url=f'{url}/sdapi/v1/txt2img', json=payload)

r = response.json()

image = Image.open(io.BytesIO(base64.b64decode(r['images'][0])))
image.save('output.png')
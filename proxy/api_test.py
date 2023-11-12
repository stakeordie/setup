import json
import requests
import io
import base64
import argparse
from PIL import Image
parser = argparse.ArgumentParser()

parser.add_argument("-m", "--nmethod", help="GPU or CPU", default="GPU")
args = parser.parse_args()
def load_input_image(path):
    with open(path, 'rb') as file:
        return base64.b64encode(file.read()).decode()

url = "http://127.0.0.1:3000/sdapi/v1/txt2img"
payload = {
    "cfg_scale": 7,
    "height": 1024,
    "width": 1024,
    "negative_prompt": "((photo)), ((photograph)), trees, nature, text, lines of text, frame, frames, border, title, words, print",
    "prompt": "an SNES Video Game Scene. Perspective from above, godlike, tilt shift, the city is a toy. Looking down through clouds. Blimps fly below. A (broken down) ((crumbling)) empty high-rise city like New York. in winter, snow storm, cold, ice, deep freeze. it is the middle of the day, bright, sunshine. . A massive ((explosion)) in the foreground on a section of the seawall that towers over everything. Water pours into the city beginning the flood that will be its certain demise.",
    "sampler_name": "DPM++ 2M",
    "steps": 20,
    "randn_source": args.nmethod,
    "seed": "754943641"
}

response = requests.post(url=f'{url}', json=payload)

r = response.json()

image = Image.open(io.BytesIO(base64.b64decode(r['images'][0])))
image.save('/root/setup/proxy/test/output4.png')
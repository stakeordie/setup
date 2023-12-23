import json
import requests
import io
import base64
import argparse
import runpod
from PIL import Image

runpod.api_key = "PO4DSUZ45QLDVTEAFXAC2NN4CQJK747FZ7D44YMT"

parser = argparse.ArgumentParser()

parser.add_argument("-p", "--port", help="Instance Port", default="3100")
parser.add_argument("--output-file-name", help="Name of output file. Example: my_output.png", default="output.png")
parser.add_argument("--cfg-scale", help="CFG Scale (0 - Unlimited, 7.5 standard)", default="7.5")
parser.add_argument("--height", help="Height in Pixels", default="1024")
parser.add_argument("--width", help="Width in Pixels", default="1024")
parser.add_argument("--prompt", help="Prompt", default="an SNES Video Game Scene. Perspective from above, godlike, tilt shift, the city is a toy. Looking down through clouds. Blimps fly below. A (broken down) ((crumbling)) empty high-rise city like New York. in winter, snow storm, cold, ice, deep freeze. it is the middle of the day, bright, sunshine. . A massive ((explosion)) in the foreground on a section of the seawall that towers over everything. Water pours into the city beginning the flood that will be its certain demise.")
parser.add_argument("--negative-prompt", help="Negative Prompt", default="((photo)), ((photograph)), trees, nature, text, lines of text, frame, frames, border, title, words, print")
parser.add_argument("--steps", help="Steps (0 - 50)", default="20")
parser.add_argument("--seed", help="Stable Diffusion Seed (-1 = Random)", default="92333095")
parser.add_argument("--sampler-name", help="Sampler Name", default="DPM++ 2M")
parser.add_argument("--random-noise-method", help="GPU or CPU", default="GPU")

args = parser.parse_args()
def load_input_image(path):
    with open(path, 'rb') as file:
        return base64.b64encode(file.read()).decode()
    
endpoint = runpod.Endpoint("ohiqabd970tfi5")


payload = {
    "cfg_scale": args.cfg_scale,
    "height": args.height,
    "width": args.width,
    "negative_prompt": args.negative_prompt,
    "prompt": args.prompt,
    "sampler_name": args.sampler_name,
    "steps": args.steps,
    "seed": args.seed,
    "override_settings": {
      "randn_source": args.random_noise_method,
    },
    "override_settings_restore_afterwards": "true"
}

print (payload)

response = endpoint.run_sync(payload)

image = Image.open(io.BytesIO(base64.b64decode(response['images'][0])))
image.save(f'/Users/the_dusky/Downloads/{args.output_file_name}')
import json
import requests
import io
import base64
import argparse
import runpod
from PIL import Image

runpod.api_key = "V940W3PSL877P9OIL9W76EIL0P1G8O7NO6HGD0JK"

parser = argparse.ArgumentParser()

parser.add_argument("-p", "--port", help="Instance Port", default="3100")
parser.add_argument("--cfg-scale", help="CFG Scale (0 - Unlimited, 7.5 standard)", default="7")
parser.add_argument("--height", help="Height in Pixels", default="1024")
parser.add_argument("--width", help="Width in Pixels", default="1024")
parser.add_argument("--prompt", help="Prompt", default="an illustration in the style of an RPG. Perspective from above, godlike, tilt shift, the city is a toy. Looking down through clouds. Blimps fly below. A (broken down) ((crumbling)) empty high-rise city like New York. in winter, snow storm, cold, ice, deep freeze. it is the middle of the day, bright, sunshine. the sky is a deep red and orang hew. A massive ((massive flood)) in the foreground on a section of the seawall that towers over everything. Water pours into the city beginning the flood that will be its certain demise.")
parser.add_argument("--negative-prompt", help="Negative Prompt", default="((photo)), ((photograph)), trees, nature, text, lines of text, frame, frames, border, title, words, print,")
parser.add_argument("--steps", help="Steps (0 - 50)", default="20")
parser.add_argument("--seed", help="Stable Diffusion Seed (-1 = Random)", default="42597708")
parser.add_argument("--sampler-name", help="Sampler Name", default="DPM++ 2M")
parser.add_argument("--random-noise-method", help="GPU or CPU", default="GPU")
parser.add_argument("--denoising-strength", help="Denoising Strength (0 - 1)", default="0.75")
parser.add_argument("--image", help="Image URL", default="https://cdn.emprops.ai/flat-files/994aa763-d9bb-42e4-b08e-553a27d67326/9e3ae556-27a7-4245-b452-8bf543238b19.png")
parser.add_argument("--inference_type", help="Inference Type (txt2img, img2img, upscale)", default="img2img")

args = parser.parse_args()
# def load_input_image(path):
#     with open(path, 'rb') as file:
#         return base64.b64encode(file.read()).decode()
    
endpoint = runpod.Endpoint("q2016dk562ijwf")


def get_as_base64(url):

    base64_bytes = base64.b64encode(requests.get(url).content)


    return base64_bytes.decode('utf-8')

if(args.inference_type == 'upscale'):
  type = "extra-single-image"
else:
  type = args.inference_type  

payload_upscale = {
  "enabled": "true",
  "upscaling_resize": 2,
  "upscaler_1": "ESRGAN_4x",
  "upscaler_2": "Nearest",
  "extras_upscaler_2_visibility": 0,
  "gfpgan_visibility": 0,
  "codeformer_visibility": 0,
  "codeformer_weight": 0,
  "image": get_as_base64(args.image),
}

payload_gen_img = {
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
    "override_settings_restore_afterwards": "true",
    "denoising_strength": args.denoising_strength,
    "init_images": [get_as_base64(args.image)],
}

payload_gen_txt = {
    override_settings: {
      sd_model_checkpoint: 'v1-5-pruned.ckpt [e1441589a6]',
      enable_pnginfo: false
    },
    prompt: "A Photo Realistic award winning 8k photo of a Woman's face with freckles on a train platform in the 1920s in Paris",
    negative_prompt: '',
    sampler_name: 'DPM++ SDE Karras',
    steps: 20,
    cfg_scale: 8.01,
    width: 512,
    height: 512,
    img2img_enabled: false,
    img2img_source: 'p5',
    denoising_strength: 0.99,
    image: '',
    image_variable: 'image_set',
    refiner_switch_at: 0.9,
    refiner_checkpoint: '',
    seed: 453200137
}

if(type == "txt2img"):
  payload = payload_gen_txt
  file_name = "t2i_output.png"
elif (type == "img2img"):
  payload = payload_gen_img
  file_name = "i2i_output.png"
else:
  payload = payload_upscale
  file_name = "us_upscale_output.png"

print (payload)

response = endpoint.run_sync({"prompt": payload, "type": type})

# with open('/Users/the_dusky/Downloads/output.txt', 'w') as f:
#     f.write(f'{response}')
#     f.write('exit')

if "images" in response:
  base64_encoded_image = response['images'][0]
else:
  base64_encoded_image = response['image']

image = Image.open(io.BytesIO(base64.b64decode(base64_encoded_image)))

image.save(f'/Users/the_dusky/Downloads/{file_name}')
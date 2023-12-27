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

args = parser.parse_args()
# def load_input_image(path):
#     with open(path, 'rb') as file:
#         return base64.b64encode(file.read()).decode()
    
endpoint = runpod.Endpoint("ohiqabd970tfi5")


def get_as_base64(url):

    base64_bytes = base64.b64encode(requests.get(url).content)


    return base64_bytes.decode('utf-8')


#type = "txt2img"
#type = "img2img"
type = "extra-single-image"

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
}

if(type == "txt2img"):
  payload = payload_gen_txt
  file_name = "text2img_output.png"
elif (type == "img2img"):
  payload = payload_gen_img
  file_name = "img2img_output.png"
else:
  payload = payload_upscale
  file_name = "upscale_output.png"

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



#   {
#    "override_settings":{
#       "sd_model_checkpoint":"sd_xl_base_1.0.safetensors [31e35c80fc]",
#       "enable_pnginfo":true
#    },
#    "prompt":"{{art_type}}. Perspective from above, godlike, tilt shift, the city is a toy. Looking down through clouds. Blimps fly below. A (broken down) ((crumbling)) empty high-rise city like New York. {{season}}. {{time_of_day}}. {{sky_color}}. A massive {{event}} in the foreground on a section of the seawall that towers over everything. Water pours into the city beginning the flood that will be its certain demise.",
#    "negative_prompt":"((photo)), ((photograph)), trees, nature, text, lines of text, frame, frames, border, title, words, print, ",
#    "sampler_name":"DPM++ 2M",
#    "steps":20,
#    "cfg_scale":7,
#    "width":1024,
#    "height":1024,
#    "img2img_enabled":true,
#    "img2img_source":"fixed",
#    "denoising_strength":0.75,
#    "image":"https://cdn.emprops.ai/flat-files/994aa763-d9bb-42e4-b08e-553a27d67326/9e3ae556-27a7-4245-b452-8bf543238b19.png"
# }
# ///
# {
# "enabled": true,
# "upscaling_resize": 2,
# "upscaler_1": "ESRGAN_4x",
# "upscaler_2": "Nearest",
# "extras_upscaler_2_visibility": 0,
# "gfpgan_visibility": 0,
# "codeformer_visibility": 0,
# "codeformer_weight": 0
# }
# ///
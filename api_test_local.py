import json
import requests
import io
import base64
import argparse
from PIL import Image
from decouple import config

parser = argparse.ArgumentParser()

parser.add_argument("-p", "--port", help="Instance Port", default="3100")
parser.add_argument("--cfg-scale", help="CFG Scale (0 - Unlimited, 7.5 standard)", default="7")
parser.add_argument("--height", help="Height in Pixels", default="1024")
parser.add_argument("--width", help="Width in Pixels", default="1024")
parser.add_argument("--prompt", help="Prompt", default="loose impressionistic textured brushwork painting in the style of (Artemisia Gentileschi: 1.6), curvy natural medium skin tone dramatic and visceral (nude:1.5) expressing intense exagerrated screaming (Absolute Disgust:1.6), dramatic contorted twisted dancer nude powerful feminine body with tattooes holding a (butcher knife:1.5), colorful hair, draped in leather and neon color patterned renaissance fabric, wearing pearl jewelry, iridescent pastel neon colors, holding butcher knife, holding blade, holding sword, loose brushwork, vibrant color, light and shadow play, emotional, dynamic, distortion for emotional effect, vibrant, use of vibrant psychedelic colors, ")
parser.add_argument("--negative-prompt", help="Negative Prompt", default="(photorealism:1.6), (photography: 1.6), signature, comic art, (vector art:1.6), (eyes closed:1.5), cross eyed, frame, border, black border, words, children, out of frame, lowres, text, error, cropped, worst quality, low quality, jpeg artifacts, duplicate, out of frame, extra fingers, mutated hands, poorly drawn hands, blurry, extra limbs, cloned face, malformed limbs, deformed lips, missing arms, missing legs, extra arms, extra legs, fused fingers, too many fingers, missing fingers, username, watermark, signature, (airbrush:1.5), smooth skin, anime, photorealistic, 35mm film, glitch, noisy, symmetry, quiet, calm, photo, glare, photo glare, linework, stencil, flash, film, pop art, stained glass, minimalism, fashion magazine, glossy, (porn:0.5),  (pop art: 1.6), cgi, 3d modeling, cinema 4d, blender, street art, logo, graphic design")
parser.add_argument("--steps", help="Steps (0 - 50)", default="20")
parser.add_argument("--seed", help="Stable Diffusion Seed (-1 = Random)", default="42597708")
parser.add_argument("--sampler-name", help="Sampler Name", default="DPM++ 2M")
parser.add_argument("--random-noise-method", help="GPU or CPU", default="GPU")
parser.add_argument("--denoising-strength", help="Denoising Strength (0 - 1)", default="0.75")
parser.add_argument("--image", help="Image URL", default="https://cdn.emprops.ai/flat-files/e26b8192-11a4-46d1-8bf1-c5058eadfb2a/6207de10-8dae-4aec-b8d3-f458b03db38b.png")
parser.add_argument("--inference_type", help="Inference Type (txt2img, img2img, upscale)", default="upscale")

args = parser.parse_args()
# def load_input_image(path):
#     with open(path, 'rb') as file:
#         return base64.b64encode(file.read()).decode()
    
endpoint = "https://sd-edge.emprops.ai"



def get_image_as_base64(url): ## CAN THIS BE A LOCAL FILE SYSTEM ADDRESS

  base64_bytes = base64.b64encode(requests.get(url).content)

  return base64_bytes.decode('utf-8')



if(args.inference_type == 'upscale_standard'):
  type = "upscale"
else:
  type = args.inference_type

payload_upscale_standard = {
  "enabled": "true",
  "upscaling_resize": 2,
  "upscaler_1": "ESRGAN_4x",
  "upscaler_2": "Nearest",
  "extras_upscaler_2_visibility": 0,
  "gfpgan_visibility": 0,
  "codeformer_visibility": 0,
  "codeformer_weight": 0,
  "image": get_image_as_base64(args.image),
}

payload_upscale = {
    "override_settings": {
      "sd_model_checkpoint": 'sd_xl_base_1.0.safetensors [31e35c80fc]',
      #"sd_model_checkpoint": 'sd_xl_refiner_1.0.safetensors [7440042bbd]',
    },
    "script_name": "sd upscale",
    "script_args": [
      "",
      64,
      "4x-Ultrasharp",
      4
    ],
    "cfg_scale": "7",
    "height": "1024",
    "width": "1024",
    "negative_prompt": args.negative_prompt,
    "prompt": args.prompt,
    "sampler_name": "DPM++ 2S a Karras",
    "steps": "50",
    "seed": "901345806",
    "override_settings_restore_afterwards": "true",
    "denoising_strength": "0.3",
    "init_images": [
      get_image_as_base64(args.image)
    ]
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
    "batch_size": "6",
    "override_settings": {
      "randn_source": args.random_noise_method,
    },
    "override_settings_restore_afterwards": "true",
    "denoising_strength": args.denoising_strength,
    "init_images": [
      get_image_as_base64(args.image)
    ]
}

payload_gen_txt = {
    "override_settings": {
      "sd_model_checkpoint": 'sd_xl_base_1.0.safetensors [31e35c80fc]',
      "enable_pnginfo": "false"
    },
    "prompt": "A Photo Realistic award winning 8k photo of a Woman's face with freckles on a train platform in the 1920s in Paris",
    "negative_prompt": '',
    "sampler_name": 'DPM++ SDE Karras',
    "steps": 20,
    "cfg_scale": 8.01,
    "width": 1024,
    "height": 1024,
    "batch_size": "9",
    "img2img_enabled": "false",
    "img2img_source": 'p5',
    "denoising_strength": 0.99,
    "image": '',
    "image_variable": 'image_set',
    "refiner_switch_at": 0.9,
    "refiner_checkpoint": '',
    "seed": 453200137
}

if(type == "txt2img"):
  uri = "sdapi/v1/txt2img"
  payload = payload_gen_txt
  file_name = "t2iv2_output.png"
elif (type == "img2img"):
  uri = "sdapi/v1/img2img"
  payload = payload_gen_img
  file_name = "i2i_output.png"
elif (type == "upscale"):
  uri = "sdapi/v1/img2img"
  payload = payload_upscale
  file_name = "up_special_output.png"
else:
  uri = "sdapi/v1/extra-single-image"
  payload = payload_upscale_standard
  file_name = "us_upscale_output.png"

url = f'{endpoint}/{uri}'
print (payload)
print (url)
#payload["init_images"] = [get_image_as_base64(args.image)]
string = f'{config("USERNAME")}:{config("PASSWORD")}'
base64_bytes = base64.b64encode(string.encode('utf-8'))
credentials = base64_bytes.decode('utf-8')

print(credentials)
headers = {
  'content-type': 'application/json',
  'Authorization': f'Basic {credentials}',
  'x-sd-model': 'juggv8'
}

print(headers)

response = requests.post(url=f'{url}', json=payload, headers=headers)

print(response)

r = response.json()

print(r)
# with open('/Users/the_dusky/Downloads/output.txt', 'w') as f:
#     f.write(f'{response}')
#     f.write('exit')
count = 1

for image in r['images']:
  image = Image.open(io.BytesIO(base64.b64decode(image)))
  image.save(f'/Users/the_dusky/Downloads/{count}{file_name}')
  count += 1
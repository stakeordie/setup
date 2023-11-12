import json
import requests
import io
import base64
from PIL import Image

def load_input_image(path):
    with open(path, 'rb') as file:
        return base64.b64encode(file.read()).decode()

headers = {'Content-Type': 'application/json'}
url = "http://127.0.0.1:3000/sdapi/v1/txt2img"
payload = {
  "input": {
    "prompt": "Hello World"
  }
}

response = requests.post(url=f'{url}', json=payload, headers=headers)

print(response)

r = response.json()

image = Image.open(io.BytesIO(base64.b64decode(r['images'][0])))
image.save('/root/setup/proxy/test/output4.png')
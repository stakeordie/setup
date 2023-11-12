import json
import requests
import io
import base64
from PIL import Image

def load_input_image(path):
    with open(path, 'rb') as file:
        return base64.b64encode(file.read()).decode()

url = "http://0.0.0.0:8100"
payload = {
  "input": {
    "prompt": "Hello World"
  }
}

response = requests.post(url=f'{url}', json=payload)

print(response)

r = response.json()

image = Image.open(io.BytesIO(base64.b64decode(r['images'][0])))
image.save('~/Downloads/output4.png')
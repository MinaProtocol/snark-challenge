#!/usr/bin/env python3

""" Simple example script for submitting entries using json body """

import requests
import json

# Load sensitive config
with open('config.json') as config_file:
    config = json.load(config_file)
url = config['service_url']
apikey = config['api_key']

data = {
    'user_id': 'johndoe',
    'problem': 'full',
    'kind': 'github',
    'gpu': 'nvidia',
    'docker_image': 'nvidia/cuda:10.1-devel',
    'source': 'https://github.com/CodaProtocol/coda.git',
}

r = requests.post(url=url,
                  json=data,
                  headers={
                    'X-api-key': apikey
                    }
                  )

print(r.text)

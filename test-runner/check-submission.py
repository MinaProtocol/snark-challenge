#!/usr/bin/env python3

""" Simple example script for submitting entries using json body """

import requests
import json

# Load sensitive config
with open('config.json') as config_file:
    config = json.load(config_file)
url = config['service_url']
apikey = config['api_key']
testid = config['test_id']

data = {
    'CheckToken': testid,
}

r = requests.get(url=url,
                  params=data,
                  headers={
                    'X-api-key': apikey
                    }
                  )

print(r.text)

#!/usr/bin/env python3

from boto3 import resource
from boto3.dynamodb.conditions import Key, Attr
import botocore
import json
import pprint
pp = pprint.PrettyPrinter(indent=4)

# Load sensitive config
with open('config.json') as config_file:
    config = json.load(config_file)

client = resource('dynamodb', region_name=config['region_name'])
table = client.Table(config['table_name'])


def scan_jobs():
    print('Scanning: %s' % config['table_name'])
    try:
        response = table.scan(
            FilterExpression=Attr('status').contains('New'),
            ExpressionAttributeNames={  # Deals with mapping reserved words
                '#mystatus': 'status',
                '#mytimestamp': 'timestamp'},
            ProjectionExpression='id, body, #mystatus, #mytimestamp',
            Limit=100)

    except botocore.exceptions.ClientError as e:
        print(e)
        return(None)
    if 'Items' in response:
        return(response['Items'])
    else:
        return(None)


if __name__ == "__main__":
    for job in scan_jobs():
        print('-'*80)
        pp.pprint(job)
        data = json.loads(job['body'])
        for key in data:
            print("%s - %s" % (key, data[key]))

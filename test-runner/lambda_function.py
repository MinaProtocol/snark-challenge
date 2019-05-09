from boto3 import resource
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError
import json
import uuid

# Load sensitive config
with open('config.json') as config_file:
    config = json.load(config_file)

client = resource('dynamodb', region_name=config['region_name'])
table = client.Table(config['table_name'])


def respond(message=None, err=False):
    return {
        'statusCode': '400' if err else '200',
        'body': message if err else "%s\n" % json.dumps(message, indent=2),
        'headers': {
            'Content-Type': 'application/json',
        },
    }


def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))

    # Add keys
    event['id'] = uuid.uuid4().hex
    event['timestamp'] = str(event['requestContext']['requestTimeEpoch'])
    event['status'] = 'New'

    operation = event['httpMethod']

    if operation == 'GET':
        payload = event['queryStringParameters'] if operation == 'GET' else json.loads(event['body'])
        print(payload)

        if 'CheckToken' in payload:
            try:
                response = table.get_item(Key={'id': payload['CheckToken']})
            except ClientError as e:
                print(e.response['Error']['Message'])
                status = 'Unknown'
            else:
                if 'Item' in response:
                    status = response['Item']['status']
                else:
                    status = 'Unknown'
            myresponse = {
                'id': payload['CheckToken'],
                'status': status,
            }

        elif 'JobList' in payload:
            try:
                response = table.scan(
                    FilterExpression=Attr('status').contains('New'),
                    ExpressionAttributeNames={  # Deals with mapping reserved words
                        '#mystatus': 'status',
                        '#mytimestamp': 'timestamp'},
                    ProjectionExpression='id, body, #mystatus, #mytimestamp',
                    Limit=100)

            except ClientError as e:
                print(e)
                myresponse = 'Error'

            if 'Items' in response:
                myresponse = response['Items']
            else:
                myresponse = None

        return respond(message=myresponse)

    elif operation == 'POST':
        # strip out unwanted fields
        unwanted_keys = [
            'httpMethod',
            'isBase64Encoded',
            'multiValueHeaders',
            'multiValueQueryStringParameters',
            'path',
            'pathParameters',
            'resource',
            'stageVariables',
            ]

        for key in unwanted_keys:
            del event[key]

        print('Saving submission')
        table.put_item(Item=event)
        response = {
            'Status': 'Submission succeeded',
            'Token': event['id']
        }
        print(response)
        return respond(message=response)
    else:
        return respond(message='Unsupported method %s' % (operation), err=True)

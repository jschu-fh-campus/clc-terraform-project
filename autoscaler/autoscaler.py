import os
import sys
import signal
import exoscale

from flask import Flask, request
app = Flask(__name__)

def signalHandler(signum, frame):
    sys.exit(0)

signal.signal(signal.SIGINT, signalHandler)
signal.signal(signal.SIGTERM, signalHandler)

apiKey = os.getenv('EXOSCALE_KEY')
apiSecret = os.getenv('EXOSCALE_SECRET')
zone = os.getenv('EXOSCALE_ZONE')
poolId = os.getenv('EXOSCALE_INSTANCEPOOL_ID')
listenPort = os.getenv('LISTEN_PORT')

exo = exoscale.Exoscale(api_key=apiKey, api_secret=apiSecret) 
exoZone = exo.compute.get_zone(zone)

def scaleInstances(additionalInstances):
    instancePool = exo.compute.get_instance_pool(id=poolId, zone=exoZone)
    if instancePool.size + additionalInstances > 0:
        instancePool.scale(instancePool.size + additionalInstances)

@app.route('/up', methods = ['POST', 'GET'])
def up():
    scaleInstances(1)
    return 'OK', 200

@app.route('/down', methods = ['POST', 'GET'])
def down():
    scaleInstances(-1)
    return 'OK', 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(listenPort))
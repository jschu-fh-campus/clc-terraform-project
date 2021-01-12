import os
import sys
import time
import signal
import exoscale

import SocketServer
from BaseHTTPServer import BaseHTTPRequestHandler

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
    if((instancePool.size + additionalInstances) > 0)
        instancePool.scale(ip.size + additionalInstances)

class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/up':
            scaleInstances(1)
        if self.path == '/down':
            scaleInstances(-1)

        self.send_response(200)

httpd = SocketServer.TCPServer(("", int(listenPort)), RequestHandler)
httpd.serve_forever()

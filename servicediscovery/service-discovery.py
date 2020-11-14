import os
import json
import time
import exoscale

def mapRunningInstancesToJSON(runningInstances, targetPort):
    data = []
    targets = []

    for instance in runningInstances:
        targets.append("{ip}:{port}".format(ip=instance.ipv4_address, port=targetPort))
    
    data.append({
        'targets': targets,
        'labels': {}
    })
    return data

def printJSONObjectToFile(directory, filename, jsonData):
    if not os.path.isdir(directory):
        os.mkdir(directory)

    filepath = os.path.join(directory, filename)

    with open(filepath, 'w') as outfile:
        json.dump(jsonData, outfile, indent=4)

def getRunningInstances(exo, exoZone, poolId):
    try:
        instancePool = exo.compute.get_instance_pool(id=poolId, zone=exoZone)
        return instancePool.instances
    except:
        return list()

apiKey = os.getenv('EXOSCALE_KEY')
apiSecret = os.getenv('EXOSCALE_SECRET')
zone = os.getenv('EXOSCALE_ZONE')
poolId = os.getenv('EXOSCALE_INSTANCEPOOL_ID')
targetPort = os.getenv('TARGET_PORT')

directory = '/srv/service-discovery'
filename = 'config.json'
pollingInterval = 15

try:
    exo = exoscale.Exoscale(api_key=apiKey, api_secret=apiSecret) 
    exoZone = exo.compute.get_zone(zone)
except:
    exit(0)

while True:
    runningInstances = getRunningInstances(exo, exoZone, poolId)
    jsonData = mapRunningInstancesToJSON(runningInstances, targetPort)
    printJSONObjectToFile(directory, filename, jsonData)
    time.sleep(pollingInterval)

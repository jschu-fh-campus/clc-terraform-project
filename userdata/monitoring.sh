#!/bin/bash

# Script to install docker and run prometheus, the service discovery and grafana

# Exit immediatelly on failure
set -e

# Run in non-interactive mode -> apt will use default values and not ask questions
export DEBIAN_FRONTEND=noninteractive

# Install Docker (https://docs.docker.com/engine/install/ubuntu/)
# -y -> answer yes to everything
apt-get update
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

apt-key fingerprint 0EBFCD88
add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# create docker network
docker network create monitoring

# create prometheus.yml on instance
echo """
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'runningInstances'
    file_sd_configs:
      - files:
          - ${config_directory}/config.json
        refresh_interval: 10s
""" >> /srv/prometheus.yml

# Run prometheus
docker run \
  -d \
  -p 9090:9090 \
  -v ${config_directory}:${config_directory} \
  -v /srv/prometheus.yml:/etc/prometheus/prometheus.yml \
  --name prometheus \
  --net=monitoring \
  --restart=always \
  prom/prometheus

# Run the service discovery 
docker run \
  -d \
  -e EXOSCALE_KEY=${exoscale_key} \
  -e EXOSCALE_SECRET=${exoscale_secret} \
  -e EXOSCALE_ZONE=${exoscale_zone} \
  -e EXOSCALE_INSTANCEPOOL_ID=${exoscale_instancepool_id} \
  -e TARGET_PORT=${target_port} \
  -v ${config_directory}:${config_directory} \
  --name service-discovery \
  --net=monitoring \
  --restart=always \
  jschu/exoscale_service_discovery

# create datasource for grafana on instance
echo """
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  access: proxy
  orgId: 1
  url: http://prometheus:9090
  version: 1
  editable: false
""" >> /srv/datasource.yml

# create scale-up notifier for grafana on instance
echo """
notifiers:
  - name: Scale up
    type: webhook
    uid: scale-up
    org_id: 1
    is_default: false
    send_reminder: true
    disable_resolve_message: true
    frequency: '5m'
    settings:
      autoResolve: true
      httpMethod: 'POST'
      severity: 'critical'
      uploadImage: false
      url: 'http://autoscaler:8090/up'
""" >> /srv/scale-up.yml

# create scale-down notifier for grafana on instance
echo """
notifiers:
  - name: Scale down
    type: webhook
    uid: scale-down
    org_id: 1
    is_default: false
    send_reminder: true
    disable_resolve_message: true
    frequency: '5m'
    settings:
      autoResolve: true
      httpMethod: 'POST'
      severity: 'critical'
      uploadImage: false
      url: 'http://autoscaler:8090/down'
""" >> /srv/scale-down.yml

# create dashboard configuration for grafana on instance
echo """
apiVersion: 1
providers:
- name: 'Home'
  orgId: 1
  folder: ''
  type: file
  updateIntervalSeconds: 10
  options:
    path: /etc/grafana/dashboards
""" >> /srv/dashboard.yml

# create dashboard for grafana on instance
echo """
{
  \"annotations\": {
    \"list\": [
      {
        \"builtIn\": 1,
        \"datasource\": \"-- Grafana --\",
        \"enable\": true,
        \"hide\": true,
        \"iconColor\": \"rgba(0, 211, 255, 1)\",
        \"name\": \"Annotations & Alerts\",
        \"type\": \"dashboard\"
      }
    ]
  },
  \"editable\": true,
  \"gnetId\": null,
  \"graphTooltip\": 0,
  \"links\": [],
  \"panels\": [
    {
      \"alert\": {
        \"alertRuleTags\": {},
        \"conditions\": [
          {
            \"evaluator\": {
              \"params\": [
                0.2
              ],
              \"type\": \"lt\"
            },
            \"operator\": {
              \"type\": \"and\"
            },
            \"query\": {
              \"params\": [
                \"A\",
                \"1m\",
                \"now\"
              ]
            },
            \"reducer\": {
              \"params\": [],
              \"type\": \"avg\"
            },
            \"type\": \"query\"
          }
        ],
        \"executionErrorState\": \"alerting\",
        \"for\": \"1m\",
        \"frequency\": \"1m\",
        \"handler\": 1,
        \"name\": \"Scale down\",
        \"noDataState\": \"no_data\",
        \"notifications\": [
          {
            \"uid\": \"scale-down\"
          }
        ]
      },
      \"aliasColors\": {},
      \"bars\": false,
      \"dashLength\": 10,
      \"dashes\": false,
      \"datasource\": \"Prometheus\",
      \"fieldConfig\": {
        \"defaults\": {
          \"custom\": {}
        },
        \"overrides\": []
      },
      \"fill\": 1,
      \"fillGradient\": 0,
      \"gridPos\": {
        \"h\": 8,
        \"w\": 12,
        \"x\": 0,
        \"y\": 0
      },
      \"hiddenSeries\": false,
      \"id\": 4,
      \"legend\": {
        \"avg\": false,
        \"current\": false,
        \"max\": false,
        \"min\": false,
        \"show\": true,
        \"total\": false,
        \"values\": false
      },
      \"lines\": true,
      \"linewidth\": 1,
      \"nullPointMode\": \"null\",
      \"options\": {
        \"alertThreshold\": true
      },
      \"percentage\": false,
      \"pluginVersion\": \"7.3.6\",
      \"pointradius\": 2,
      \"points\": false,
      \"renderer\": \"flot\",
      \"seriesOverrides\": [],
      \"spaceLength\": 10,
      \"stack\": false,
      \"steppedLine\": false,
      \"targets\": [
        {
          \"expr\": \"avg(sum by (instance) (rate(node_cpu_seconds_total{mode!=\\\"idle\\\"}[1m])) / sum by (instance) (rate(node_cpu_seconds_total[1m])))\",
          \"interval\": \"\",
          \"legendFormat\": \"\",
          \"queryType\": \"randomWalk\",
          \"refId\": \"A\"
        }
      ],
      \"thresholds\": [
        {
          \"colorMode\": \"critical\",
          \"fill\": true,
          \"line\": true,
          \"op\": \"lt\",
          \"value\": 0.2
        }
      ],
      \"timeFrom\": null,
      \"timeRegions\": [],
      \"timeShift\": null,
      \"title\": \"Scale down\",
      \"tooltip\": {
        \"shared\": true,
        \"sort\": 0,
        \"value_type\": \"individual\"
      },
      \"type\": \"graph\",
      \"xaxis\": {
        \"buckets\": null,
        \"mode\": \"time\",
        \"name\": null,
        \"show\": true,
        \"values\": []
      },
      \"yaxes\": [
        {
          \"format\": \"short\",
          \"label\": null,
          \"logBase\": 1,
          \"max\": null,
          \"min\": null,
          \"show\": true
        },
        {
          \"format\": \"short\",
          \"label\": null,
          \"logBase\": 1,
          \"max\": null,
          \"min\": null,
          \"show\": true
        }
      ],
      \"yaxis\": {
        \"align\": false,
        \"alignLevel\": null
      }
    },
    {
      \"alert\": {
        \"alertRuleTags\": {},
        \"conditions\": [
          {
            \"evaluator\": {
              \"params\": [
                0.8
              ],
              \"type\": \"gt\"
            },
            \"operator\": {
              \"type\": \"and\"
            },
            \"query\": {
              \"params\": [
                \"A\",
                \"1m\",
                \"now\"
              ]
            },
            \"reducer\": {
              \"params\": [],
              \"type\": \"avg\"
            },
            \"type\": \"query\"
          }
        ],
        \"executionErrorState\": \"alerting\",
        \"for\": \"1m\",
        \"frequency\": \"1m\",
        \"handler\": 1,
        \"name\": \"Scale up\",
        \"noDataState\": \"no_data\",
        \"notifications\": [
          {
            \"uid\": \"scale-up\"
          }
        ]
      },
      \"aliasColors\": {},
      \"bars\": false,
      \"dashLength\": 10,
      \"dashes\": false,
      \"datasource\": \"Prometheus\",
      \"fieldConfig\": {
        \"defaults\": {
          \"custom\": {}
        },
        \"overrides\": []
      },
      \"fill\": 1,
      \"fillGradient\": 0,
      \"gridPos\": {
        \"h\": 9,
        \"w\": 12,
        \"x\": 0,
        \"y\": 8
      },
      \"hiddenSeries\": false,
      \"id\": 2,
      \"legend\": {
        \"avg\": false,
        \"current\": false,
        \"max\": false,
        \"min\": false,
        \"show\": true,
        \"total\": false,
        \"values\": false
      },
      \"lines\": true,
      \"linewidth\": 1,
      \"nullPointMode\": \"null\",
      \"options\": {
        \"alertThreshold\": true
      },
      \"percentage\": false,
      \"pluginVersion\": \"7.3.6\",
      \"pointradius\": 2,
      \"points\": false,
      \"renderer\": \"flot\",
      \"seriesOverrides\": [],
      \"spaceLength\": 10,
      \"stack\": false,
      \"steppedLine\": false,
      \"targets\": [
        {
          \"expr\": \"avg(sum by (instance) (rate(node_cpu_seconds_total{mode!=\\\"idle\\\"}[1m])) / sum by (instance) (rate(node_cpu_seconds_total[1m])))\",
          \"interval\": \"\",
          \"legendFormat\": \"\",
          \"queryType\": \"randomWalk\",
          \"refId\": \"A\"
        }
      ],
      \"thresholds\": [
        {
          \"colorMode\": \"critical\",
          \"fill\": true,
          \"line\": true,
          \"op\": \"gt\",
          \"value\": 0.8
        }
      ],
      \"timeFrom\": null,
      \"timeRegions\": [],
      \"timeShift\": null,
      \"title\": \"Scale up\",
      \"tooltip\": {
        \"shared\": true,
        \"sort\": 0,
        \"value_type\": \"individual\"
      },
      \"type\": \"graph\",
      \"xaxis\": {
        \"buckets\": null,
        \"mode\": \"time\",
        \"name\": null,
        \"show\": true,
        \"values\": []
      },
      \"yaxes\": [
        {
          \"format\": \"short\",
          \"label\": null,
          \"logBase\": 1,
          \"max\": null,
          \"min\": null,
          \"show\": true
        },
        {
          \"format\": \"short\",
          \"label\": null,
          \"logBase\": 1,
          \"max\": null,
          \"min\": null,
          \"show\": true
        }
      ],
      \"yaxis\": {
        \"align\": false,
        \"alignLevel\": null
      }
    }
  ],
  \"schemaVersion\": 26,
  \"style\": \"dark\",
  \"tags\": [],
  \"templating\": {
    \"list\": []
  },
  \"time\": {
    \"from\": \"now-15m\",
    \"to\": \"now\"
  },
  \"timepicker\": {},
  \"timezone\": \"\",
  \"title\": \"CPU usage\",
  \"uid\": \"2urSUP-Gk\",
  \"version\": 1
}
""" >> /srv/dashboard.json

#Run Autoscaler
docker run \
  -d \
  -p ${listen_port}:${listen_port} \
  --name autoscaler \
  --net=monitoring \
  --restart=always \
  quay.io/janoszen/exoscale-grafana-autoscaler \
  --exoscale-api-key ${exoscale_key} \
  --exoscale-api-secret ${exoscale_secret} \
  --exoscale-zone-id 4da1b188-dcd6-4ff5-b7fd-bde984055548 \
  --instance-pool-id ${exoscale_instancepool_id}

#Run Grafana
docker run \
  -d \
  -p 3000:3000 \
  -v /srv/datasource.yml:/etc/grafana/provisioning/datasources/datasource.yml \
  -v /srv/scale-up.yml:/etc/grafana/provisioning/notifiers/scale-up.yml \
  -v /srv/scale-down.yml:/etc/grafana/provisioning/notifiers/scale-down.yml \
  -v /srv/dashboard.yml:/etc/grafana/provisioning/dashboards/dashboard.yml \
  -v /srv/dashboard.json:/etc/grafana/dashboards/dashboard.json \
  --name grafana \
  --net=monitoring \
  --restart=always \
  grafana/grafana

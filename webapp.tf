variable "zone" {
  default = "at-vie-1"
}

data "exoscale_compute_template" "ubuntu" {
  zone = var.zone
  name = "Linux Ubuntu 20.04 LTS 64-bit"
}

resource "exoscale_instance_pool" "webapp" {
  name = "webapp"
  description = "This is the production environment for my webapp"
  zone = var.zone
  template_id = data.exoscale_compute_template.ubuntu.id
  size = 3
  service_offering = "micro"
  disk_size = 50
  
  user_data = file("script.sh")
  key_pair = ""

  security_group_ids = [exoscale_security_group.sg.id]

  timeouts {
    delete = "10m"
  }
}

resource "exoscale_nlb" "webapp" {
  name = "webapp"
  description = "This is the Network Load Balancer for my webapp"
  zone = var.zone
}

resource "exoscale_nlb_service" "webapp" {
  zone = exoscale_nlb.webapp.zone
  name = "webapp"
  description = "Webapp over HTTP"
  nlb_id = exoscale_nlb.webapp.id
  instance_pool_id = exoscale_instance_pool.webapp.id
    protocol = "tcp"
    port = 80
    target_port = 80
    strategy = "round-robin"

  healthcheck {
    port = 80
    mode = "http"
    uri = "/"
    interval = 5
    timeout = 3
    retries = 1
  }
}

// muss laufen mit only api key (exoscale key / secret?)
// firewall ssh and restrict to own ip
// modules
// load generator
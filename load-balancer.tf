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
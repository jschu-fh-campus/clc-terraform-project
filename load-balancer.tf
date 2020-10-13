resource "exoscale_nlb" "webapp" {
  name = "webapp"
  description = "This is the Network Load Balancer for my webapp"
  zone = var.zone
}

resource "exoscale_nlb_service" "webapp" {
  name = "webapp"
  description = "Webapp over HTTP"
  zone = exoscale_nlb.webapp.zone
  nlb_id = exoscale_nlb.webapp.id
  instance_pool_id = exoscale_instance_pool.webapp.id
    protocol = "tcp"
    port = 80
    target_port = 8080
    strategy = "round-robin"

  healthcheck {
    port = 8080
    mode = "http"
    uri = "/health"
    interval = 5
    timeout = 3
    retries = 1
  }
}
resource "exoscale_nlb" "load_balancer" {
  name = "load_balancer"
  description = "This is the Network Load Balancer for my webapp"
  zone = var.zone
}

resource "exoscale_nlb_service" "load_balancer_service" {
  name = "load_balancer_service"
  description = "Webapp over HTTP"
  zone = exoscale_nlb.load_balancer.zone
  nlb_id = exoscale_nlb.load_balancer.id
  instance_pool_id = exoscale_instance_pool.instance_pool.id
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
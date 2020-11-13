resource "exoscale_compute" "prometheus" {
  zone = var.zone
  display_name = "prometheus"
  template_id  = data.exoscale_compute_template.ubuntu.id
  size         = "micro"
  disk_size    = 50
  key_pair     = exoscale_ssh_keypair.johannes.name
  state        = "Running"
  security_group_ids = [exoscale_security_group.prometheus.id]

  user_data = templatefile("userdata/prometheus.sh", {
        exoscale_key = var.exoscale_key,
        exoscale_secret = var.exoscale_secret,
        exoscale_zone = var.zone,
        exoscale_instancepool_id = exoscale_instance_pool.instance_pool.id
        target_port = "9100",
        targetFilePath = "/srv/service-discovery"
    })
}
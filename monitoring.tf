resource "exoscale_compute" "monitoring" {
  zone = var.zone
  display_name = "monitoring"
  template_id  = data.exoscale_compute_template.ubuntu.id
  size         = "micro"
  disk_size    = 50
  key_pair     = exoscale_ssh_keypair.johannes.name
  state        = "Running"
  security_group_ids = [exoscale_security_group.monitoring.id]

  user_data = templatefile("userdata/monitoring.sh", {
        exoscale_key = var.exoscale_key,
        exoscale_secret = var.exoscale_secret,
        exoscale_zone = var.zone,
        exoscale_instancepool_id = exoscale_instance_pool.instance_pool.id,
        target_port = "9100",
        config_directory = "/srv/service-discovery"
    })
}
resource "exoscale_instance_pool" "instance_pool" {
  name = "instance_pool"
  description = "This is the instance pool for my webapp"
  zone = var.zone
  template_id = data.exoscale_compute_template.ubuntu.id
  size = 3
  service_offering = "micro"
  disk_size = 50
  user_data = file("userdata/load-generator.sh")
  key_pair = exoscale_ssh_keypair.johannes.name
  security_group_ids = [exoscale_security_group.instance_pool.id]
}
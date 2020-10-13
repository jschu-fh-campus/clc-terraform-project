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
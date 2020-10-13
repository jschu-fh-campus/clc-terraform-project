resource "exoscale_security_group" "webapp" {
  name = "webapp"
  description = "This is the security group for my webapp"
}

resource "exoscale_security_group_rule" "http" {
  security_group_id = exoscale_security_group.webapp.id
  type = "INGRESS"
  protocol = "tcp"
  cidr = "0.0.0.0/0"
  start_port = 8080
  end_port = 8080
}

resource "exoscale_security_group_rule" "ssh" {
  security_group_id = exoscale_security_group.webapp.id
  type = "INGRESS"
  protocol = "tcp"
  cidr = "0.0.0.0/0"
  start_port = 22
  end_port = 22
}
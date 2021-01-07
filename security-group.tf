# Instance Pool

resource "exoscale_security_group" "instance_pool" {
  name = "instance_pool"
  description = "This is the security group for the instance pool"
}

resource "exoscale_security_group_rule" "instance_pool_http" {
  security_group_id = exoscale_security_group.instance_pool.id
  type = "INGRESS"
  protocol = "TCP"
  cidr = "0.0.0.0/0"
  start_port = 8080
  end_port = 8080
}

resource "exoscale_security_group_rule" "instance_pool_ssh" {
  security_group_id = exoscale_security_group.instance_pool.id
  type = "INGRESS"
  protocol = "TCP"
  cidr = "0.0.0.0/0"
  start_port = 22
  end_port = 22
}

resource "exoscale_security_group_rule" "instance_pool_node_exporter" {
  security_group_id = exoscale_security_group.instance_pool.id
  type = "INGRESS"
  protocol = "TCP"
  cidr = "0.0.0.0/0"
  start_port = 9100
  end_port = 9100
}

# Monitoring

resource "exoscale_security_group" "monitoring" {
  name = "monitoring"
  description = "This is the security group for monitoring"
}

resource "exoscale_security_group_rule" "monitoring_ssh" {
  security_group_id = exoscale_security_group.monitoring.id
  type = "INGRESS"
  protocol = "TCP"
  cidr = "0.0.0.0/0"
  start_port = 22
  end_port = 22
}

resource "exoscale_security_group_rule" "monitoring_prometheus" {
  security_group_id = exoscale_security_group.monitoring.id
  type = "INGRESS"
  protocol = "TCP"
  cidr = "0.0.0.0/0"
  start_port = 9090
  end_port = 9090
}

resource "exoscale_security_group_rule" "monitoring_grafana" {
  security_group_id = exoscale_security_group.monitoring.id
  type = "INGRESS"
  protocol = "TCP"
  cidr = "0.0.0.0/0"
  start_port = 3000
  end_port = 3000
}

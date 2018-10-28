output "consul_instances" {
  value = "${aws_instance.consul_server_instance.*.id}"
}

output "security_group" {
  value = "${aws_security_group.consul_server_ingress.id}"
}

output "consul_cluster_name" {
  value = "${format("%s-%s-%s", var.resource_name_prefix, "instance", random_id.entropy.hex)}"
}

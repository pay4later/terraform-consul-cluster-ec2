terraform {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_vpc" "current" {
  tags {
    Name = "${var.vpc_name}"

    # Optional tag to filter
    #BillingTeamName = "DevOps"

    # Optional tag to filter
    #Owner = "DevOps"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "template_file" "user_data" {
  template = "${file("${path.module}/templates/default-user-data.sh.tpl")}"

  vars {
    aws_region          = "${data.aws_region.current.name}"
    consul_cluster_name = "${format("%s-%s-%s", var.resource_name_prefix, "instance", random_id.entropy.hex)}"
    consul_server_nodes = "${var.consul_server_nodes}"
    consul_version      = "${var.consul_version}"
  }
}

resource "random_shuffle" "azs" {
  input        = ["${data.aws_availability_zones.available.names}"]
  result_count = "${var.consul_server_nodes}"
}

resource "random_id" "entropy" {
  byte_length = 4
}

data "aws_subnet" "private" {
  count             = "${var.consul_server_nodes}"
  vpc_id            = "${data.aws_vpc.current.id}"
  availability_zone = "${element(random_shuffle.azs.result, count.index)}"

  tags {
    Tier = "Private"
  }
}

# Define security groups
# Gitlab SG for the NLB facing the world
resource "aws_security_group" "consul_server_ingress" {
  name        = "${var.resource_name_prefix}-ingress-${random_id.entropy.hex}"
  description = "Allow traffic to Consul instances"
  vpc_id      = "${data.aws_vpc.current.id}"

  # TCP 8300 (Server RPC)
  ingress {
    description = "TCP 8300 (Server RPC)"
    from_port   = 8300
    to_port     = 8300
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.current.cidr_block}"]
  }

  # TCP 8301 (Serf LAN)
  ingress {
    description = "TCP 8301 (Serf LAN)"
    from_port   = 8301
    to_port     = 8301
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.current.cidr_block}"]
  }

  # UDP 8301 (Serf LAN)
  ingress {
    description = "UDP 8301 (Serf LAN)"
    from_port   = 8301
    to_port     = 8301
    protocol    = "udp"
    cidr_blocks = ["${data.aws_vpc.current.cidr_block}"]
  }

  # TCP 8302 (Serf WAN)
  ingress {
    description = "TCP 8302 (Serf WAN)"
    from_port   = 8302
    to_port     = 8302
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.current.cidr_block}"]
  }

  # UDP 8302 (Serf WAN)
  ingress {
    description = "UDP 8302 (Serf WAN)"
    from_port   = 8302
    to_port     = 8302
    protocol    = "udp"
    cidr_blocks = ["${data.aws_vpc.current.cidr_block}"]
  }

  # TCP 8400 (CLI RPC)
  ingress {
    description = "TCP 8400 (CLI RPC)"
    from_port   = 8400
    to_port     = 8400
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.current.cidr_block}"]
  }

  # TCP 8500 (HTTP API)
  ingress {
    description = "TCP 8500 (HTTP API)"
    from_port   = 8500
    to_port     = 8500
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.current.cidr_block}"]
  }

  # TCP 8600 (DNS)
  ingress {
    description = "TCP 8600 (DNS)"
    from_port   = 8600
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.current.cidr_block}"]
  }

  # UDP 8600 (DNS)
  ingress {
    description = "UDP 8600 (DNS)"
    from_port   = 8600
    to_port     = 8600
    protocol    = "udp"
    cidr_blocks = ["${data.aws_vpc.current.cidr_block}"]
  }

  # SSH access
  ingress {
    description = "Allow SSH access from Internet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.current.cidr_block}"]
  }

  # ICMP
  ingress {
    description = "Allow ICMP from VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["${data.aws_vpc.current.cidr_block}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
            merge(
              map("Name", format("%s-%s", var.resource_name_prefix, "sg-${random_id.entropy.hex}")),
              var.tags,
            )
          }"
}

/*
 * Create EC2 IAM Instance Role and Policy
 */
resource "aws_iam_role" "ec2InstanceRole" {
  name               = "ec2InstanceRole-${random_id.entropy.hex}"
  assume_role_policy = "${var.ec2_assume_role}"
  path               = "/consul/servers/"
}

resource "aws_iam_role_policy" "ec2InstanceRolePolicy" {
  name   = "ec2InstanceRolePolicy-${random_id.entropy.hex}"
  role   = "${aws_iam_role.ec2InstanceRole.id}"
  policy = "${var.ec2_consul_policy}"
}

resource "aws_iam_instance_profile" "ec2InstanceProfile" {
  name = "ec2InstanceProfile-${random_id.entropy.hex}"
  role = "${aws_iam_role.ec2InstanceRole.name}"
  path = "/consul/servers/"
}

resource "null_resource" "waiter" {
  depends_on = ["aws_iam_instance_profile.ec2InstanceProfile"]

  provisioner "local-exec" {
    command = "sleep 15"
  }
}

resource "aws_instance" "consul_server_instance" {
  count         = "${var.consul_server_nodes}"
  ami           = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  key_name      = "${var.aws_key_name}"
  user_data     = "${data.template_file.user_data.rendered}"

  vpc_security_group_ids = [
    "${aws_security_group.consul_server_ingress.id}",
  ]

  associate_public_ip_address = false
  availability_zone           = "${element(random_shuffle.azs.result, count.index)}"
  subnet_id                   = "${element(data.aws_subnet.private.*.id, count.index)}"
  iam_instance_profile        = "${aws_iam_instance_profile.ec2InstanceProfile.name}"

  tags = "${
            merge(
              map("Name", format("%s-%s-%s-%02d", var.resource_name_prefix, "instance", random_id.entropy.hex, count.index + 1)),
              map("consul:clusters:nodes", format("%s-%s-%s", var.resource_name_prefix, "instance", random_id.entropy.hex)),
              var.tags,
            )
          }"
}

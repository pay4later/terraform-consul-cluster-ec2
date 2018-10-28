variable "vpc_name" {
  default     = "MDOBREV-VPC"
  description = "The name of the VPC ommiting the -vpc suffix"
}

variable "consul_server_nodes" {
  default     = "5"
  description = "Amount of Consul server nodes to bring up. Minimum amount is 3, recommended is 5"
}

variable "consul_version" {
  default     = "1.3.0"
  description = "Version of Consul to install. Use semver, for example 0.8.4"
}

variable "instance_type" {
  default     = "t2.micro"
  description = "Type of the instance to use for the Consul cluster nodes. See https://aws.amazon.com/ec2/instance-types/"
}

variable "aws_key_name" {
  description = "SSH keypair name for the VPN instance"
}

variable "tags" {
  description = "A map of tags to add to all resources"

  default = {
    BillingTeamName = "DevOps"
    Owner           = "DevOps"
    Project         = "Consul"
  }
}

variable "resource_name_prefix" {
  description = "All the resources will be prefixed with the value of this variable"
  default     = "consul"
}

/*
 * Change if you know what you do
 */

variable "ec2_consul_policy" {
  type = "string"

  default = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {
     "Sid": "",
     "Effect": "Allow",
     "Action": "ec2:DescribeInstances",
     "Resource": "*"
     }
 ]
}
EOF
}

variable "ec2_assume_role" {
  type = "string"

  default = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "",
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
}
EOF
}

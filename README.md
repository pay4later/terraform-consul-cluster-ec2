# Overview

This Terraform module creates a Consul cluster in AWS using ECS instances and cloud auto-discovery


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| aws_key_name | SSH keypair name for the VPN instance | string | - | yes |
| consul_server_nodes | Amount of Consul server nodes to bring up. Minimum amount is 3, recommended is 5 | string | `5` | no |
| consul_version | Version of Consul to install. Use semver, for example 0.8.4 | string | `1.3.0` | no |
| ec2_assume_role |  | string | `{     "Version": "2008-10-17",     "Statement": [       {         "Sid": "",         "Effect": "Allow",         "Principal": {           "Service": "ec2.amazonaws.com"         },         "Action": "sts:AssumeRole"       }     ] } ` | no |
| ec2_consul_policy |  | string | `{   "Version": "2012-10-17",   "Statement": [      {      "Sid": "",      "Effect": "Allow",      "Action": "ec2:DescribeInstances",      "Resource": "*"      }  ] } ` | no |
| instance_type | Type of the instance to use for the Consul cluster nodes. See https://aws.amazon.com/ec2/instance-types/ | string | `t2.micro` | no |
| resource_name_prefix | All the resources will be prefixed with the value of this variable | string | `consul` | no |
| tags | A map of tags to add to all resources | string | `<map>` | no |
| vpc_name | The name of the VPC ommiting the -vpc suffix | string | `MDOBREV-VPC` | no |

## Outputs

| Name | Description |
|------|-------------|
| consul_cluster_name |  |
| consul_instances |  |
| security_group |  |

<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

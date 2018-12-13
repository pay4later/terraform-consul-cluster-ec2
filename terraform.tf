terraform {
  backend "s3" {
    key            = "consul-cluster.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock"
  }
}

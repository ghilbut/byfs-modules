provider aws {
  alias   = "acm_certificate"
  region  = "us-east-1"
  profile = var.aws_profile
}


locals {
  az_suffixes = ["a", "c"]

  private_cidrs = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ]

  tags = merge(
    var.tags,
    {
      created_by = "terraform"
      "terraform:byfs:prefix" = var.unique_name
      "terraform:byfs:module" = "byfs-devleop"
    }
  )
}

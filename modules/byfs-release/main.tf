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

  django_container_name = "${var.prefix}-django"
  django_cpu            = "256"
  django_memory         = "512"
  django_port           = 8000

  alb_django_priority = 50000

  tags = merge(
    var.tags,
    {
      created_by = "terraform"
      "terraform:byfs:prefix" = var.prefix
      "terraform:byfs:module" = "byfs-release"
    }
  )
}

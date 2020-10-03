locals {
  az_suffixes = ["a", "b"]

  private_cidrs = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ]

  tags = merge(
    var.tags,
    {
      owner   = "terraform"
      service = "k3s-basecamp"
      purpose = "initial management environment"
    },
  )
}

locals {
  private_key    = file(var.public_key_path)
  helmchart_path = "/Users/ghilbut/work/workbench/ghilbut/byfs-modules/k3s-basecamp/helm"
  argo_host      = "argo.${var.domain_name}"
  revision       = "master"
}

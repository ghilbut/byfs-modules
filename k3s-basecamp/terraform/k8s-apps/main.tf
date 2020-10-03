locals {
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
  helmchart_path = "/Users/ghilbut/work/workbench/ghilbut/byfs-modules/k3s-basecamp/helm"
  argo_host      = "argo.${var.domain_name}"
  revision       = "master"
}

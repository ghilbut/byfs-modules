################################################################
##
##  AWS ECS Fargate
##

##--------------------------------------------------------------
##  AWS CloudWatch

resource aws_cloudwatch_log_group ecs {
  name              = "/aws/ecs/containerinsights/${var.cluster_name}/performance"
  retention_in_days = 1

  tags = merge(
    map(
      "Name", "/aws/ecs/containerinsights/${var.cluster_name}/performance",
    ),
    local.tags
  )
}

##--------------------------------------------------------------
##  AWS ECS Fargate

resource aws_ecs_cluster byfs {
  depends_on = [
    aws_cloudwatch_log_group.ecs,
  ]

  name               = var.cluster_name
  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT",
  ]

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = merge(
    map(
      "Name", var.cluster_name
    ),
    local.tags
  )
}
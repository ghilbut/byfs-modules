################################################################
##
##  AWS ECS Fargate
##

##--------------------------------------------------------------
##  AWS ECS Fargate

resource aws_ecs_cluster byfs {
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


################################################################
##
##  AWS IAM
##

data aws_iam_policy_document assume_role_policy {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

##--------------------------------------------------------------
##  task execution

resource aws_iam_role ecs_task_execution {
  name               = "${var.unique_name}-ecs-task-execution"
  description        = "${var.unique_name}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource aws_iam_role_policy_attachment ecs_task_execution_policy {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

##--------------------------------------------------------------
##  secret access

resource aws_iam_policy secret_access_policy {
  name        = "${var.unique_name}-secret-accss"
  description = "${var.unique_name}-secret-accss"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:ssm:ap-northeast-2:*:parameter/*",
        "arn:aws:secretsmanager:ap-northeast-2:*:secret:*"
      ]
    }
  ]
}
EOF
}

resource aws_iam_role_policy_attachment secrets {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = aws_iam_policy.secret_access_policy.arn
}
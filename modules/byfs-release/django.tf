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
  name               = "${var.prefix}-ecs-task-execution"
  description        = "${var.prefix}-ecs-task-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource aws_iam_role_policy_attachment ecs_task_execution_policy {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

##--------------------------------------------------------------
##  secret access

resource aws_iam_policy secret_access_policy {
  name        = "${var.prefix}-secret-accss"
  description = "${var.prefix}-secret-accss"

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



################################################################
##
##  AWS ECR
##

resource aws_ecr_repository django {
  name = local.django_container_name

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = merge(
    map(
      "Name", "${var.prefix}-django"
    ),
    local.tags
  )
}



################################################################
##
##  AWS CloudWatch
##

resource aws_cloudwatch_log_group django {
  name              = "${var.prefix}-django"
  retention_in_days = 1

  tags = merge(
    map(
      "Name", "${var.prefix}-django",
    ),
    local.tags
  )
}


################################################################
##
##  AWS LB
##

resource aws_lb_target_group django {
  depends_on = [
    aws_lb_listener.http,
  ]

  name        = "alb-${var.prefix}-django"
  port        = local.django_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    interval = 10
    path = "/healthz"
  }
}

resource aws_lb_listener_rule django_from_cloudfront {
  listener_arn = aws_lb_listener.http.arn
  priority     = local.alb_django_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.django.arn
  }

  condition {
    host_header {
      values = [
        aws_route53_record.cloudfront.fqdn,
      ]
    }
  }

  condition {
    path_pattern {
      values = [
        "/admin*",
        "/api*",
        "/redoc*",
        "/swagger*",
      ]
    }
  }
}



################################################################
##
##  AWS ECS
##

##--------------------------------------------------------------
##  local variables

locals {
  family         = "${var.prefix}-django"
  execution_role = aws_iam_role.ecs_task_execution.arn

  environment = [
    {
      "name": "DJANGO_SETTINGS_MODULE",
      "value": "spps.settings.prod"
    }
  ]

  secrets = [
    {
      "name": "${upper(var.prefix)}_DB_HOST",
      "valueFrom": var.mysql_host.arn
    },
    {
      "name": "${upper(var.prefix)}_DB_PORT",
      "valueFrom": var.mysql_port.arn
    },
    {
      "name": "${upper(var.prefix)}_DB_NAME",
      "valueFrom": var.mysql_database.arn
    },
    {
      "name": "${upper(var.prefix)}_DB_USER",
      "valueFrom": var.mysql_username.arn
    },
    {
      "name": "${upper(var.prefix)}_DB_PASSWORD",
      "valueFrom": var.mysql_password.arn
    }
  ]
}

##--------------------------------------------------------------
##  templates

data template_file django_containers {
  template = file("${path.module}/templates/ecs-django-container-definitions.json")

  vars = {
    name        = local.django_container_name
    image       = "${aws_ecr_repository.django.repository_url}:latest"
    port        = local.django_port
    environment = jsonencode(local.environment)
    secrets     = jsonencode(local.secrets)
    log_config  =<<EOF
{
  "logDriver": "awslogs",
  "options": {
    "awslogs-region":          "${var.aws_region}",
    "awslogs-group":           "${aws_cloudwatch_log_group.django.name}",
    "awslogs-stream-prefix":   "${var.prefix}",
    "awslogs-datetime-format": "\\[%Y-%m-%d %H:%M:%S\\]"
  }
}
EOF
  }
}

data template_file django_task {
  template = file("${path.module}/templates/ecs-django-task-definition.json")

  vars = {
    family         = local.family
    cpu            = local.django_cpu
    memory         = local.django_memory
    execution_role = local.execution_role
    containers     = data.template_file.django_containers.rendered
    tags           = jsonencode([for name, value in merge(
        map(
          "Name", "${var.prefix}-django"
        ),
        local.tags
      ): {
        key = name
        value = value
      }
    ])
  }
}

##--------------------------------------------------------------
##  Task Definition

resource aws_ecs_task_definition django {
  family                   = local.family
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = local.django_cpu
  memory                   = local.django_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  # defined in role.tf
  #task_role_arn = aws_iam_role.app_role.arn

  container_definitions    = data.template_file.django_containers.rendered

  tags = merge(
    map(
      "Name", "${var.prefix}-django"
    ),
    local.tags
  )
}

##--------------------------------------------------------------
##  Security Groups

resource aws_security_group django {
  name        = "${var.prefix}-django"
  description = "Allow all traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = local.private_cidrs
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags = merge(
    map(
      "Name", "sg-${var.prefix}-django",
    ),
    local.tags, 
  )
}

##--------------------------------------------------------------
##  ECS Service

resource aws_ecs_service django {
  depends_on = [
    aws_ecr_repository.django,
    aws_lb_target_group.django,
  ]

  lifecycle {
    ignore_changes = [
      task_definition,
    ]
  }

  name                               = "django"
  cluster                            = var.ecs_cluster.id
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100
  launch_type                        = "FARGATE"
  task_definition                    = aws_ecs_task_definition.django.arn
  desired_count                      = 1

  network_configuration {
    subnets          = [
      data.aws_subnet.default.id,
    ]
    security_groups  = [
      aws_security_group.django.id,
    ]

    # if you have NAT, set to false
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.django.id
    container_name   = local.django_container_name
    container_port   = local.django_port
  }

  deployment_controller {
    type = "ECS"
  }
}

##--------------------------------------------------------------
##  Auto Scaling

resource aws_appautoscaling_target django_scale_target {
  count = (var.django_max_capacity == var.django_min_capacity ? 0 : 1)

  service_namespace  = "ecs"
  resource_id        = "service/${var.ecs_cluster.name}/${aws_ecs_service.django.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = var.django_max_capacity
  min_capacity       = var.django_min_capacity
}

resource aws_appautoscaling_policy django_scale_out {
  count = (var.django_max_capacity == var.django_min_capacity ? 0 : 1)

  name               = "scale-out"
  resource_id        = aws_appautoscaling_target.django_scale_target.0.resource_id
  scalable_dimension = aws_appautoscaling_target.django_scale_target.0.scalable_dimension
  service_namespace  = aws_appautoscaling_target.django_scale_target.0.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource aws_cloudwatch_metric_alarm django_cpu_utilization_high {
  count = (var.django_max_capacity == var.django_min_capacity ? 0 : 1)

  alarm_name          = "${var.prefix}-django-CPU-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.django_scale_out_cpu_high

  dimensions = {
    ClusterName = var.ecs_cluster.name
    ServiceName = aws_ecs_service.django.name
  }

  alarm_actions = [
    aws_appautoscaling_policy.django_scale_out.0.arn,
  ]
}

resource aws_appautoscaling_policy django_scale_in {
  count = (var.django_max_capacity == var.django_min_capacity ? 0 : 1)

  name               = "scale-in"
  resource_id        = aws_appautoscaling_target.django_scale_target.0.resource_id
  scalable_dimension = aws_appautoscaling_target.django_scale_target.0.scalable_dimension
  service_namespace  = aws_appautoscaling_target.django_scale_target.0.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 300
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource aws_cloudwatch_metric_alarm django_cpu_utilization_low {
  count = (var.django_max_capacity == var.django_min_capacity ? 0 : 1)

  alarm_name          = "${var.prefix}-django-CPU-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = var.django_scale_in_cpu_low

  dimensions = {
    ClusterName = var.ecs_cluster.name
    ServiceName = aws_ecs_service.django.name
  }

  alarm_actions = [
    aws_appautoscaling_policy.django_scale_in.0.arn,
  ]
}

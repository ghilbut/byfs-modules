data aws_vpc default {
  default = true
}


data aws_subnet defaults {
  count = length(local.az_suffixes)

  availability_zone = "${var.aws_region}${local.az_suffixes[count.index]}"
  default_for_az = true
  vpc_id = data.aws_vpc.default.id
}


data aws_subnet default {
  availability_zone = "${var.aws_region}a"
  default_for_az = true
  vpc_id = data.aws_vpc.default.id
}
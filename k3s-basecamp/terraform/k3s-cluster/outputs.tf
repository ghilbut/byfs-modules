output private_ip {
  value = aws_instance.basecamp.private_ip
}

output public_ip {
  value = aws_instance.basecamp.public_ip
}

output argo_password {
  value     = random_password.argo.result
  sensitive = true
}

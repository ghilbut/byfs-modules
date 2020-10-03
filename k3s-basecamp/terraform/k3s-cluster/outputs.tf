output private_ip {
  value = aws_instance.basecamp.private_ip
}

output public_ip {
  value = aws_instance.basecamp.public_ip
}

output k8s_token {
  value     = random_uuid.token.result
  sensitive = true
}

output argo_password {
  value     = random_password.argo.result
  sensitive = true
}

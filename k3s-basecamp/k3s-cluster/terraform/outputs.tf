output private_ip {
  value = aws_instance.master.private_ip
}

output public_ip {
  value = aws_instance.master.public_ip
}

output k8s_token {
  value     = random_uuid.token.result
  sensitive = true
}

output argo_password {
  value     = random_password.argo.result
  sensitive = true
}

output grafana_username {
  value = local.grafana_username
}

output grafana_password {
  value = random_password.grafana.result
  sensitive = true
}

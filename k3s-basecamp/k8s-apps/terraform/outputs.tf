output grafana_admin_username {
  value = local.grafana_username
}

output grafana_admin_password {
  value = random_password.grafana_admin.result
  sensitive = true
}

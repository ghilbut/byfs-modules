output kubernetes_token {
  value = data.external.kubernetes_token.result.token
  sensitive = true
}

output grafana_admin_username {
  value = local.grafana_username
}

output grafana_admin_password {
  value = random_password.grafana_admin.result
  sensitive = true
}

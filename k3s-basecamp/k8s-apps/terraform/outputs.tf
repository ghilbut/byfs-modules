output kubernetes_token {
  value = data.external.kubernetes_token.result.token
  sensitive = true
}

output "load_balancer_ip" {
  value = var.controller_load_balancer_ip
}

output "namespace" {
  value = helm_release.nginx_ingress.namespace
}

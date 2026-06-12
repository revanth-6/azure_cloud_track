resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  version          = "4.8.3"
  namespace        = "ingress-nginx"
  create_namespace = true

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  # Configure NGINX Ingress as an internal load balancer in the AKS Subnet
  set {
    name  = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
    value = "true"
  }

  # Statically assign the private IP that Application Gateway targets
  set {
    name  = "controller.service.loadBalancerIP"
    value = "10.0.2.254"
  }

  # Disable default public service ports or configurations if necessary
  set {
    name  = "controller.metrics.enabled"
    value = "true"
  }

  # Enable Prometheus scraping annotations on the ingress controller pods
  set {
    name  = "controller.podAnnotations.prometheus\\.io/scrape"
    value = "true"
  }

  set {
    name  = "controller.podAnnotations.prometheus\\.io/port"
    value = "10254"
  }
}

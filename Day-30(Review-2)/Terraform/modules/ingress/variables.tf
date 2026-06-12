variable "controller_load_balancer_ip" {
  type        = string
  default     = "10.0.2.254"
  description = "The static private IP to assign to the NGINX Ingress load balancer."
}

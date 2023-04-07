resource "helm_release" "traefik" {
  count            = var.ingress_controller == "traefik" ? 1: 0
  namespace        = "ingress"
  create_namespace = true

  name       = "traefik"
  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  version    = "21.2.0"

  set {
    name    = "ports.web.nodePort"
    value   = var.ingress_port
  }

  set {
    name    = "deployment.replicas"
    value   = var.num_replicas
  }
}                                                                                                                                                                                                                                                                                                                                                                                                                                          


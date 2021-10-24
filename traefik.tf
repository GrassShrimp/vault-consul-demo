resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://helm.traefik.io/traefik"
  chart      = "traefik"
  version    = "9.15.2"
  namespace  = "traefik"

  values = [
    <<EOF
      additionalArguments:
      - --api.insecure=true
      logs:
        general:
          level: INFO
        access:
          enabled: true
      ingressRoute:
        dashboard:
          enabled: false
      ports:
        traefik:
          port: 8080
          exposedPort: 9000
        web:
          nodePort: 32080
        websecure:
          nodePort: 32443
      nodeSelector:
        ingress-ready: "true"
      tolerations:
      - key: "node-role.kubernetes.io/master"
        operator: "Exists"
        effect: "NoSchedule"
      persistence:
        enabled: true
        storageClass: standard
    EOF
  ]

  create_namespace = true

  depends_on = [ helm_release.metallb ]
}
data "kubernetes_service" "traefik" {
  metadata {
    name = "traefik"
    namespace = helm_release.traefik.namespace
  }
}
resource "local_file" "traefik-dashboard" {
  content = <<-EOF
  apiVersion: traefik.containo.us/v1alpha1
  kind: IngressRoute
  metadata:
    name: traefik-dashboard
  spec:
    entryPoints:
    - web
    routes:
    - kind: Rule
      match: HOST(`traefik.${data.kubernetes_service.traefik.status.0.load_balancer.0.ingress.0.ip}.nip.io`) && (PathPrefix(`/dashboard`) || PathPrefix(`/api`))
      services:
      - kind: TraefikService
        name: api@internal
  EOF
  filename = "${path.root}/configs/traefik-dashboard.yaml"
  provisioner "local-exec" {
    command = "kubectl apply -f ${self.filename} -n ${helm_release.traefik.namespace}"
  }
}

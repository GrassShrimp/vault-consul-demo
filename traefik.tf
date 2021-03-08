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
          port: 80
        websecure:
          port: 443
      persistence:
        enabled: true
        storageClass: hostpath
    EOF
  ]

  create_namespace = true
}

resource "null_resource" "ingressroute-dashboard" {
  provisioner "local-exec" {
    command = "kubectl apply -f ./traefik-dashboard.yaml -n ${helm_release.traefik.namespace}"
  }
}
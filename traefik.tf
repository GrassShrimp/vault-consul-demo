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

  depends_on = [ kubernetes_config_map.metallb-config ]
}

resource "null_resource" "ingressroute-dashboard" {
  provisioner "local-exec" {
    command = "kubectl apply -f ./traefik-dashboard.yaml -n ${helm_release.traefik.namespace}"
  }
}
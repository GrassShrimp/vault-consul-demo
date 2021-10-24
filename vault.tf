resource "helm_release" "vault" {
  name       = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.9.1"
  namespace  = "vault"

  values = [
  <<EOF
  server:
    affinity: ""
    ha:
      enabled: true
  ui:
    enabled: true
  EOF
  ]

  create_namespace = true

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=initialized --timeout=-1s -n ${self.namespace} pods --all"
  }

  depends_on = [ helm_release.consul ]
}

resource "null_resource" "vault-ansible" {
  provisioner "local-exec" {
    command = "ansible-playbook playbook.yaml -e \"namespace=${helm_release.vault.namespace}\""
  }

  provisioner "local-exec" {
    when = destroy
    command = "rm cluster-keys.json"
  }
}
resource "local_file" "vault-ingressroute" {
  content = <<-EOF
  apiVersion: traefik.containo.us/v1alpha1
  kind: IngressRoute
  metadata:
    name: vault
  spec:
    entryPoints:
    - web
    routes:
    - kind: Rule
      match: HOST(`vault.${data.kubernetes_service.traefik.status.0.load_balancer.0.ingress.0.ip}.nip.io`) && (PathPrefix(`/ui`) || PathPrefix(`/v1`))
      services:
      - name: vault-ui
        port: 8200
  EOF
  filename = "${path.root}/configs/vault-ingressroute.yaml"
  provisioner "local-exec" {
    command = "kubectl apply -f ${self.filename} -n ${helm_release.vault.namespace}"
  }
}

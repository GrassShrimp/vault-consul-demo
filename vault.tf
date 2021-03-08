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

resource "null_resource" "vault-ingressroute" {
  provisioner "local-exec" {
    command = "kubectl apply -f ./vault-ingressroute.yaml -n ${helm_release.vault.namespace}"
  }
}
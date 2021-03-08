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

  depends_on = [ helm_release.consul ]
}

resource "null_resource" "initialize-and-unseal-vault" {
  provisioner "local-exec" {
    command = "sleep 30"
  }

  provisioner "local-exec" {
    command = "kubectl exec -n ${helm_release.vault.namespace} vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json"
  }

  provisioner "local-exec" {
    command = "kubectl get pods -n vault | grep -E 'vault-\\d' | awk '{print $1}' | while read pod ; do kubectl exec -n ${helm_release.vault.namespace} $pod -- vault operator unseal $(cat cluster-keys.json | jq -r \".unseal_keys_b64[]\"); done"
  }

  provisioner "local-exec" {
    command = "kubectl exec -n ${helm_release.vault.namespace} vault-0 -- /bin/sh -c \"echo \"$(cat cluster-keys.json | jq -r .root_token)\" | vault login -\""
  }

  provisioner "local-exec" {
    command = "kubectl exec -n ${helm_release.vault.namespace} vault-0 -- vault auth enable kubernetes"
  }

  provisioner "local-exec" {
    command = "kubectl exec -n ${helm_release.vault.namespace} vault-0 -- vault write auth/kubernetes/config token_reviewer_jwt=\"$(kubectl exec -n ${helm_release.vault.namespace} vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)\" kubernetes_host=\"https://$KUBERNETES_PORT_443_TCP_ADDR:443\" kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt"
  }

  provisioner "local-exec" {
    command = "kubectl exec -n ${helm_release.vault.namespace} vault-0 -- vault secrets enable -path=secret kv-v2"
  }

  provisioner "local-exec" {
    command = "kubectl exec -n ${helm_release.vault.namespace} vault-0 -- vault kv put secret/webapp/config username=\"static-user\" password=\"static-password\""
  }

  provisioner "local-exec" {
    command = "kubectl exec -n ${helm_release.vault.namespace} vault-0 -- /bin/sh -c 'vault policy write webapp - <<EOF\npath \"secret/data/webapp/config\" {\n capabilities = [\"read\"]\n}\nEOF'"
  }

  provisioner "local-exec" {
    command = "kubectl exec -n ${helm_release.vault.namespace} vault-0 -- vault write auth/kubernetes/role/webapp bound_service_account_names=vault bound_service_account_namespaces=default policies=webapp ttl=24h"
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
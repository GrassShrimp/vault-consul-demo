resource "helm_release" "consul" {
  name       = "consul"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "consul"
  version    = "0.30.0"
  namespace  = "consul"

  values = [
  <<EOF
  global:
    datacenter: vault-kubernetes-tutorial

  client:
    enabled: true

  server:
    replicas: 1
    bootstrapExpect: 1
    disruptionBudget:
      maxUnavailable: 0
  EOF
  ]

  create_namespace = true

  # provisioner "local-exec" {
  #   when = destroy
  #   command = "kubectl delete persistentvolumeclaims -n ${self.namespace} $(kubectl get persistentvolumeclaims -n ${self.namespace} --no-headers=true | awk '{print $1}')"
  # }

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=ready --timeout=-1s -n ${self.namespace} pods --all"
  }

  depends_on = [ kind_cluster.vault-consul ]
}
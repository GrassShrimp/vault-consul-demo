resource "kind_cluster" "k8s-cluster" {
  name   = "k8s-cluster"
  image  = "kindest/node:v1.20.2@sha256:8f7ea6e7642c0da54f04a7ee10431549c0257315b3a634f6ef2fecaaedb19bab"
  config = <<-EOF
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    nodes:
    - role: control-plane
      kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"
      extraPortMappings:
      - containerPort: 32080
        hostPort: 80
        protocol: TCP
      - containerPort: 32443
        hostPort: 443
        protocol: TCP
    - role: worker
    - role: worker
  EOF
}

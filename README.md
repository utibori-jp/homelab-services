# homelab-services

Application-layer GitOps for my k3s homelab. Managed by Argo CD using the App-of-Apps pattern.

The cluster bootstrap (Argo CD itself, Tailscale operator) lives in a separate private repo, `homelab-infra`. This one only holds workloads on top of that base.

## Cluster

- k3s v1.34.3+k3s3 on Proxmox VMs
- 3 nodes: 1 control-plane, 2 workers
- Reached over Tailscale, no public ingress
- ServiceLB and built-in Traefik LoadBalancer disabled; Traefik runs as ClusterIP and is fronted by the Tailscale operator's `IngressClass: tailscale`

## Layout

```
bootstrap/
  root-app.yaml              apply once by hand, then Argo CD takes over
apps/
  kustomization.yaml         lists the four Applications below
  traefik-config.yaml        points at manifests/traefik-clusterip
  longhorn.yaml              longhorn helm chart
  vikunja.yaml               vikunja OCI helm chart
  ingresses.yaml             points at charts/tailscale-ingresses
charts/tailscale-ingresses/  in-repo helm chart, three Ingress resources
manifests/traefik-clusterip/ HelmChartConfig that flips k3s Traefik to ClusterIP
```

## Bootstrap

After Argo CD is up (handled by `homelab-infra`):

```
kubectl apply -f bootstrap/root-app.yaml
```

Everything else syncs from there.

## Access

All UIs are exposed only on the tailnet via the Tailscale operator. TLS is terminated by Tailscale, the upstream services run plain HTTP inside the cluster.

- argocd.tail078c12.ts.net
- longhorn.tail078c12.ts.net
- vikunja.tail078c12.ts.net

## Notes

- No secrets are committed. This repo is public.
- Longhorn is pinned to 1.11.1; 1.11.0 ships a validating-webhook regression that bricks the install.
- Vikunja is pulled from `oci://ghcr.io/go-vikunja/helm-chart`. The values live under a top-level `vikunja:` key (bjw-s common library convention).
- The Argo CD Application name for the in-cluster Argo CD server is `argo-cd-argocd-server`. The Ingress backend has to match that.

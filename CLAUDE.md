# CLAUDE.md

Guidance for Claude when working in this repository.

## What this repo is

Application-layer GitOps for a personal k3s homelab. Argo CD manages everything here via App-of-Apps. The cluster bootstrap (Argo CD itself, Tailscale operator) lives in a separate private repo, `homelab-infra`, and is out of scope for this one.

This repo is public. Treat it accordingly: no secrets, no tailnet identifiers beyond what is already in the README, no internal hostnames or IPs that aren't already committed.

## Writing style for any docs or comments you produce

The owner dislikes the typical AI documentation voice. When writing or editing Markdown, comments, or commit messages, avoid the following:

- Bold for emphasis. If something matters, the sentence should carry it.
- Emoji in headings or bullets.
- Em dashes (`—`). Use a comma, a period, or parentheses.
- Empty intensifiers: `seamlessly`, `robust`, `powerful`, `comprehensive`, `elegant`, `modern`, `leverage`, `simply`, `easily`.
- Self-referential intros: "This document describes...", "In this section we will...".
- Meta-hedges: "It's worth noting that...", "It's important to understand that...".
- "Not just X, but Y" constructions.
- Decorative summary sentences at the end of every section.
- Forced parallelism: don't pad lists to 3 or 5 items, don't make every bullet `Term: description`, don't give every section the same depth.
- Pre-code throat-clearing ("Here is an example:", "The following snippet demonstrates:") and post-code recap ("As you can see...").
- Horizontal rules (`---`) used as decoration.

What to do instead: write short declarative sentences, let structure be uneven where the content is uneven, and prefer concrete nouns to abstract praise. Aim for a personal-notes tone, not a product page.

## Repository layout

```
bootstrap/                   manual entry point, applied once by kubectl
apps/                        the App-of-Apps target, one Application per workload
charts/tailscale-ingresses/  in-repo helm chart for the three Tailscale Ingresses
manifests/traefik-clusterip/ HelmChartConfig overriding k3s' default Traefik
```

The single source of truth for "what runs in the cluster" is `clusters/home-lab/kustomization.yaml`. New apps are added by writing a new `apps/<name>.yaml` and listing it there.

## Things that are deliberately the way they are

- Longhorn is pinned to 1.11.1. Do not bump to 1.11.0; it has a validating webhook regression that breaks installs. Newer versions are fine in principle but verify before changing.
- Vikunja comes from `oci://ghcr.io/go-vikunja/helm-chart`, chart name `vikunja`. Values are nested under a top-level `vikunja:` key because the chart wraps bjw-s common library.
- The Argo CD Service name in-cluster is `argo-cd-argocd-server` (double prefix). The Ingress backend in `charts/tailscale-ingresses` has to match. There used to be a non-prefixed `argocd-server` from an old install; it was removed and should not come back.
- Traefik runs as ClusterIP, not LoadBalancer. k3s' ServiceLB is disabled at the node level (`/etc/rancher/k3s/config.yaml` has `disable: [servicelb]`). The only way traffic reaches a service from outside is through a Tailscale Ingress.
- TLS is terminated by Tailscale. Argo CD runs with `--insecure` for that reason. Don't add cert-manager or rewrite the upstream to HTTPS.

## Don't touch

- Anything related to the `argo-cd` or `tailscale-operator` Argo CD Applications. Those are owned by `homelab-infra`. Breaking either one severs the only access path to the cluster.
- The `argocd` Helm release in the cluster (chart `argocd-config`). It's a wrapper that owns the Argo CD CRDs. Uninstalling it cascades into every Application disappearing.
- `kube-system` resources other than the Traefik HelmChartConfig.

## Working against the cluster

The cluster is reached over Tailscale, then SSH to `home-lab-1`. From there:

```
sudo kubectl ...
```

For Helm, kubeconfig has to be passed explicitly because it lives under `/etc/rancher`:

```
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
sudo -E helm ...
```

If a LoadBalancer Service won't delete, it's the cleanup finalizer waiting for a controller that no longer exists (ServiceLB is disabled). Strip it by hand:

```
sudo kubectl patch svc <name> -n <ns> --type=json \
  -p='[{"op":"remove","path":"/metadata/finalizers"}]'
```

## Git / Commit conventions

- Use Conventional Commits. Scope is the directory or component: `fix(manifests/traefik-clusterip)`, `feat(apps/vikunja)`.
- Title line only. No body, no bullet points.
- Commit messages in English.
- Do not add `Co-Authored-By:`.

## When changing an Application
 
1. Edit the file under `apps/`.
2. Commit and push. Do not `kubectl apply` it directly, the App-of-Apps will pick it up.
3. Watch with `sudo kubectl get applications -n argocd -w`.
4. If a sync gets stuck, look at the Application's `.status.conditions` before touching anything.

## When adding a new app
 
1. New file in `apps/<name>.yaml`.
2. Add it to `apps/kustomization.yaml`.
3. If it needs a Tailscale Ingress, add a template to `charts/tailscale-ingresses/templates/` and a value in that chart's `values.yaml`. Backend service name has to match what the upstream chart actually creates, which is not always the release name.
4. Commit, push, watch the sync.

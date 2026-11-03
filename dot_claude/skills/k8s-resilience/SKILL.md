---
name: k8s-resilience
description: Evaluate and improve a Kubernetes workload so it keeps working, and recovers on its own, regardless of human actions (drains, deletes, edits, rotations) or unexpected events (node loss, pressure, expired credentials). Use when asked to "harden", make resilient or self-healing, or reduce manual intervention for a Deployment, DaemonSet, StatefulSet, Job or operator CRD (e.g. WekaClient), or after an incident where someone had to fix a workload by hand. Also covers probes, PodDisruptionBudgets, rollout strategy, load balancer and ingress health checks, and identifying HPA/VPA autoscaling candidates.
user-invocable: true
---

# Kubernetes resilience and self-healing review

Goal: Kubernetes, not a human, puts the workload back into its intended state.
This is about availability and recovery, not security (use a separate review for securityContext, RBAC, network policy).

## Principles

- **Toil reduction.** Kubernetes is powerful enough that humans should not have to remember its quirks (drain order, "don't delete that pod", "re-run this after the secret rotates"). The system must be robust to both humans and unexpected events, not rely on people behaving.
- **Defence in depth.** If two paths are equally good and cost about the same to implement, do both rather than picking one. Examples: preloaded image cache *and* `IfNotPresent`; GitOps `selfHeal` *and* an admission policy; a PDB *and* topology spread; a self-healing control *and* an alert that fires when it fails. Layers should fail independently. Still apply "smallest change" (below) to each layer: depth means redundant mechanisms for the same named failure, not extra settings for failures nobody named.
- **Trust, but verify.** Assume the platform, operators, charts and people mostly do the right thing, but never rely on that without evidence. A setting is not a guarantee until you have seen it work. Verify the rendered manifest and CRD schema rather than the chart values or docs, verify the live object matches Git, and verify each self-healing path by exercising it (delete the pod, drain the node, revoke the secret) and observing recovery, not by reading the config. Verify the backstop too: confirm the alert actually fires when the self-healing fails.

## Process

1. **Name the incident or fear.** What did a human have to do, or what could happen, that breaks the workload? Write each as "when X happens, Y breaks, and today Z fixes it by hand".
   Typical X: pod deleted, node drained or cordoned, node lost or under pressure, image pull fails, credential or secret expires or becomes unreadable, config edited live, rollout stalls, dependency down at start, node setting (sysctl, hugepages, kernel module) missing.
2. **Map each X to the checklist below.** One or more settings per failure mode; skip settings that answer no named failure. For each failure mode, look for a second, independent layer (defence in depth) and include it unless its cost is clearly out of proportion.
3. **Read the real spec.** Check the rendered manifest (`helm template`) and, for operator CRDs, the CRD schema (`kubectl explain`, or the chart's CRDs). Never assume a CRD field exists.
4. **Prefer the smallest change** that removes the manual step, per layer. Note the blast radius (which clusters/nodes) and whether pods roll on sync.
5. **Close the loop**: say how you would test it (delete a pod, drain a node, revoke the secret) and what alert tells you when self-healing is not enough. Where you have cluster access and the user approves, run the test and report what you observed; otherwise mark the change as unverified.

## Checklist

### Restart and health
- `terminationGracePeriodSeconds` and `preStop` long enough for clean shutdown (data paths, mounts, client unmounts).
- `restartPolicy` and Job `backoffLimit`, `activeDeadlineSeconds`, `podFailurePolicy` so failures end or retry deliberately.
- Probes are covered in their own section below.

### Probes (`readinessProbe` / `livenessProbe` / `startupProbe`)
Review every container, including sidecars and init-adjacent helpers. For each, ask what a failed probe causes and whether that is what you want.
- **`readinessProbe` is the baseline**: every container that serves traffic or counts toward availability has one. It answers "should this pod receive traffic / count as available", and it gates rollouts, PDB accounting and Service/Endpoint membership.
  - It must reflect the pod's own ability to serve, including the dependencies *it* needs to answer requests, but should degrade gracefully (shed or serve stale) where a shared dependency outage would otherwise mark every replica unready at once and turn a partial outage into a total one. Decide this deliberately and write it down.
  - Tune `periodSeconds`, `timeoutSeconds`, `failureThreshold` and `successThreshold` to the real latency and flap tolerance, not defaults. A readiness flap should not cause an outage on its own.
- **`livenessProbe` only for "wedged, and a restart fixes it"**. Check only the process's own internals (event loop responsive, deadlock detector). Never check dependencies (restart storms). Make it more lenient than readiness (higher `failureThreshold` or `periodSeconds`), and never point it at the same endpoint as readiness unless you have decided that "not ready" should mean "restart". Omit it if there is no wedged state a restart would fix.
- **`startupProbe`** for slow starters, so liveness doesn't kill them mid-boot. Size `failureThreshold * periodSeconds` to the worst-case start (cold cache, big image, replaying data), not the typical one.
- **Probe mechanism, in order of preference** (for `readinessProbe`, and by default `livenessProbe` and `startupProbe` too):
  1. **`grpc`** if the app speaks gRPC or can implement the standard gRPC Health Checking Protocol (`grpc.health.v1.Health`). It checks a real application-level answer over the real listener, with no HTTP shim needed. Use the `service` field to check a specific service. Confirm the cluster's Kubernetes version supports the `grpc` probe, and note its limits: it takes a numeric `port` (not a named port) and does not support TLS-only listeners, so expose the health service on a plaintext port if needed.
  2. **`httpGet`** if the app serves HTTP and gRPC is not an option. Use a dedicated lightweight health path that returns 2xx only when the app can serve. Set `scheme` and `httpHeaders` (e.g. `Host`) where the app needs them, and remember any 2xx/3xx counts as success, so don't point it at a path that redirects.
  3. **`tcpSocket`** only if there is no other option (the protocol is neither HTTP nor gRPC and you cannot change the app). It only proves something is listening, not that the app can serve, so treat it as a floor: add a health endpoint to the app when you can, and rely on the load balancer and remote end-to-end checks for the real signal in the meantime.
  Record why a lower-preference mechanism was chosen whenever you pick one.
- **Never use `exec` probes, i.e. no local shell commands inside the pod.** Use one of the mechanisms above so the kubelet exercises the real network listener. Reasons: `exec` forks a process per probe (CPU and PID cost at scale, and it is counted against the container's own limits), needs a shell or binaries that distroless images don't have, can hang or leave zombies on timeout, and proves only that a command ran, not that the port is reachable. If the app has no health endpoint, add one (gRPC health service or HTTP path) rather than reaching for `exec`, and use `tcpSocket` only as the last resort.
- Probe the same port and path real traffic uses where possible (or a dedicated lightweight endpoint on the serving listener), so a probe pass means the serving path works. A probe on a separate admin port can pass while the serving port is dead.
- Probe handlers must be cheap and must not take locks shared with request handling, or probes will fail exactly when the pod is busiest.

### Placement and eviction
- `priorityClassName`: protect pods that must not be evicted or must preempt. Reserve `system-node-critical` for genuinely node-critical, small pods.
- Resources: `requests` set; memory `limits` set; requests == limits (Guaranteed QoS) for pods that must be last to be evicted. Set `ephemeral-storage` requests.
- `tolerations`: `operator: Exists` for node agents; for stateful pods tune `node.kubernetes.io/not-ready` / `unreachable` `tolerationSeconds` (default 300s) to the failover time you want.
- `topologySpreadConstraints` / pod anti-affinity so one node or zone loss isn't total loss.
- `nodeSelector` / affinity that matches labels which exist on every intended node.
- `PodDisruptionBudget`: see its own section below.

### Images and pull credentials
- Pin tags (or digests); never `latest`.
- Explicit `imagePullPolicy: IfNotPresent` for pinned images so restarts don't need the registry or pull secret.
- Pre-pull/cache images on target nodes (preload DaemonSet) and keep that cache from being evicted.
- `imagePullSecrets` present in every namespace that pulls; secret refreshed automatically (External Secrets `refreshInterval`), with an alert when the sync goes stale or fails.
- Know what happens when the credential expires: cached image still runs; new nodes cannot pull.

### PodDisruptionBudget
- Every multi-replica workload that must stay available through voluntary disruption (drains, upgrades, autoscaler scale-down) has one. Single-replica workloads: a PDB with `minAvailable: 1` blocks every drain, so either run 2+ replicas or accept disruption and don't add one.
- Prefer `maxUnavailable` (scales with replica count) over `minAvailable`. Never set `minAvailable` equal to replicas, or `maxUnavailable: 0`: it blocks drains and creates manual work (someone must delete the PDB to patch a node).
- Check the arithmetic against the replica count *and* autoscaler bounds (HPA `minReplicas`), at the smallest size the workload will run at.
- The selector must match the pods' labels exactly; a PDB that matches nothing protects nothing and a PDB that matches the wrong set blocks unrelated drains. Verify with `kubectl get pdb` (`ALLOWED DISRUPTIONS`, `CURRENT`, `EXPECTED`).
- Set `unhealthyPodEvictionPolicy: AlwaysAllow` for workloads where a crashing or never-ready pod should not block a drain (check that your cluster version supports it).
- PDBs only govern voluntary evictions, and they count only *ready* pods, so a bad `readinessProbe` directly causes a stuck drain or false protection. Pair with `topologySpreadConstraints` (defence in depth: spread limits what one node loss takes, the PDB limits what humans and the autoscaler take).
- Alert on PDBs with zero allowed disruptions for a sustained period, since that is the signal that a drain or upgrade is about to need a human.
- StatefulSets and operator-managed workloads: confirm whether the operator manages its own PDB before adding one.

### Rollout strategy and controllers
Review the rollout configuration for every controller, and ask: if this rollout is bad, what limits the damage, and what stops it without a human?
- Deployment: `strategy.rollingUpdate` (`maxUnavailable`, `maxSurge`), `minReadySeconds`, `progressDeadlineSeconds`. Set `maxUnavailable` low (0 where capacity allows, with `maxSurge` > 0) so new pods must be ready before old ones are removed. `minReadySeconds` catches pods that pass readiness then crash. `progressDeadlineSeconds` makes a stalled rollout visible (`ProgressDeadlineExceeded`); pair with an alert, and with automatic rollback via your GitOps or progressive-delivery tool, since Deployments do not roll back by themselves.
- Progressive delivery (Argo Rollouts `Rollout`, Flagger `Canary`): if present, review `strategy.canary` / `strategy.blueGreen` steps, `maxUnavailable`/`maxSurge`, analysis templates and `abortScaleDownDelaySeconds`. Prefer automated analysis that aborts and rolls back on error rate or latency, using the same remote health signals as below. Confirm the CRD fields with `kubectl explain` before suggesting them.
- DaemonSet: `updateStrategy` (`maxUnavailable`) sized so a bad rollout can't take out every node at once.
- StatefulSet: `podManagementPolicy`, `updateStrategy.partition`, `persistentVolumeClaimRetentionPolicy`.
- Rollouts depend on probes: with no or weak `readinessProbe`, `maxUnavailable` and `minReadySeconds` protect nothing. Review the two together.
- Check that rollout and traffic settings agree: `terminationGracePeriodSeconds` and `preStop` must cover the time the load balancer needs to stop sending traffic (see the traffic section), or every rollout drops requests.
- Operator CRDs: use the operator's own knobs (upgrade policy, auto-remove timeout, tolerations, priority) after confirming them in the CRD.

### Load balancing and ingress health checks
The aim is a check that fails when real users would fail, from where real users are. Strive for remote, end-to-end checks, and keep the in-cluster `readinessProbe` as the baseline underneath them.
- **Baseline: `readinessProbe`.** Kubernetes only puts ready pods into Service endpoints, so this is the first line of defence for every path. Ingress controllers and Gateway implementations that route to pod IPs via EndpointSlices inherit it.
- **Layer on top: load balancer health checks** (cloud LB, Gateway `HealthCheckPolicy` / `BackendConfig` / target group annotations, Ingress controller upstream checks, service mesh outlier detection). Configure them explicitly rather than relying on defaults: path, port, protocol, expected status, interval, timeout, healthy and unhealthy thresholds. Where the platform defaults to checking `/` and expecting 200, confirm that actually reflects app health (a default check on `/` may pass on a redirect or a static page while the app is broken).
- **Layer on top: remote end-to-end checks** (blackbox / synthetic probes from outside the cluster or from another cluster or region, hitting the real hostname, TLS and path through the real LB and Ingress). These catch what in-pod and in-cluster checks cannot: DNS, certificates, LB and Ingress misconfiguration, NetworkPolicy, and the whole route. Alert on these; they are the truth for "can users reach it".
- **Never use local shell commands inside a pod** (`exec` probes, `kubectl exec ... curl localhost`) as a health signal. They test the pod from inside itself and say nothing about the network path.
- Align the layers: the LB health check path and the `readinessProbe` should agree on what "healthy" means (usually the same endpoint, or the LB check a superset). If they disagree, you get pods that are Ready but receiving no traffic, or traffic sent to pods that are about to be unready.
- Drain gracefully so a rollout or scale-down doesn't drop requests: `preStop` sleep (via an `httpGet` or built-in `sleep` handler, not a shell script) or app-level graceful shutdown longer than the LB's deregistration delay plus propagation time, with `terminationGracePeriodSeconds` longer than both. Use container-native LB / pod readiness gates where the platform supports them, so a pod isn't counted Ready until the LB has registered it.
- Health checks must not be tied to a shared dependency such that one dependency outage empties every backend at once. Prefer fail-open behaviour or panic thresholds where the LB supports them (e.g. Envoy panic threshold) when all backends look unhealthy.
- Timeouts and retries: check that LB and Ingress timeouts, idle timeouts and retry budgets are consistent with the app's (idle timeout shorter than the LB's causes intermittent resets) and that retries can't amplify an outage.
- Detection: alert on LB backends unhealthy or zero healthy, Ingress 5xx rate, certificate expiry, and the remote probe failing. For each alert, the response should be something Kubernetes or the LB does automatically (eject, reroute, roll back) before it is a human.

### Autoscaling (HPA / VPA candidates)
Humans bumping replica counts or resource requests by hand after a load change or an OOMKill is toil, and a resilience gap. For every workload, decide explicitly: HPA, VPA, both (on different signals), or neither, and record why.
- **Find candidates from evidence, not guesses.** Look for a fixed replica count with usage that varies over time (HPA candidate), requests far from real usage or CPU throttling or OOMKills (VPA candidate), and incidents where someone scaled or resized by hand. Example PromQL (verify metric and label names against your kube-state-metrics and cAdvisor versions first):
  - Over-provisioned CPU: `sum by (namespace, pod, container) (rate(container_cpu_usage_seconds_total{container!=""}[1h])) / sum by (namespace, pod, container) (kube_pod_container_resource_requests{resource="cpu"})`
  - CPU throttling: `rate(container_cpu_cfs_throttled_periods_total[5m]) / rate(container_cpu_cfs_periods_total[5m])`
  - Memory headroom: `max by (namespace, pod, container) (container_memory_working_set_bytes{container!=""}) / max by (namespace, pod, container) (kube_pod_container_resource_limits{resource="memory"})`
  - OOMKills: `kube_pod_container_status_last_terminated_reason{reason="OOMKilled"}`
  - Peak-to-trough load per workload (e.g. `max_over_time` vs `min_over_time` of request rate over a week) shows whether horizontal scaling would pay off.
- **HPA candidates** (`autoscaling/v2`): stateless, horizontally scalable workloads with 2+ replicas whose load varies, where adding replicas adds capacity.
  - Pick a signal that tracks load: CPU utilisation is the default; prefer request rate, queue depth or latency (custom/external metrics, or KEDA for event-driven; confirm the CRD) where CPU is a poor proxy. Memory is rarely a good scaling signal because it doesn't fall when load does.
  - HPA utilisation is measured against `requests`, so requests must be set and realistic. A missing or wrong request makes HPA scale wrongly or not at all.
  - `minReplicas` is a floor sized for the failure you must survive (at least 2, and enough for zone spread and the PDB), not the cheapest value. If the metrics pipeline fails, HPA holds the current replica count rather than scaling to zero, so the floor is your backstop.
  - `maxReplicas` bounded by what the cluster, quota and downstream dependencies can take. Scaling out into a shared dependency can turn a spike into an outage.
  - Set `behavior` deliberately: scale up fast, scale down slowly (`stabilizationWindowSeconds`, `policies`) to avoid flapping and to avoid dropping in-flight work. Scale-down needs graceful shutdown (`preStop`, `terminationGracePeriodSeconds`) and a working `readinessProbe`; startup behaviour needs `startupProbe` so cold pods aren't counted as busy or ready too early.
  - Don't let GitOps fight the HPA: omit `spec.replicas` from the manifest (or `ignoreDifferences` on it) so `selfHeal` doesn't reset the count on every sync.
  - Scaling pods needs node capacity: pair with Cluster Autoscaler or Karpenter (or deliberate headroom), or the new replicas just sit `Pending`.
- **VPA candidates** (`VerticalPodAutoscaler`, an add-on: confirm it is installed and its version and CRD): workloads that can't scale horizontally (singletons, many StatefulSets, leader-elected components), batch and Jobs, and anything whose requests are guesses.
  - Start with `updateMode: "Off"` to collect recommendations, review them against the evidence above, then move to `Initial` or an applying mode once trusted. Applying modes evict pods to resize (check whether your version supports in-place resize), so they need 2+ replicas and a `PodDisruptionBudget`, or accept the restart.
  - Constrain it with `resourcePolicy` (`minAllowed`, `maxAllowed`, `controlledResources`) so a bad recommendation can't starve or bloat a pod, and keep requests == limits where Guaranteed QoS is needed.
  - **Don't run HPA and VPA on the same resource metric** (e.g. both on CPU): they fight. Use VPA for memory (and CPU requests) with HPA on a custom or external metric, or VPA in `Off` mode purely as a right-sizing aid.
- **Usually neither**: DaemonSets (VPA at most; there is no horizontal axis), workloads whose replica count is fixed by design (sharded, quorum-based, licence-bound), and operator-managed workloads where the operator owns replicas and resources. Check whether the CRD exposes a `scale` subresource before pointing an HPA at it, and prefer the operator's own scaling knobs.
- **Defence in depth**: HPA with a sensible `minReplicas` floor, plus VPA recommendations for right-sizing, plus node autoscaling, plus a PDB, plus an alert when the HPA is pinned at `maxReplicas` or reports `ScalingLimited` / `AbleToScale=False` or missing metrics (`kube_horizontalpodautoscaler_*`). The alert says when autoscaling isn't enough.
- **Trust, but verify**: prove it by generating load (or replaying traffic) and watching scale-out, scale-in and the absence of flapping, and by killing the metrics source to confirm the workload holds at its floor.

### Config and node state
- GitOps `selfHeal` reverts live edits; confirm it's on for the app and that `ignoreDifferences` doesn't hide the drift you care about.
- Node-level settings (sysctl, hugepages, modules) should be enforced by a DaemonSet or node config, not set by hand. Privileged pods are a tradeoff: state it and get approval.
- Admission policy (e.g. Kyverno) can enforce defaults (priority, probes, resources) so a human edit can't remove them. Pair it with `selfHeal`: one reverts drift after the fact, the other rejects it up front.
- Make startup dependencies self-resolving: init containers or retries, `optional: true` where a missing secret/configmap shouldn't block, and keep the last good Secret if the source is unreadable.

### Detection (the backstop)
- Alerts for: crash loops, `ImagePullBackOff`/`ErrImagePull`, pods Pending, DaemonSet unavailable, replicas unavailable, ExternalSecret not ready, node pressure.
- Each alert names the action; if the action is "a human does X", ask whether Kubernetes could do X instead.
- Alert on the *self-healing mechanism itself* failing (stale ExternalSecret sync, GitOps app out of sync or `selfHeal` disabled, preload DaemonSet not fully scheduled), not just on the workload symptom.

## Anti-patterns
- Liveness probes that depend on external services.
- `exec` probes or any local shell command inside a pod used as a health check.
- Ignoring the probe preference order (`grpc`, then `httpGet`, then `tcpSocket`): e.g. `tcpSocket` on an app that could serve an HTTP health endpoint, or `httpGet`/`tcpSocket` on a gRPC app that could implement `grpc.health.v1`.
- Missing `readinessProbe` on a serving container, or liveness and readiness pointed at the same check without a deliberate decision.
- Relying on a single layer of health checking (only `readinessProbe`, or only an external check) when both are cheap.
- LB or Ingress health checks left on platform defaults that were never confirmed to reflect real app health.
- Rollout settings (`maxUnavailable`, `minReadySeconds`) that depend on a readiness probe which does not exist or always passes.
- A hand-set `replicas` or hand-tuned requests on a workload whose load varies, with no HPA/VPA decision recorded.
- HPA and VPA both acting on CPU or memory for the same workload; an HPA with no requests, `minReplicas: 1` on something that must survive a node loss, or a GitOps-managed `replicas` field fighting the HPA.
- `system-node-critical` on everything.
- PDBs that forbid any disruption (`minAvailable` == replicas, `maxUnavailable: 0`, or a single replica with `minAvailable: 1`).
- Adding every setting "just in case". Each one should answer a named failure mode. (Redundant layers for the *same* named failure are fine; unrelated settings are not.)
- Choosing a single mitigation when a second, comparably cheap and independent one exists.
- Runbooks that say "remember to...". If a human must remember, automate it or enforce it.
- Flipping a privileged or node-wide change on without stating blast radius.
- Guessing CRD fields that were not verified.
- Declaring a workload "self-healing" because the config looks right, without exercising the failure or confirming the alert fires.

## Output format

Report a table: **Failure mode** | **Today** | **Layers** (primary, plus independent backup) | **Change** | **Blast radius** | **How to test** | **Verified?** (tested and observed, or not yet). Include an **autoscaling candidates** list (workload, HPA / VPA / both / neither, signal, and why). Then list what you did not change and why, and any decision the user must make.

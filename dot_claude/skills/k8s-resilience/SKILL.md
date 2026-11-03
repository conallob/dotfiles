---
name: k8s-resilience
description: Evaluate and improve a Kubernetes workload so it keeps working, and recovers on its own, regardless of human actions (drains, deletes, edits, rotations) or unexpected events (node loss, pressure, expired credentials). Use when asked to "harden", make resilient or self-healing, or reduce manual intervention for a Deployment, DaemonSet, StatefulSet, Job or operator CRD (e.g. WekaClient), or after an incident where someone had to fix a workload by hand.
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
- **Never use `exec` probes, i.e. no local shell commands inside the pod.** Use `httpGet`, `tcpSocket` or `grpc` so the kubelet exercises the real network listener. Reasons: `exec` forks a process per probe (CPU and PID cost at scale, and it is counted against the container's own limits), needs a shell or binaries that distroless images don't have, can hang or leave zombies on timeout, and proves only that a command ran, not that the port is reachable. If the app has no health endpoint, add one (or use `tcpSocket` as a floor) rather than reaching for `exec`.
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
- Missing `readinessProbe` on a serving container, or liveness and readiness pointed at the same check without a deliberate decision.
- Relying on a single layer of health checking (only `readinessProbe`, or only an external check) when both are cheap.
- LB or Ingress health checks left on platform defaults that were never confirmed to reflect real app health.
- Rollout settings (`maxUnavailable`, `minReadySeconds`) that depend on a readiness probe which does not exist or always passes.
- `system-node-critical` on everything.
- PDBs that forbid any disruption (`minAvailable` == replicas, `maxUnavailable: 0`, or a single replica with `minAvailable: 1`).
- Adding every setting "just in case". Each one should answer a named failure mode. (Redundant layers for the *same* named failure are fine; unrelated settings are not.)
- Choosing a single mitigation when a second, comparably cheap and independent one exists.
- Runbooks that say "remember to...". If a human must remember, automate it or enforce it.
- Flipping a privileged or node-wide change on without stating blast radius.
- Guessing CRD fields that were not verified.
- Declaring a workload "self-healing" because the config looks right, without exercising the failure or confirming the alert fires.

## Output format

Report a table: **Failure mode** | **Today** | **Layers** (primary, plus independent backup) | **Change** | **Blast radius** | **How to test** | **Verified?** (tested and observed, or not yet). Then list what you did not change and why, and any decision the user must make.

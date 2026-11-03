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
- `startupProbe` for slow starters, so liveness doesn't kill them mid-boot.
- `livenessProbe` only for "this process is wedged and a restart fixes it". Never check dependencies (restart storms).
- `readinessProbe` for "should receive traffic / count as available".
- `terminationGracePeriodSeconds` and `preStop` long enough for clean shutdown (data paths, mounts, client unmounts).
- `restartPolicy` and Job `backoffLimit`, `activeDeadlineSeconds`, `podFailurePolicy` so failures end or retry deliberately.

### Placement and eviction
- `priorityClassName`: protect pods that must not be evicted or must preempt. Reserve `system-node-critical` for genuinely node-critical, small pods.
- Resources: `requests` set; memory `limits` set; requests == limits (Guaranteed QoS) for pods that must be last to be evicted. Set `ephemeral-storage` requests.
- `tolerations`: `operator: Exists` for node agents; for stateful pods tune `node.kubernetes.io/not-ready` / `unreachable` `tolerationSeconds` (default 300s) to the failover time you want.
- `topologySpreadConstraints` / pod anti-affinity so one node or zone loss isn't total loss.
- `nodeSelector` / affinity that matches labels which exist on every intended node.
- `PodDisruptionBudget` for multi-replica workloads. Avoid `minAvailable` equal to replicas: it blocks drains and creates manual work.

### Images and pull credentials
- Pin tags (or digests); never `latest`.
- Explicit `imagePullPolicy: IfNotPresent` for pinned images so restarts don't need the registry or pull secret.
- Pre-pull/cache images on target nodes (preload DaemonSet) and keep that cache from being evicted.
- `imagePullSecrets` present in every namespace that pulls; secret refreshed automatically (External Secrets `refreshInterval`), with an alert when the sync goes stale or fails.
- Know what happens when the credential expires: cached image still runs; new nodes cannot pull.

### Rollouts and controllers
- Deployment: `strategy.rollingUpdate` (`maxUnavailable`, `maxSurge`), `minReadySeconds`, `progressDeadlineSeconds`.
- DaemonSet: `updateStrategy` (`maxUnavailable`) sized so a bad rollout can't take out every node at once.
- StatefulSet: `podManagementPolicy`, `updateStrategy.partition`, `persistentVolumeClaimRetentionPolicy`.
- Operator CRDs: use the operator's own knobs (upgrade policy, auto-remove timeout, tolerations, priority) after confirming them in the CRD.

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
- `system-node-critical` on everything.
- PDBs that forbid any disruption.
- Adding every setting "just in case". Each one should answer a named failure mode. (Redundant layers for the *same* named failure are fine; unrelated settings are not.)
- Choosing a single mitigation when a second, comparably cheap and independent one exists.
- Runbooks that say "remember to...". If a human must remember, automate it or enforce it.
- Flipping a privileged or node-wide change on without stating blast radius.
- Guessing CRD fields that were not verified.
- Declaring a workload "self-healing" because the config looks right, without exercising the failure or confirming the alert fires.

## Output format

Report a table: **Failure mode** | **Today** | **Layers** (primary, plus independent backup) | **Change** | **Blast radius** | **How to test** | **Verified?** (tested and observed, or not yet). Then list what you did not change and why, and any decision the user must make.

# Kubernetes Taints and Tolerations

## 1. Taint

A **Taint** is a Kubernetes mechanism used to restrict Pods from being scheduled on a particular Node.

Taints are applied to **Nodes**.

```text
Taint → Node
```

A Node with a taint tells the Kubernetes Scheduler:

> "Do not schedule Pods here unless they have a matching toleration."


### 1.2 Why Do We Use Taints?

Taints are used to control which Pods can run on specific Nodes.

**Common Use Cases:**

* Dedicated database Nodes
* GPU Nodes
* Production Nodes
* Special hardware Nodes
* Control-plane Nodes
* Workload isolation
* Preventing unwanted Pods from being scheduled


### 1.3 Taint Syntax
```
kubectl taint nodes <node-name> key=value:effect
```

Example:
```
kubectl taint nodes worker-1 dedicated=database:NoSchedule
```

Here:
```
Key    = dedicated
Value  = database
Effect = NoSchedule
```

### 1.4 Taint Structure

The basic structure is: ``` key=value:effect ```

Example: ```dedicated=database:NoSchedule```

Key: ```dedicated```

Value: ```database```

Effect:```NoSchedule```

### 1.5 Taint Effects

There are three main taint effects:
```
NoSchedule
PreferNoSchedule
NoExecute
```

### 1.6 NoSchedule

`NoSchedule` is a hard restriction.

Pods without a matching toleration will not be scheduled on the Node.

Example:
```
kubectl taint nodes worker-1 dedicated=database:NoSchedule
```

Flow:
```
Pod
 ↓
Scheduler
 ↓
Node has NoSchedule taint
 ↓
Pod has no matching toleration
 ↓
❌ Pod cannot be scheduled
```

>Existing Pods are not automatically evicted when a `NoSchedule` taint is added.

### 1.7 PreferNoSchedule

`PreferNoSchedule` is a soft restriction.

Kubernetes tries to avoid scheduling Pods on the Node, but it may still schedule them if necessary.

Example:
```
kubectl taint nodes worker-1 dedicated=database:PreferNoSchedule
```

Difference
```
NoSchedule
    ↓
Hard restriction

PreferNoSchedule
    ↓
Soft restriction
```
### 1.8 NoExecute

`NoExecute` affects both new and existing Pods.

Pods that don't tolerate the taint can be evicted.

Example:
```
kubectl taint nodes worker-1 dedicated=database:NoExecute
```

Flow:
```
Node
 ↓
NoExecute taint
 ↓
Existing Pod without toleration
 ↓
❌ Pod can be evicted
```

### 1.9 Add a Taint

First check the Nodes:
```
kubectl get nodes
```

Example:
```
NAME       STATUS   ROLES
master     Ready    control-plane
worker-1   Ready    <none>
worker-2   Ready    <none>
```

Add a taint:
```
kubectl taint nodes worker-1 dedicated=database:NoSchedule
```

Output:
```
node/worker-1 tainted
```

### 1.10 Check Node Taints

Use:
```
kubectl describe node worker-1
```

Look for:
```
Taints:
dedicated=database:NoSchedule
```

You can also check all Nodes:
```
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

### 1.11 Remove a Taint

To remove a taint, add `-` at the end.
```
kubectl taint nodes worker-1 dedicated=database:NoSchedule-
```

Output:
```
node/worker-1 untainted
```

Verify:
```
kubectl describe node worker-1
```
### 1.12 Multiple Taints on a Node

A Node can have multiple taints.

Example:
```
kubectl taint nodes worker-1 environment=production:NoSchedule
kubectl taint nodes worker-1 workload=database:NoSchedule
```

Now the Node has:
```
environment=production:NoSchedule
workload=database:NoSchedule
```
A Pod must tolerate the relevant taints to be scheduled on that Node.

### 1.13 Troubleshooting Taints

If a Pod is stuck in Pending
Check:
```
kubectl describe pod <pod-name>
```
Look at the **Events** section.

Then check Node taints:
```
kubectl describe node <node-name>
```
Or:
```
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```
If the Node has:
```
dedicated=database:NoSchedule
```

and the Pod doesn't have a matching toleration, the Pod cannot be scheduled on that Node.

### 1.14 Commands

```bash
# Add Taint
kubectl taint nodes worker-1 dedicated=database:NoSchedule

# Check Taint
kubectl describe node worker-1

# Remove Taint
kubectl taint nodes worker-1 dedicated=database:NoSchedule-

# Check all Node Taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```
---
# 2. Tolerations
A **Toleration** is a Kubernetes Pod configuration that allows a Pod to be scheduled on a Node that has a matching **Taint**.

Tolerations are applied to **Pods**.
```
Toleration → Pod
```
A toleration tells Kubernetes:

> "This Pod can tolerate the specified taint."

### 2.2 Why Do We Use Tolerations?

Tolerations are mainly used when Pods need to run on Nodes that have been tainted.

**Common Use Cases:**

* Database Pods on dedicated database Nodes
* GPU workloads on GPU Nodes
* Production workloads on dedicated Nodes
* Special hardware workloads
* Control-plane workloads when explicitly required
* Workload isolation

### 2.3 Basic Toleration Syntax

Example:
```
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"
```

This Pod can tolerate:
```
dedicated=database:NoSchedule
```

### 2.4 Complete Pod Example
```
apiVersion: v1
kind: Pod
metadata:
  name: database-pod

spec:
  tolerations:
    - key: "dedicated"
      operator: "Equal"
      value: "database"
      effect: "NoSchedule"

  containers:
    - name: nginx
      image: nginx
```
### 2.5 How Toleration Works With Taint

Suppose the Node has this Taint:
```
dedicated=database:NoSchedule
```

The Pod has:
```
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"
```

The values match:
```
Node Taint
------------------------
key    = dedicated
value  = database
effect = NoSchedule
------------------------
          ↓
        MATCH
          ↓
Pod Toleration
------------------------
key    = dedicated
value  = database
effect = NoSchedule
------------------------
          ↓
      ✅ Allowed
```
### 2.6 Important: Toleration Does NOT Select a Node

This is one of the most important interview points.

A toleration does **not** force a Pod to run on a specific Node.

It only allows the Pod to run on a Node with a matching taint.

Example:
```
Node:
dedicated=database:NoSchedule

Pod:
Matching toleration

Result:
✅ Pod is allowed on that Node
```

But Kubernetes can still choose another suitable Node.

For Node selection, use:

* NodeSelector
* Node Affinity

### 2.7 Toleration Effects

Tolerations can specify the taint effect:

```text
NoSchedule
PreferNoSchedule
NoExecute
```

Example:

```yaml
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"
```

### 2.8 NoSchedule Toleration

Suppose the Node has:
```
dedicated=database:NoSchedule
```

The Pod needs:
```
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"
```

Without the toleration:
```
❌ Pod cannot be scheduled on that tainted Node
```

With the toleration:
```
✅ Pod is allowed
```

### 2.9 NoExecute Toleration

Suppose the Node has:

```text
dedicated=database:NoExecute
```

The Pod can tolerate it using:

```yaml
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoExecute"
```

This allows the Pod to remain on the Node.

Without the matching toleration, an existing Pod can be evicted.

### 2.10 TolerationSeconds

For `NoExecute`, we can specify how long a Pod should tolerate the taint.

Example:

```yaml
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoExecute"
    tolerationSeconds: 60
```

Meaning:

```text
NoExecute taint applied
        ↓
Pod remains for 60 seconds
        ↓
Taint still exists
        ↓
Pod is evicted
```

This is useful when we don't want immediate eviction.

### 2.11 Troubleshooting Tolerations

If a Pod is stuck in Pending

Check the Pod:
```
kubectl describe pod <pod-name>
```
Check the Events section.

Then check Node taints:
```
kubectl describe node <node-name>
```

Suppose the Node has:
```
dedicated=database:NoSchedule
```

But the Pod has:
```
tolerations:
  - key: "workload"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"
```

This does **not** match because:
```
Node key:
dedicated

Pod key:
workload
```

Therefore:
```
❌ Toleration does not match
```

The Pod cannot tolerate that taint.


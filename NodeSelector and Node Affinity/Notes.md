# NodeSelector and Node Affinity

## 1. Introduction

Kubernetes Scheduler decides on which Node a Pod should run.

By default, Kubernetes considers different factors such as:

* CPU and memory availability
* Resource requests
* Taints and tolerations
* Node affinity
* Pod affinity
* Pod anti-affinity
* Node conditions

Sometimes we don't want a Pod to run on any available Node.

For example:

* Production Pods should run only on production Nodes.
* GPU workloads should run only on GPU Nodes.
* Database Pods should run only on dedicated Nodes.
* Development workloads should run only on development Nodes.

For these requirements, Kubernetes provides **NodeSelector** and **Node Affinity**.

---

## 2. Node Labels

Before using NodeSelector or Node Affinity, we normally add labels to Nodes.

A label is a key-value pair attached to a Kubernetes object.

Example:
```
environment=production
team=backend
disk=ssd
hardware=gpu
```

### Check Node Labels
```
kubectl get nodes --show-labels
```

Example output:

```text
NAME     STATUS   ROLES    LABELS
node1    Ready    worker   environment=production
node2    Ready    worker   environment=development
```
---
## 3. Adding a Label to a Node

Use:
```
kubectl label nodes <node-name> <key>=<value>
```

Example:
```
kubectl label nodes node1 environment=production
```

Another example:
```
kubectl label nodes node2 environment=development
```

Add multiple labels:
```
kubectl label nodes node1 environment=production team=backend
```
---
## 4. Removing a Node Label

To remove a label:
```
kubectl label nodes node1 environment-
```
The `-` at the end removes the label.

---
## 5. What is NodeSelector?

`nodeSelector` is the simplest method of controlling Pod placement.

It allows us to tell Kubernetes:

> Schedule this Pod only on a Node having a specific label.

The Pod will be scheduled only if the Node has the required label.

### 5.1 NodeSelector Syntax 

Basic syntax:
```
spec:
  nodeSelector:
    key: value
```

Example:
```
spec:
  nodeSelector:
    environment: production
```

This means:
```
Pod → Node with environment=production
```

### 5.2 NodeSelector Example

First label the Node:
```
kubectl label nodes node1 environment=production
```

Create the Pod:
```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-node-selector
spec:
  nodeSelector:
    environment: production
  containers:
    - name: nginx
      image: nginx
      ports:
        - containerPort: 80
```

Save it as:
```
node-selector.yaml
```

Apply:
```
kubectl apply -f node-selector.yaml
```

Check:
```
kubectl get pods -o wide
```

The Pod should be scheduled on the Node having:
```
environment=production
```

### 5.3 How NodeSelector Works

The scheduling flow is:

```
Node
  |
  |-- label: environment=production
  |
Kubernetes Scheduler
  |
  |-- checks nodeSelector
  |
Pod
  |
  |-- nodeSelector: environment=production
  |
  ↓
Scheduled on matching Node
```

If no Node has the required label, the Pod cannot be scheduled.

The Pod remains in:
```
Pending
```

### 5.4 Multiple Labels with NodeSelector

Example:
```
spec:
  nodeSelector:
    environment: production
    disk: ssd
```

This means the Node must have **both** labels:
```
environment=production
disk=ssd
```

For example:
```
node1:
environment=production
disk=ssd
```
Node1 matches.

But:
```
node2:
environment=production
disk=hdd
```
Node2 does not match.

### 5.5 Advantages of NodeSelector

* Very simple to configure.
* Easy to understand.
* Useful for basic scheduling requirements.
* Uses Node labels.
* Good for simple exact-match conditions.

### 5.6 Limitations of NodeSelector

NodeSelector has limited flexibility.

It mainly supports exact key-value matching.

For example, it cannot easily express advanced requirements such as:

```
environment must be production OR staging
```
or:
```
Node should preferably have SSD
```
For these scenarios, Node Affinity is better.

---

## 6. What is Node Affinity?

Node Affinity is an advanced mechanism for controlling where Pods are scheduled.

It provides more flexibility than NodeSelector.

Node Affinity allows us to define:

* Hard requirements
* Soft preferences
* Multiple conditions
* Operators
* More complex scheduling rules

Example:
```
Schedule Pod on production Nodes.
OR
Prefer production Nodes, but allow other Nodes if required.
```


### 6.1 Types of Node Affinity

There are two main types:

**1. Required Node Affinity:**
```
requiredDuringSchedulingIgnoredDuringExecution
```
This is a **hard requirement**.
If no matching Node is available, the Pod will remain Pending.



Full structure:

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: environment
              operator: In
              values:
                - production
```

This means:

> The Pod must be scheduled on a Node where environment=production.


Example:

First label the Node:

```bash
kubectl label nodes node1 environment=production
```

Pod YAML:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-required-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
          - matchExpressions:
              - key: environment
                operator: In
                values:
                  - production

  containers:
    - name: nginx
      image: nginx
```

Apply:

```bash
kubectl apply -f required-affinity.yaml
```

Check:

```bash
kubectl get pods -o wide
```
**What Happens if No Node Matches?**

Suppose the Pod requires:

```text
environment=production
```
But all Nodes have:

```text
environment=development
```
The Pod cannot be scheduled.

Check:
```bash
kubectl get pods
```
Output may show:
```text
NAME                       READY   STATUS    RESTARTS
nginx-required-affinity   0/1     Pending   0
```
To troubleshoot:
```bash
kubectl describe pod nginx-required-affinity
```
You may see a scheduling event indicating that available Nodes do not satisfy the affinity requirement.


**2. Preferred Node Affinity:**
```
preferredDuringSchedulingIgnoredDuringExecution
```

This is a **soft requirement**.

Kubernetes prefers the matching Node, but can use another suitable Node if necessary.

Example:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-preferred-affinity
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
        - weight: 100
          preference:
            matchExpressions:
              - key: environment
                operator: In
                values:
                  - production

  containers:
    - name: nginx
      image: nginx
```
Here Kubernetes prefers:

```text
environment=production
```

But if a production Node is not available, Kubernetes may schedule the Pod on another suitable Node.

**Weight in Preferred Affinity:**

`weight` represents the preference strength.

Range:
```
1 - 100
```
Example:
```
weight: 100
```
means a strong preference.
Example:
```
weight: 20
```
means a weaker preference.

Example:
```
preferredDuringSchedulingIgnoredDuringExecution:
  - weight: 80
    preference:
      matchExpressions:
        - key: disk
          operator: In
          values:
            - ssd

  - weight: 40
    preference:
      matchExpressions:
        - key: environment
          operator: In
          values:
            - production
```
Kubernetes considers these preferences while selecting the best Node.

### 6.2 Important Concept: IgnoredDuringExecution

Both affinity types contain:
```
IgnoredDuringExecution
```

Example:
```
requiredDuringSchedulingIgnoredDuringExecution
```
This means the rule is considered during scheduling.

Suppose:
```
Pod → environment=production
Node → environment=production
```
Pod gets scheduled.

Later, the Node label changes:
```
environment=development
```
Kubernetes does not automatically evict the already-running Pod just because the label changed.

The rule is mainly enforced during scheduling.


### 6.3 Troubleshooting Node Affinity

If a Pod is stuck in Pending:

Step 1. Check Pod: ```kubectl get pods```

Step 2. Describe Pod: ```kubectl describe pod <pod-name>```

Step 3. Check Nodes: ```kubectl get nodes```

Step 4. Check Labels: ```kubectl get nodes --show-labels```

Step 5. Compare Required Label:

For example, Pod requires: ```environment=production```

Check: ```kubectl get nodes -l environment=production```

If no Node is returned, there is no matching Node.

Step 6. Add Correct Label: ```kubectl label node node1 environment=production```

Step 7. Check Pod Again: ```kubectl get pods -o wide```

---
## 3. Useful Kubernetes Commands

Check Nodes: ```kubectl get nodes```

Check Node labels: ```kubectl get nodes --show-labels```

Describe Node: ```kubectl describe node node1```

Add label: ```kubectl label node node1 environment=production```

Remove label: ```kubectl label node node1 environment-```

Check Pods: ```kubectl get pods```

Check Pod placement: ```kubectl get pods -o wide```

Describe Pod: ```kubectl describe pod <pod-name>```

Check Pod YAML: ```kubectl get pod <pod-name> -o yaml```

---

## 4. NodeSelector vs Node Affinity
| Feature                  | NodeSelector | Node Affinity |  
| ------------------------ | ------------ | ------------- |  
| Basic scheduling         | Yes          | Yes           |  
| Exact key-value matching | Yes          | Yes           |  
| Hard requirement         | Yes          | Yes           |  
| Soft preference          | No           | Yes           |  
| Multiple operators       | No           | Yes           |  
| `In`                     | No           | Yes           |  
| `NotIn`                  | No           | Yes           |  
| `Exists`                 | No           | Yes           |  
| `DoesNotExist`           | No           | Yes           |  
| `Gt`                     | No           | Yes           |  
| `Lt`                     | No           | Yes           |  
| Flexibility              | Low          | High          |  
| Complexity               | Simple       | Advanced      |  

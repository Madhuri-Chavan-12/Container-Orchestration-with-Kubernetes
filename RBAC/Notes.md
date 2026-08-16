# Kubernetes RBAC (Role-Based Access Control)

**RBAC (Role-Based Access Control)** is a Kubernetes authorization mechanism used to control **who can perform which actions on which Kubernetes resources**.

In simple words:

> RBAC decides **who can do what on which resource** inside a Kubernetes cluster.

For example:

* Developer → Can view Pods
* Developer → Cannot delete Deployments
* DevOps Engineer → Can create/update Deployments
* Admin → Can manage everything

```
RBAC
 |
 +-- Role
 |     └── Namespace-scoped permissions
 |
 +-- ClusterRole
 |     └── Cluster-wide / reusable permissions
 |
 +-- RoleBinding
 |     └── Binds User/Group/ServiceAccount
 |         to Role/ClusterRole in a namespace
 |
 +-- ClusterRoleBinding
       └── Binds User/Group/ServiceAccount
           to ClusterRole cluster-wide
```

```
WHO?
  User / Group / ServiceAccount

WHAT?
  get / list / watch / create / update / delete

WHICH RESOURCE?
  Pods / Deployments / Services / Secrets

WHERE?
  Namespace or Cluster
```

That is the core of Kubernetes RBAC.
RBAC works using four main objects:
```
Role
ClusterRole
RoleBinding
ClusterRoleBinding
```
---
## Why Do We Need RBAC?

Without proper authorization, users or applications may get more permissions than required.

RBAC helps us implement the **Principle of Least Privilege**.

### Example

Suppose a developer only needs to check Pods.

We should not give:

```
create
update
delete
secrets
nodes
deployments
```

Instead, give only:

```
get
list
watch
pods
```
This reduces the risk of accidental or unauthorized changes.

---

## RBAC Architecture

The basic flow is:

```
User / ServiceAccount
        |
        v
 RoleBinding / ClusterRoleBinding
        |
        v
Role / ClusterRole
        |
        v
Resources + Verbs
```

Example:

```
Developer
    |
    v
RoleBinding
    |
    v
Role
    |
    v
Pods
    |
    +-- get
    +-- list
    +-- watch
```

---

## Important RBAC Objects

**Role:**
A **Role** defines permissions within a **specific namespace**.

Example:

```text
Role
 └── namespace: dev
      └── resources: pods
           ├── get
           ├── list
           └── watch
```
A Role cannot directly provide permissions across the entire cluster.

---

**ClusterRole:**
A **ClusterRole** defines permissions at the **cluster level**.

It can be used for:

* Cluster-wide resources
* Namespace resources across multiple namespaces
* Nodes
* PersistentVolumes
* Namespaces
* Cluster-scoped resources

Example:
```
ClusterRole
 └── nodes
      ├── get
      └── list
```

---

**RoleBinding:**
A **RoleBinding** connects a user, group, or ServiceAccount to a Role or ClusterRole.

It works within a specific namespace.
```
User
 |
 v
RoleBinding
 |
 v
Role
 |
 v
Pod permissions
```
---

**ClusterRoleBinding:**
A **ClusterRoleBinding** connects a user, group, or ServiceAccount to a ClusterRole at the **cluster level**.

Example:
```
User
 |
 v
ClusterRoleBinding
 |
 v
ClusterRole
 |
 v
Cluster-wide permissions
```
---

## Role vs ClusterRole

| Feature             | Role          | ClusterRole                      |  
| ------------------- | ------------- | -------------------------------- |  
| Scope               | Namespace     | Cluster                          |  
| Namespace resources | Yes           | Yes                              |  
| Cluster resources   | No            | Yes                              |  
| Example             | Pods in `dev` | Nodes                            |  
| Used with           | RoleBinding   | ClusterRoleBinding / RoleBinding |  

---

## RoleBinding vs ClusterRoleBinding

| Feature                   | RoleBinding               | ClusterRoleBinding      |  
| ------------------------- | ------------------------- | ----------------------- |  
| Scope                     | Namespace                 | Cluster                 |  
| Can reference Role        | Yes                       | No                      |  
| Can reference ClusterRole | Yes                       | Yes                     |  
| Permissions               | Namespace-specific        | Cluster-wide            |  
| Use case                  | Developer access to `dev` | Admin access to cluster | 
 
---

## Important Point

A **ClusterRole can be referenced by a RoleBinding**.

This is useful when you want to reuse a ClusterRole but restrict its permissions to one namespace.

Example:

```text
ClusterRole
     |
     v
RoleBinding
     |
     v
namespace: dev
```

The permissions are limited to the namespace where the RoleBinding exists.

---
  
## Example Role

Suppose developers should only be able to view Pods in the `dev` namespace.

Create:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: dev
rules:
  - apiGroups: [""]
    resources:
      - pods
    verbs:
      - get
      - list
      - watch
```

This means:
```
Namespace = dev

Resource = pods

Allowed:
    get
    list
    watch

Not allowed:
    create
    update
    delete
```

---

## Understanding apiGroups

Kubernetes resources belong to API groups.

For example:

**Core API group:** Pods, Services, ConfigMaps, Secrets:
```
apiGroups: [""]
```
**Apps API group:**
Deployments, StatefulSets, DaemonSets:

```yaml
apiGroups:
  - apps
```
**RBAC API group:**
Roles, RoleBindings:

```yaml
apiGroups:
  - rbac.authorization.k8s.io
```

Example:

```yaml
rules:
  - apiGroups:
      - apps
    resources:
      - deployments
    verbs:
      - get
      - list
      - watch
```
---

## RoleBinding Example

Create a ServiceAccount:

```
apiVersion: v1
kind: ServiceAccount
metadata:
  name: developer
  namespace: dev
```

Create Role:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: dev
rules:
  - apiGroups: [""]
    resources:
      - pods
    verbs:
      - get
      - list
      - watch
```

Create RoleBinding:

```
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: developer-pod-reader
  namespace: dev
subjects:
  - kind: ServiceAccount
    name: developer
    namespace: dev
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Apply:
```
kubectl apply -f serviceaccount.yaml
kubectl apply -f role.yaml
kubectl apply -f rolebinding.yaml
```
---

## Testing RBAC Permissions

Use:
```
kubectl auth can-i
```
Example:
```
kubectl auth can-i get pods \
  --as=system:serviceaccount:dev:developer \
  -n dev
```
Expected:
```
yes
```

Check delete permission:

```
kubectl auth can-i delete pods \
  --as=system:serviceaccount:dev:developer \
  -n dev
```
Expected:
```
no
```
---

## Check Current User Permissions

```bash
kubectl auth can-i --list
```

This shows the permissions available to the current identity.

Example:

```text
Resources              Non-Resource URLs
pods                   get,list,watch
services               get,list
deployments.apps       get,list
```
---

## ServiceAccount and RBAC

A **ServiceAccount** provides an identity for applications or workloads running inside Kubernetes.

Example:

```
Pod
 |
 v
ServiceAccount
 |
 v
RoleBinding
 |
 v
Role
 |
 v
Allowed Kubernetes API actions
```

Example:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: dev
```

Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  namespace: dev
spec:
  serviceAccountName: app-sa
  containers:
    - name: app
      image: nginx
```
The application can now authenticate to the Kubernetes API using that ServiceAccount, subject to its RBAC permissions.

---
## ClusterRole Example

Allow a user to view Nodes:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
  - apiGroups: [""]
    resources:
      - nodes
    verbs:
      - get
      - list
      - watch
```
Bind it:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: node-reader-binding
subjects:
  - kind: User
    name: developer
    apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```
Apply:
```
kubectl apply -f clusterrole.yaml
kubectl apply -f clusterrolebinding.yaml
```
Test:
```
kubectl auth can-i get nodes --as=developer
```
Expected:

```text
yes
```

---
## Namespace-Level Access

Suppose a developer should have Deployment access only in `dev`.

We can create:
```
Role
+
RoleBinding
```

in the `dev` namespace.
The developer can:

```
kubectl get deployments -n dev
kubectl create deployment nginx --image=nginx -n dev
```
But should not automatically have access to:

```
kubectl get deployments -n prod
```
This is one of the main benefits of namespace-scoped RBAC.

---
## Read-Only Access
A common production requirement is:
> Give developers read-only access to application resources.

Example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: developer-readonly
  namespace: dev
rules:
  - apiGroups: [""]
    resources:
      - pods
      - services
      - configmaps
    verbs:
      - get
      - list
      - watch

  - apiGroups:
      - apps
    resources:
      - deployments
      - replicasets
    verbs:
      - get
      - list
      - watch
```
This allows monitoring/debugging without modification permissions.

---
##  Wildcards in RBAC

You can use:
```yaml
verbs:
  - "*"
```
or:
```
resources:
  - "*"
```
Example:

```
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
```
This gives extremely broad permissions.

### Avoid this in production unless there is a strong reason.

Prefer explicit permissions:
```
resources:
  - pods

verbs:
  - get
  - list
  - watch
```
---
## RBAC Does NOT Deny Explicitly

Kubernetes RBAC is primarily **additive**.

If a user has:
```
Role A:
get pods

Role B:
delete pods
```
The user gets:
```
get pods
delete pods
```

You cannot create another Role saying:

```text
deny delete pods
```
to override the existing permission.

Therefore, carefully control which Roles and RoleBindings are assigned.

---
## RBAC Troubleshooting

When a user gets:

```text
Error from server (Forbidden)
```
**Step 1: Identify the user:**

Determine: ``` Who is making the request? ```

Could be:
```
User
Group
ServiceAccount
```
**Step 2: Check permissions:** ``` kubectl auth can-i get pods -n dev ```

For a ServiceAccount:
```
kubectl auth can-i get pods \
  --as=system:serviceaccount:dev:app-sa \
  -n dev
```
**Step 3: Check Roles:** ```kubectl get roles -n dev ```

Describe: ```kubectl describe role pod-reader -n dev ```

**Step 4: Check RoleBindings:** ```kubectl get rolebindings -n dev ```

  Describe: ```kubectl describe rolebinding developer-pod-reader -n dev ```


**Step 5: Check ClusterRoles:** ```kubectl get clusterroles ```

Describe: ```kubectl describe clusterrole node-reader```

**Step 6: Check ClusterRoleBindings:** ```kubectl get clusterrolebindings```

Describe: ```kubectl describe clusterrolebinding node-reader-binding```

---

## Useful RBAC Commands

List Roles: ```kubectl get roles -A```

List ClusterRoles: ```kubectl get clusterroles```

List RoleBindings: ```kubectl get rolebindings -A```

List ClusterRoleBindings: ```kubectl get clusterrolebindings```

Describe Role: ```kubectl describe role <role-name> -n <namespace>```

Describe ClusterRole: ```kubectl describe clusterrole <clusterrole-name>```

Describe RoleBinding: ```kubectl describe rolebinding <binding-name> -n <namespace>```

Check permission: ```kubectl auth can-i <verb> <resource>```

Example: ```kubectl auth can-i get pods -n dev```

Check all permissions: ```kubectl auth can-i --list```

Check as another user: ```kubectl auth can-i get pods --as=developer -n dev```

Check as ServiceAccount:
```
kubectl auth can-i get pods \
  --as=system:serviceaccount:dev:app-sa \
  -n dev
```

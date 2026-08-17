# Persistent Volume

A **Persistent Volume (PV)** is a piece of storage in a Kubernetes cluster that exists independently of Pods.

Pods are temporary. If a Pod is deleted or recreated, data inside the Pod can be lost.

A Persistent Volume provides **persistent storage** so that application data can survive Pod restarts, rescheduling, and recreation.

### Simple Example
```
Pod
 |
 | uses
 v
PersistentVolumeClaim (PVC)
 |
 | binds to
 v
PersistentVolume (PV)
 |
 | backed by
 v
EBS / EFS / NFS / Cloud Storage
```

## Why do we need Persistent Volume?

Normal container/Pod storage is temporary.

For example:
```
Pod → Container → Application Data
```

If the Pod is deleted:
```
Pod deleted
    ↓
Container storage deleted
    ↓
Application data may be lost
```

With Persistent Volume:
```
Pod
 ↓
PVC
 ↓
PV
 ↓
AWS EBS / EFS
```

If the Pod is deleted, the storage can remain available.

## PV vs PVC

| PV                                          | PVC                               |  
| ------------------------------------------- | --------------------------------- |  
| Actual storage resource                     | Request for storage               |   
| Created by Admin or dynamically provisioned | Created by Developer/User         |  
| Cluster-level resource                      | Namespace-level resource          |  
| Defines capacity and storage type           | Requests capacity and access mode |  
| Example: 20Gi EBS volume                    | Example: request 10Gi             |  

Think of it like:
```
PV  = Available storage
PVC = Request for storage
Pod = Consumer of storage
```

## Important PV Components


### 1. Capacity

Defines how much storage is available.
```
capacity:
  storage: 10Gi
```

### 2. Access Modes

Defines how the volume can be accessed.

Common access modes:
```
ReadWriteOnce (RWO)
ReadOnlyMany (ROX)
ReadWriteMany (RWX)
```

### 3. Reclaim Policy

Defines what happens to the PV after its PVC is deleted.

Common policies:
```
Retain
Delete
```

### 4. StorageClass

Defines how storage should be dynamically provisioned.
```
storageClassName: gp3
```

## Access Modes

### 1. ReadWriteOnce (RWO)

Volume can be mounted as read-write by a single node.
```
Node 1
  |
  +---- Pod
         |
         +---- PV
```

Common example:
```
AWS EBS
```

### 2. ReadOnlyMany (ROX)

Volume can be mounted as read-only by multiple nodes.
```
Node 1 ── Pod ──┐
Node 2 ── Pod ──┼── PV
Node 3 ── Pod ──┘
```

### 3. ReadWriteMany (RWX)

Volume can be mounted as read-write by multiple nodes.
```
Node 1 ── Pod ──┐
Node 2 ── Pod ──┼── PV
Node 3 ── Pod ──┘
```

Common examples:
```
NFS
AWS EFS
```
## PersistentVolume YAML

Example:
```
apiVersion: v1
kind: PersistentVolume

metadata:
  name: my-pv

spec:
  capacity:
    storage: 10Gi

  accessModes:
    - ReadWriteOnce

  persistentVolumeReclaimPolicy: Retain

  hostPath:
    path: /data/myapp
```

Check PV:
```
kubectl get pv
```

Detailed information:
```
kubectl describe pv my-pv
```

##  PersistentVolumeClaim

A PVC requests storage from Kubernetes.

Example:
```
apiVersion: v1
kind: PersistentVolumeClaim

metadata:
  name: my-pvc

spec:
  accessModes:
    - ReadWriteOnce

  resources:
    requests:
      storage: 5Gi
```

Apply:
```
kubectl apply -f pvc.yaml
```

Check:
```
kubectl get pvc
```

Expected:
```
NAME      STATUS   VOLUME   CAPACITY
my-pvc    Bound    my-pv    10Gi
```

## Using PVC in a Pod

Example:
```
apiVersion: v1
kind: Pod

metadata:
  name: nginx

spec:
  containers:
    - name: nginx
      image: nginx

      volumeMounts:
        - mountPath: /usr/share/nginx/html
          name: storage

  volumes:
    - name: storage
      persistentVolumeClaim:
        claimName: my-pvc
```

Here:
```
Pod
 ↓
PVC
 ↓
PV
```

The application writes data to:
```
/usr/share/nginx/html
```

and the data is stored on the persistent volume.

## StorageClass and Dynamic Provisioning

In production, we usually don't manually create PVs.

Instead, Kubernetes can dynamically create PVs using a **StorageClass**.

Example:
```
PVC
 ↓
StorageClass
 ↓
Cloud Storage
 ↓
PV automatically created
```

Example PVC:
```
apiVersion: v1
kind: PersistentVolumeClaim

metadata:
  name: app-pvc

spec:
  storageClassName: gp3

  accessModes:
    - ReadWriteOnce

  resources:
    requests:
      storage: 20Gi
```

When the PVC is created, Kubernetes can dynamically provision the required storage.

## Reclaim Policy

### 1. Retain
```
PVC deleted
   ↓
PV remains
   ↓
Data can be preserved
```

Useful when data is important.

### 2. Delete

```text
PVC deleted
   ↓
PV deleted
   ↓
Underlying storage may also be deleted
```

Useful for temporary or disposable workloads.

## PV Lifecycle

The typical lifecycle is:
```
Available : PV is available and not bound to any PVC.
    ↓
Bound     : PV is successfully bound to a PVC.
    ↓
Released  : PVC has been deleted, but the PV still contains information about the previous claim.
    ↓
Reclaimed : PV is cleaned up or reused according to the reclaim policy.
```

## Important Kubernetes Commands

List PVs: ```kubectl get pv```

List PVCs: ```kubectl get pvc```

List PVCs from all namespaces: ```kubectl get pvc -A```

Describe PV: ```kubectl describe pv <pv-name>```

Describe PVC: ```kubectl describe pvc <pvc-name>```

Check StorageClasses: ```kubectl get storageclass```

Check StorageClass details: ```kubectl describe storageclass <storageclass-name>```

Check Pod volume mounts: ```kubectl describe pod <pod-name>```

## Common PV Problems

### 1. PVC stuck in Pending

Check:
```
kubectl get pvc
kubectl describe pvc <pvc-name>
```

Possible reasons:

* No matching PV
* StorageClass doesn't exist
* Insufficient storage
* Wrong access mode
* CSI driver issue
* Cloud provider storage provisioning failure

### 2. PV stuck in Released

Check:
```
kubectl get pv
kubectl describe pv <pv-name>
```

The previous PVC may have been deleted while the PV retained its data.

### 3. Pod cannot mount volume

Check:
```
kubectl describe pod <pod-name>
```
Look at the **Events** section.

Also check:
```
kubectl get pvc
kubectl get pv
kubectl get storageclass
```

For cloud storage, verify the CSI driver and underlying volume.

## PV in StatefulSet

Stateful applications such as:
```
MySQL
PostgreSQL
MongoDB
Redis
Kafka
```
often require persistent storage.

A StatefulSet can use:
```
volumeClaimTemplates:
```

Example:
```
volumeClaimTemplates:
  - metadata:
      name: data

    spec:
      accessModes:
        - ReadWriteOnce

      resources:
        requests:
          storage: 10Gi
```

For replicas:
```
StatefulSet
   |
   +── Pod-0 ── PVC-0 ── PV-0
   |
   +── Pod-1 ── PVC-1 ── PV-1
   |
   +── Pod-2 ── PVC-2 ── PV-2
```

Each StatefulSet Pod gets its own persistent storage.

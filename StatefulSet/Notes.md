# StatefulSet



A **StatefulSet** is a Kubernetes workload controller used to manage **stateful applications** that require stable identity, stable network names, and persistent storage.

> "StatefulSet is a Kubernetes workload controller used for stateful applications that require stable identity, stable networking, and persistent storage. Unlike Deployment, StatefulSet gives Pods predictable names such as app-0, app-1, and app-2. It commonly uses a Headless Service for stable DNS and volumeClaimTemplates for dedicated persistent storage. StatefulSet also provides ordered Pod creation, scaling, and updates. Typical use cases include databases, Kafka, and other distributed stateful applications."

Unlike a Deployment, StatefulSet Pods have **stable and predictable identities**.

Examples:

* MySQL
* PostgreSQL
* MongoDB
* Kafka
* Elasticsearch
* ZooKeeper

## Why Do We Need StatefulSet?

A normal Deployment creates Pods with dynamically generated names:
```
myapp-7d8f9c6b7d-xk2lm
myapp-7d8f9c6b7d-p9qrs
```

If a Pod is deleted, the replacement Pod gets a different name.

StatefulSet provides predictable Pod identities:
```
mysql-0
mysql-1
mysql-2
```

If `mysql-1` is deleted, Kubernetes recreates:
```
mysql-1
```
So the Pod identity remains stable.

## StatefulSet Key Features

### 1. Stable Pod Identity

Pods have predictable names:
```
app-0
app-1
app-2
```

### 2. Stable Network Identity

Each Pod can have a stable DNS name.

For example:
```
mysql-0.mysql
mysql-1.mysql
mysql-2.mysql
```

### 3. Stable Storage

Each Pod can have its own PersistentVolume.

Example:
```
mysql-0 → mysql-0 storage
mysql-1 → mysql-1 storage
mysql-2 → mysql-2 storage
```

### 4. Ordered Deployment

Pods are normally created sequentially:
```
mysql-0
mysql-1
mysql-2
```

### 5. Ordered Scaling

When scaling from 3 to 4 replicas:
```
mysql-0
mysql-1
mysql-2
mysql-3
```

When scaling down, Pods are normally removed in reverse order:
```
mysql-3
mysql-2
```

## StatefulSet vs Deployment

| Feature          | Deployment                  | StatefulSet           |  
| ---------------- | --------------------------- | --------------------- |  
| Pod identity     | Dynamic                     | Stable                |  
| Pod names        | Random suffix               | Predictable           |  
| Storage          | Usually shared/independent  | Stable per Pod        |  
| Network identity | Usually via Service         | Stable DNS identity   |  
| Pod ordering     | No strict identity ordering | Ordered by default    |  
| Best for         | Stateless applications      | Stateful applications |  
| Example          | Web server                  | Database              |  


## StatefulSet Architecture

Typical architecture:

```
                Kubernetes Cluster
                       |
                 Headless Service
                       |
          -------------------------
          |           |           |
       mysql-0      mysql-1      mysql-2
          |           |           |
       PVC-0        PVC-1        PVC-2
          |           |           |
       PV-0         PV-1         PV-2
```

Each Pod gets its own persistent storage.

## StatefulSet YAML Example

```
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 3

  selector:
    matchLabels:
      app: mysql

  template:
    metadata:
      labels:
        app: mysql

    spec:
      containers:
        - name: mysql
          image: mysql:8.0

          ports:
            - containerPort: 3306

          env:
            - name: MYSQL_ROOT_PASSWORD
              value: rootpassword

          volumeMounts:
            - name: mysql-storage
              mountPath: /var/lib/mysql

  volumeClaimTemplates:
    - metadata:
        name: mysql-storage
      spec:
        accessModes:
          - ReadWriteOnce

        resources:
          requests:
            storage: 5Gi
```

## Headless Service

StatefulSet commonly uses a **Headless Service**.

Example:
```
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  clusterIP: None

  selector:
    app: mysql

  ports:
    - port: 3306
      targetPort: 3306
```

Important:
```
clusterIP: None
```

This makes the Service headless.

A Headless Service does not provide one common virtual IP like a normal ClusterIP Service. Instead, DNS can resolve individual StatefulSet Pods.


## Pod DNS Names

If StatefulSet is named:
```
mysql
```

and Service is:
```
mysql
```

Pods can have DNS names such as:
```
mysql-0.mysql
mysql-1.mysql
mysql-2.mysql
```

Fully qualified DNS names typically follow:
```
<pod-name>.<service-name>.<namespace>.svc.cluster.local
```

Example:
```
mysql-0.mysql.default.svc.cluster.local
```
This stable identity is important for distributed systems and databases.

## volumeClaimTemplates

`volumeClaimTemplates` is one of the most important StatefulSet features.

Example:
```
volumeClaimTemplates:
  - metadata:
      name: mysql-storage
    spec:
      accessModes:
        - ReadWriteOnce

      resources:
        requests:
          storage: 5Gi
```

For 3 replicas, Kubernetes creates separate PVCs:
```
mysql-storage-mysql-0
mysql-storage-mysql-1
mysql-storage-mysql-2
```

Conceptually:

```text
mysql-0 → PVC-0 → PV-0
mysql-1 → PVC-1 → PV-1
mysql-2 → PVC-2 → PV-2
```

## StatefulSet Pod Identity

Suppose we have:
```
replicas: 3
```

Pods will be:
```
mysql-0
mysql-1
mysql-2
```

If `mysql-1` crashes:
```
mysql-1
```

is recreated with the same identity.

This is different from a Deployment where a replacement Pod receives a new generated name.

## StatefulSet Scaling

Scale StatefulSet:
```
kubectl scale statefulset mysql --replicas=5
```

Check Pods:
```
kubectl get pods
```
Expected:
```
mysql-0
mysql-1
mysql-2
mysql-3
mysql-4
```

Scale down:
```
kubectl scale statefulset mysql --replicas=3
```

Normally the highest ordinal Pods are removed first:
```
mysql-4
mysql-3
```

## StatefulSet Commands

Create: ```kubectl apply -f statefulset.yaml```

Check StatefulSets: ```kubectl get statefulset```

or: ```kubectl get sts```

Check Pods: ```kubectl get pods```

Describe StatefulSet: ```kubectl describe statefulset mysql```

Check PVCs: ```kubectl get pvc```

Check PVs: ```kubectl get pv```

Scale: ```kubectl scale sts mysql --replicas=3```

Delete StatefulSet: ```kubectl delete statefulset mysql```


## When Should We Use StatefulSet?

Use StatefulSet when the application needs:

* Persistent data
* Stable Pod identity
* Stable hostname
* Dedicated storage per Pod
* Ordered startup
* Ordered shutdown
* Ordered scaling
* Stateful distributed application behavior

Examples:
```
Database
Message Queue
Distributed Database
Kafka
ZooKeeper
Elasticsearch
```

## When Should We NOT Use StatefulSet?

Do not use StatefulSet just because the application uses a database-like architecture.

If the application is completely stateless, Deployment is usually simpler.

For example:

```text
Frontend
REST API
Web Application
Stateless Microservice
```

Use:

```text
Deployment + Service
```

instead of StatefulSet unless stable identity/storage is actually required.


## StatefulSet Troubleshooting

### 1. Pods are stuck in Pending

Check: ```kubectl describe pod mysql-0```

Check PVC: ```kubectl get pvc```

Check PV: ```kubectl get pv```

Possible reasons:

* No available PV
* StorageClass problem
* Insufficient resources
* Node scheduling issue

### 2. PVC is Pending

Check: ```kubectl describe pvc <pvc-name>```

Check StorageClasses: ```kubectl get storageclass```

Possible reasons:

* StorageClass doesn't exist
* Dynamic provisioning failure
* Cloud storage provisioning problem
* Insufficient storage

### 3. StatefulSet Pod is not starting

Check:
```
kubectl get pods
kubectl describe pod mysql-0
kubectl logs mysql-0
```

Check StatefulSet: ```kubectl describe sts mysql```

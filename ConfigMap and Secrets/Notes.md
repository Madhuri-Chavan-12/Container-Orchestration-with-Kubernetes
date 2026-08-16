# 1. ConfigMap

A **ConfigMap** is a Kubernetes object used to store **non-sensitive configuration data** separately from the application code and container image.
> Do not store passwords, tokens, or private keys in ConfigMaps.

Examples of configuration:

* Application environment
* Database host
* API URLs
* Port numbers
* Feature flags
* Configuration files
* Environment-specific settings


## Flow
```
User Request
     |
     v
Ingress
     |
     v
Service
     |
     v
Pod
     |
     v
Application
     |
     +---- Environment Variables
     |          |
     |          v
     |      ConfigMap
     |
     +---- Sensitive Values
                |
                v
              Secret
```

### Why use ConfigMap?

Instead of hardcoding configuration inside the application or Docker image, we keep it in a ConfigMap.

```text
Application Code
       |
       v
Docker Image
       |
       v
Kubernetes Pod
       |
       +---- ConfigMap ---> Application Configuration
```

---

## Creating a ConfigMap

### 1. Using YAML

Create `configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: production
  APP_PORT: "8080"
  LOG_LEVEL: info
  APP_NAME: DevOpsApp
```

Apply it:
```
kubectl apply -f configmap.yaml
```

Verify:
```
kubectl get configmap
```

Detailed information:
```
kubectl describe configmap app-config
```

### 2. Create ConfigMap from Literal Values:

You can create a ConfigMap directly from the command line.
```
kubectl create configmap app-config \
  --from-literal=APP_ENV=production \
  --from-literal=APP_PORT=8080 \
  --from-literal=LOG_LEVEL=info
```

Check:
```
kubectl get configmap app-config
```


### 3. Create ConfigMap from a File

Suppose we have:
`app.properties`

```
APP_ENV=production
APP_PORT=8080
LOG_LEVEL=info
```
Create ConfigMap:
```
kubectl create configmap app-config \
  --from-file=app.properties
```
Verify:
```
kubectl describe configmap app-config
```

### 4. Using ConfigMap as Environment Variables

Example ConfigMap:
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  APP_ENV: production
  APP_PORT: "8080"
  LOG_LEVEL: info
```
Deployment:
```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: devops-app
spec:
  replicas: 2

  selector:
    matchLabels:
      app: devops-app

  template:
    metadata:
      labels:
        app: devops-app

    spec:
      containers:
        - name: app
          image: devops-app:latest

          env:
            - name: APP_ENV
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: APP_ENV

            - name: APP_PORT
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: APP_PORT

            - name: LOG_LEVEL
              valueFrom:
                configMapKeyRef:
                  name: app-config
                  key: LOG_LEVEL
```
The container receives:
```
APP_ENV=production
APP_PORT=8080
LOG_LEVEL=info
```

### 5. Import All ConfigMap Values Using envFrom

Instead of defining every variable individually, we can import all ConfigMap keys.

```yaml
containers:
  - name: app
    image: devops-app:latest

    envFrom:
      - configMapRef:
          name: app-config
```

All values from `app-config` become environment variables inside the container.

### 6. Using ConfigMap as a Volume

A ConfigMap can also be mounted as files inside a Pod.

Example:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: config-demo
spec:
  containers:
    - name: app
      image: nginx

      volumeMounts:
        - name: config-volume
          mountPath: /etc/config

  volumes:
    - name: config-volume
      configMap:
        name: app-config
```

The ConfigMap values will be available under:

```text
/etc/config/
```

For example:

```bash
ls /etc/config
```

Possible output:

```text
APP_ENV
APP_PORT
LOG_LEVEL
APP_NAME
```

Check a value:

```bash
cat /etc/config/APP_ENV
```

Output:

```text
production
```

### 7. ConfigMap with Configuration File

ConfigMaps are useful when applications require complete configuration files.

Example:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    server {
        listen 80;

        location / {
            proxy_pass http://backend:8080;
        }
    }
```

Mount it:

```yaml
volumes:
  - name: nginx-config
    configMap:
      name: nginx-config
```

Then:

```yaml
volumeMounts:
  - name: nginx-config
    mountPath: /etc/nginx/nginx.conf
    subPath: nginx.conf
```

---

## Important ConfigMap Commands
**List ConfigMaps:**  ```kubectl get configmaps ```

**Get a specific ConfigMap:** ```kubectl get configmap app-config ```

**Display YAML:** ```kubectl get configmap app-config -o yaml ```

**Describe ConfigMap:** ```kubectl describe configmap app-config ```

**Create from literal:** 
```kubectl create configmap app-config \
  --from-literal=APP_ENV=production
```
**Delete ConfigMap:** ```kubectl delete configmap app-config```

---

## Updating a ConfigMap

Edit the ConfigMap: ```kubectl edit configmap app-config```

Or update the YAML file: ```kubectl apply -f configmap.yaml ```

Verify: ```kubectl get configmap app-config -o yaml```

---
 ## Volume Mount

If the ConfigMap is mounted as a volume, Kubernetes can update the mounted files after the ConfigMap changes.

However, the application must be capable of detecting/reloading the changed configuration.

If the application reads the configuration only during startup, a Pod restart may still be required.

---

## ConfigMap Troubleshooting

### Problem 1: ConfigMap not found

Check: ```kubectl get configmap ```

Check namespace: ```kubectl get configmap -n <namespace> ```

Check Pod namespace: ```kubectl get pod <pod-name> -o jsonpath='{.metadata.namespace}' ```

### Problem 2: Environment variable not available

Check the Pod: ```kubectl exec -it <pod-name> -- env ```

Search for the variable: ```kubectl exec -it <pod-name> -- env | grep APP_ENV ```

Check Deployment: ```kubectl get deployment <deployment-name> -o yaml ```


### Problem 3: ConfigMap was updated but application still uses old value

If using environment variables: ```kubectl rollout restart deployment <deployment-name> ```

Then verify: ```kubectl exec -it <pod-name> -- env | grep APP_ENV ```

If using volume mounts, verify the mounted file: ```kubectl exec -it <pod-name> -- cat /etc/config/APP_ENV```

---


# 2. Secrets

A **Secret** in Kubernetes is used to store sensitive information such as:

* Passwords
* API keys
* Tokens
* SSH keys
* Database credentials
* TLS certificates

Secrets are similar to ConfigMaps, but they are intended for **sensitive data**.

---
## Why Use Secrets?

Instead of hardcoding credentials inside application code or Docker images, we store them in Kubernetes Secrets.

**Example:**

```text
Application
    |
    v
Kubernetes Secret
    |
    +-- DB_USERNAME
    +-- DB_PASSWORD
    +-- API_KEY
```
Benefits:

* Keeps sensitive values separate from application code
* Can be injected into Pods as environment variables
* Can be mounted as files
* Can be managed separately from application deployments

> **Important:** Kubernetes Secrets are Base64-encoded by default, not encrypted. Base64 is encoding, not encryption.
---
## Create a Secret

### 1. Using YAML

```yaml
apiVersion: v1
kind: Secret

metadata:
  name: app-secret

type: Opaque

data:
  username: YWRtaW4=
  password: cGFzc3dvcmQ=
```

Create it:
```
kubectl apply -f secret.yaml
```
Check:
```
kubectl get secrets
```


### 2. Base64 Encoding and Decoding

Encode a value: ```echo -n "admin" | base64 ```

Output: ```YWRtaW4= ```

Decode: ```echo -n "YWRtaW4=" | base64 --decode ```

Output: ```admin```

### 3.  Using `stringData`

Instead of manually Base64-encoding values, we can use `stringData`.
```
apiVersion: v1
kind: Secret

metadata:
  name: app-secret

type: Opaque

stringData:
  username: admin
  password: mypassword
```
Apply:
```
kubectl apply -f secret.yaml
```
Kubernetes converts `stringData` into the Secret's encoded `data` representation.

**For writing manifests, `stringData` is usually easier.**

### 4. Use Secret as Environment Variables

Secret:

```yaml
apiVersion: v1
kind: Secret

metadata:
  name: app-secret

type: Opaque

stringData:
  username: admin
  password: mypassword
```

Deployment:

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: app

spec:
  replicas: 2

  selector:
    matchLabels:
      app: app

  template:
    metadata:
      labels:
        app: app

    spec:
      containers:
        - name: app
          image: myapp:1.0

          env:
            - name: DB_USERNAME
              valueFrom:
                secretKeyRef:
                  name: app-secret
                  key: username

            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: app-secret
                  key: password
```

Inside the container:
```
echo $DB_USERNAME
echo $DB_PASSWORD
```

### 5. Use Secret as Environment Variables - All Keys
Instead of defining every key individually:

```yaml
envFrom:
  - secretRef:
      name: app-secret
```
Example:

```yaml
containers:
  - name: app
    image: myapp:1.0

    envFrom:
      - secretRef:
          name: app-secret
```
All keys from the Secret become environment variables.

### 6. Mount Secret as a Volume
Secret:
```
apiVersion: v1
kind: Secret

metadata:
  name: app-secret

type: Opaque

stringData:
  username: admin
  password: mypassword
```
Pod:
```
apiVersion: v1
kind: Pod

metadata:
  name: secret-pod

spec:
  containers:
    - name: app
      image: nginx

      volumeMounts:
        - name: secret-volume
          mountPath: /etc/secrets

  volumes:
    - name: secret-volume
      secret:
        secretName: app-secret
```
Inside the container:
```
ls /etc/secrets
```
Output:
```
username
password
```

Each Secret key becomes a file.

### 7. TLS Secret

TLS Secrets are used for HTTPS certificates.
```
apiVersion: v1
kind: Secret

metadata:
  name: tls-secret

type: kubernetes.io/tls

data:
  tls.crt: <base64-certificate>
  tls.key: <base64-private-key>
```
Commonly used with:
```
Ingress
   |
   v
TLS Secret
   |
   +-- Certificate
   +-- Private Key
```

### 8. Docker Registry Secret

Used when Kubernetes needs credentials to pull a private Docker image.

Create:
```
kubectl create secret docker-registry regcred \
  --docker-server=<registry-server> \
  --docker-username=<username> \
  --docker-password=<password>
```
Use in Pod:

```
spec:
  imagePullSecrets:
    - name: regcred

  containers:
    - name: app
      image: private-registry/myapp:1.0
```

---

## Important Commands

List Secrets: ```kubectl get secrets```

Get a specific Secret:```kubectl get secret app-secret```

View Secret YAML:```kubectl get secret app-secret -o yaml```

Decode a value:
```
kubectl get secret app-secret \
  -o jsonpath="{.data.password}" | base64 --decode
```
Describe Secret:```kubectl describe secret app-secret```

Delete Secret:```kubectl delete secret app-secret```

---

## ConfigMap vs Secret

| ConfigMap                               | Secret                       |  
| --------------------------------------- | ---------------------------- |  
| Stores non-sensitive configuration      | Stores sensitive information |  
| API URLs                                | Passwords                    |  
| Environment names                       | API tokens                   |  
| Port numbers                            | SSH keys                     |  
| Feature flags                           | Database credentials         |  
| Generally stored as plain configuration | Designed for sensitive data  |  

---
## Key Point

**ConfigMap → Non-sensitive configuration**

**Secret → Sensitive configuration**

ConfigMap handles **application configuration**, while Secret handles **sensitive configuration**.



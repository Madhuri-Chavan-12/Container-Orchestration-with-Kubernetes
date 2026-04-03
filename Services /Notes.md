# Kubernetes Services   
A Service in Kubernetes is an abstraction that exposes a set of Pods as a network service.

* **Problem it solves:**

  i. Pods are ephemeral (they die/restart)  
  ii. IP addresses keep changing  
  iii. Service provides a stable IP + DNS name

* **How Service Works**   
    i. Uses labels & selectors  
    ii. Routes traffic to matching Pods


* **There are four main types of Kubernetes Services:**  
**1. ClusterIP:** As the name suggests, With the help of this Service. Kubernetes expose
the service within the cluster which means the service or application won’t be
accessible outside of the cluster.
You can view the Service YML file and see how to use this service.
```
apiVersion: v1
kind: Service
metadata:
name: httpd-service
spec:
ports:
- port: 80
64
targetPort: 80
selector:
name: DevOps
type: ClusterIP
```
**2. NodePort:** This is the next stage of the ClusterIP where you want to deploy your
application or service that should be accessible to the world without any interruption.
In this Service, the node port exposes the service or application through the static
port on each node’s IP.
You can view the Service YML file and see how to use this service.
```
apiVersion: v1
kind: Service
metadata:
name: httpd-service
spec:
ports:
- port: 80
targetPort: 80
selector:
name: DevOps
type: NodePort
```
**3. LoadBalancer:** Load balancers are used to distribute the traffic between the multiple
pods. With the help of this service object, the services will be exposed via the cloud’s
load balancer.
```
You can view the Service YML file and see how to use this service.
apiVersion: v1
kind: Service
metadata:
name: svc-lb
spec:
type: LoadBalancer
selector:
tag: DevOps
ports:
- name: port-lb
protocol: TCP
port: 80
targetPort: 80
```
**4. ExternalName:** This is a similar object service to ClusterIP but it does have DNS
CName instead of Selectors and labels. In other words, services will be mapped to a
DNS name.
You can view the Service YML file and see how to use this service.
```
apiVersion: v1
65
kind: Service
metadata:
name: k8-service
namespace: dev
spec:
type: ExternalName
```

* **Selector**  
  i. Matches Pods using labels  
  ii. Without selector → manual endpoints needed

* **Endpoints**  
i. Actual Pod IPs behind Service  
ii. Auto-managed by Kubernetes

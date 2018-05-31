# 6fusion Kubernetes Collector

## Installation steps

### Server requirements

* A CoreOS operating system (recommended) or any Kubernetes compatible Linux distribution
* A Kubernetes cluster running properly with its containers, binaries, API Server and cAdvisor API

### Local computer requirements

* Latest Kubernetes client `kubectl`
* Have the kubeconfig and all credential files required to access the Kubernetes instance of the server in any folder of your local computer
* Download this repository to your local computer

### Kubernetes configuration values
Go to the folder where you downloaded this repository, edit the file `kubernetes/k8scollector.yaml` and set the following values according to your needs:
(note: all values **must** be base64 encoded; a handy command (if available in your operating system) to encode a value is: `echo YOUR_VALUE | base64`)

**Registry Pull Secret section (registry-pull-secret)**
```
...
data:
  .dockerconfigjson: # Put here the base64 encoded string of your config.json file that contains the credentials to access the docker hub account where the Kubernetes collector private repositories are allocated
...
```
**Kube Secret section (kube-secret)**
```
...
data:
  kube-host: "BASE64_VALUE"        # IP address or domain of the kubernetes API server
  kube-port: "BASE64_VALUE"        # Port of the kubernetes API server
  kube-token: "BASE64_VALUE"       # Token of the kubernetes API server (leave the empty string if no token is to be used)
  kube-use-ssl: "BASE64_VALUE"     # Use 1 for true and 0 for false
  kube-verify-ssl: "BASE64_VALUE"  # Use 1 for true and 0 for false
  cadvisor-host: "BASE64_VALUE"    # IP address or domain of the cluster master cAdvisor host
  cadvisor-port: "BASE64_VALUE"    # cAdvisor port (usually 4194)
...
```
**6fusion On Premise Secret section (on-premise-secret)**
```
...
data:
  host: "BASE64_VALUE"             # IP address or domain of the 6fusion On Premise API server
  port: "BASE64_VALUE"             # Port of the 6fusion On Premise API server
  token: "BASE64_VALUE"            # Token to access the 6fusion On Premise API server (leave the empty string if no token is to be used)
  use-ssl: "BASE64_VALUE"          # Use 1 for true and 0 for false
  verify-ssl: "BASE64_VALUE"       # Use 1 for true and 0 for false
  organization-id: "BASE64_VALUE"  # Organization ID of the one already created in the 6fusion On Premise API server
...
```
**Metrics collector replication controller section (6fusion-k8scollector-metrics)**
```
...
spec:
  replicas: 2  # Set the amount of metrics collectors replicas (default 2)
...
```
Once you have set the above values, save the `kubernetes/k8scollector.yaml` file.

### 6fusion-system namespace installation (optional)
**NOTE:** do this step only if the `6fusion-system` namespace is not present on the Kubernetes cluster that runs on the server

`$ kubectl --kubeconfig=/path/to/kubeconfig_file create -f /path/to/repository/kubernetes/k8scollector-namespace.yaml`

### 6fusion Kubernetes collector installation

`$ kubectl --kubeconfig=/path/to/kubeconfig_file create -f /path/to/repository/kubernetes/k8scollector.yaml`

### 6fusion Kubernetes collector pods information
The 6fusion Kubernetes collector will create the following pods:

##### K8scollector master pod (and service)
This pod named `6fusion-collector-master` will contain the following containers:
* `k8scollector-inventory`: the container that collects the cluster inventory
* `k8scollector-onpremise`: the container that connects to the 6fusion On Premise API to send the cluster data
* `k8scollector-cleancache`: the container that performs a cache db clean of old and unused data in a regular basis
* `k8scollector-mongodb`: the container that provides the cache db for the cluster data

The MongoDB cache in this pod will be exposed through a Kubernetes service called `k8scollector-master` on port `27017` so the separate Metrics container of this collector can connect to it and make the corresponding database operations required for the metrics collection.

##### K8scollector metrics pod
This pod named `6fusion-k8scollector-metrics` will run as a **Replication Controller** so depending on the amount of containers running in the whole cluster, it can be scaled horizontally at any time with the amount of replicas needed to satisfy the metrics collection in a short convenient amount of time. It contains the following container:
* `k8scollector-metrics`: the container that collects the metrics of the machines in the cluster


#### Collector logging development
1. kubeconfig should be pointed at AWS development environment
2. Connect to VPN of AWS cluster
3. run script test/setup_environment.sh for environmental variables 
4. on fresh install collect inventory metrics app/bin/inventory-collector
5. to run the logger metrics app/bin/logger

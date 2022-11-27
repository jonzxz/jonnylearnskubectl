# README

## Repository Structure
1. Startup script is found in `startup.sh`
  - This assumes the setup will be executed in a Linux environment, and it is tested on Ubuntu in WSL2.
1. `html/` contains a single `index.html` file. This directory is to be mounted on `minikube` as a volume, which is then mounted into the Kubernetes deployment.
1. `*.yml` contains a series of resources that are required to spin up the deliverables.


## Startup script
1. The startup script is broken into several sub-sections, pre-requisites, startup and exits
1. The pre-requiste section contains installation commands (commented out) to retrieve the required binaries / services. This includes
  - `kubectl`
  - `minikube`
  - `helm`
  - Adding `prometheus` repo from `helm`
  - Docker is assumed to be already installed, service is running and current user is part of the `docker` group.
1. The Startup section contains shell script commands to 
  - Install `prometheus` from `helm` and establish port forwarding
  - Mount the `html` folder as a `minikube` volume
  - `kubectl apply` to create the deployments / resources
  - Port foward the incremental counter `nginx` service to `localhost:8080`
1. The last section is the Exits, scripts here are mostly for reference since it is to cleanly tear down items / processes created earlier.
  - `kill` the `minikube mount` executed earlier (this should be an auto-exit after the shell is terminated)
  - `kubectl delete` to delete the resources/deployments
  - `helm delete` to release `prometheus`

## Deliverables

### Display first name via environment variable
1. Environment variable `FIRST_NAME` set to `nginx` pods
```env
root@nginx-counter-5c49999f68-rd779:/# env
... truncated
HOSTNAME=nginx-counter-5c49999f68-rd779
NGINX_VERSION=1.23.2
NGINX_COUNTER_SERVICE_PORT_80_TCP_PORT=80
FIRST_NAME=JonathanKerk
NGINX_COUNTER_SERVICE_PORT_80_TCP_ADDR=10.102.157.122
NGINX_COUNTER_SERVICE_SERVICE_PORT_HTTP=80
```
1. Environment variable added to static `nginx` site using
  1. `nginx-conf/default` template mounted as `/tmp/nginx/conf.d/default`
  1. mounted `default` contains default configuration for routing rules to site
  1. contains `nginx` module `sub_filter` to replace text (like `sed`) with environment variable `$FIRST_NAME` passed into container from template
1. entry point of `nginx` container overridden with `envsubst` to read template and inject it into `/etc/nginx/conf.d/default` 
1. [Screencap proof](screencaps/static_site_env_var_display.png)

### Ensuring nginx service (+- counter) is able to connect to MySQL pod
1. Tested connection via `apt-get update` and `apt-get install inetutils-ping` to install basic net utils
1. Retrieved IP address of `mysql` pod via `kubectl get pod -l app=mysql -o jsonpath="{.items[0].status.podIP}"`
1. `ping` result of line above 
  ```
  root@nginx-counter-7889c4cbc8-wz77g:/# ping 172.17.0.5
  PING 172.17.0.5 (172.17.0.5): 56 data bytes
  64 bytes from 172.17.0.5: icmp_seq=0 ttl=64 time=0.147 ms
  64 bytes from 172.17.0.5: icmp_seq=1 ttl=64 time=0.060 ms
  --- 172.17.0.5 ping statistics ---
  ```
1. [Screencap proof](screencaps/nginx_mysql_connectivity.png)

### Monitor resources using Prometheus and Grafana
1. Not knowledgeable in Grafana and Prometheus
1. Service discovery -> `kubernetes-pods` shows the `nginx` pods
1. Simple query on `kube_pod_container_status_running` returns results
```code
kube_pod_container_status_running{namespace="default", pod="nginx-counter-5c49999f68-kncc9"} or kube_pod_container_status_running{namespace="default", pod="nginx-counter-5c49999f68-m84kq"}

kube_pod_container_status_running{app_kubernetes_io_component="metrics", app_kubernetes_io_instance="prometheus-1669374032", app_kubernetes_io_managed_by="Helm", app_kubernetes_io_name="kube-state-metrics", app_kubernetes_io_part_of="kube-state-metrics", app_kubernetes_io_version="2.6.0", container="nginx-counter", helm_sh_chart="kube-state-metrics-4.22.3", instance="172.17.0.4:8080", job="kubernetes-service-endpoints", namespace="default", node="minikube", pod="nginx-counter-5c49999f68-kncc9", service="prometheus-1669374032-kube-state-metrics", uid="78028aa2-df96-488e-87e5-a099eb8b099c"}
1
kube_pod_container_status_running{app_kubernetes_io_component="metrics", app_kubernetes_io_instance="prometheus-1669374032", app_kubernetes_io_managed_by="Helm", app_kubernetes_io_name="kube-state-metrics", app_kubernetes_io_part_of="kube-state-metrics", app_kubernetes_io_version="2.6.0", container="nginx-counter", helm_sh_chart="kube-state-metrics-4.22.3", instance="172.17.0.4:8080", job="kubernetes-service-endpoints", namespace="default", node="minikube", pod="nginx-counter-5c49999f68-m84kq", service="prometheus-1669374032-kube-state-metrics", uid="2a3ac1ed-eed9-4c51-912f-251229998df4"}
```
1. [Screencap proof](screencaps/prometheus_monitoring_output.png)


### Create table in MySQL
1. Table is created using a `ConfigMap` with data to create a new database `hello` and create a table called `world`. Dummy data is also inserted
1. Table is created via `volumeMount` to modify the container entry point
1. Verified with the following steps
  - `kubectl exec -it $(kubectl get pods --namespace default -l "app=mysql" -o jsonpath="{.items[0].metadata.name}") -- bash`
  - `mysql -u root -p`
  - `use hello`, `select * from hello`
  ```sql
  mysql> use hello;
  Database changed
  mysql> select * from hello;
  +------+-------------+
  | id   | title       |
  +------+-------------+
  |    1 | hello world |
  +------+-------------+
  1 row in set (0.00 sec)
  ```
1. [Screencap proof](screencaps/mysql_init_data.png)

### Assumptions made
1. Cluster will be executed in a Linux environment
1. Docker is already running as a service and `whoami` is part of the `docker` group
1. Database is treated as a pure POC database. While the password for the database is passed in as a `Secret`, the actual value is in plain text within the configuration
1. Hiring team's expectations on the lower end, this is my first time using Kubernetes, Grafana and Prometheus :(


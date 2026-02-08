# Day 12 - Descomplicando os ServiceMonitors, PodMonitors e os Alertas no Kubernetes

## ServiceMonitors

ServiceMonitors são recursos do Prometheus Operator no Kubernetes usados para descobrir e monitorar serviços automaticamente. 
Eles definem como o Prometheus deve encontrar endpoints de serviços, coletar métricas e aplicar seletores de labels, facilitando a integração e o monitoramento de aplicações sem necessidade de configuração manual dos targets.

O ServiceMonitor define:
 - Quais serviços devem ser monitorados, usando seletores de labels.
 - Quais endpoints e portas devem ser acessados para coleta de métricas.
 - Intervalo de scrape (frequência de coleta das métricas).
 - Esquema de autenticação e TLS, se necessário.
 - Labels e parâmetros adicionais para customizar a coleta.

**Exemplo:**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  annotations:
  labels:
    app.kubernetes.io/component: prometheus
    app.kubernetes.io/instance: k8s
    app.kubernetes.io/name: prometheus
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 2.41.0
  name: prometheus-k8s
  namespace: monitoring
spec:
  endpoints:
  - interval: 30s
    port: web
  - interval: 30s
    port: reloader-web
  selector:
    matchLabels:
      app.kubernetes.io/component: prometheus
      app.kubernetes.io/instance: k8s
      app.kubernetes.io/name: prometheus
      app.kubernetes.io/part-of: kube-prometheus
```

Este ServiceMonitor monitora os serviços que possuem as labels:

  app.kubernetes.io/component: prometheus
  app.kubernetes.io/instance: k8s
  app.kubernetes.io/name: prometheus
  app.kubernetes.io/part-of: kube-prometheus

E irá monitorar as portas web e reloader-web a cada 30s.

**Visualizar Customer Resource Definitions**

```bash
$ kubectl get customresourcedefinitions.apiextensions.k8s.io             
NAME                                           CREATED AT
accesscontrolpolicies.hub.traefik.io           2026-01-04T19:33:24Z
aiservices.hub.traefik.io                      2026-01-04T19:33:24Z
alertmanagerconfigs.monitoring.coreos.com      2026-01-28T18:06:47Z
alertmanagers.monitoring.coreos.com            2026-01-28T18:06:48Z
...
podmonitors.monitoring.coreos.com              2026-01-28T18:06:48Z
probes.monitoring.coreos.com                   2026-01-28T18:06:48Z
prometheusagents.monitoring.coreos.com         2026-01-28T18:06:48Z
prometheuses.monitoring.coreos.com             2026-01-28T18:06:48Z
prometheusrules.monitoring.coreos.com          2026-01-28T18:06:48Z
...
servicemonitors.monitoring.coreos.com          2026-01-28T18:06:48Z
thanosrulers.monitoring.coreos.com             2026-01-28T18:06:48Z
```

**Listar Service Monitors**

```bash
$ kubectl get servicemonitors.monitoring.coreos.com                     
No resources found in default namespace.
$ kubectl get servicemonitors.monitoring.coreos.com -A
NAMESPACE    NAME                      AGE
monitoring   alertmanager-main         7d
monitoring   blackbox-exporter         7d
monitoring   coredns                   7d
monitoring   grafana                   7d
monitoring   kube-apiserver            7d
monitoring   kube-controller-manager   7d
monitoring   kube-scheduler            7d
monitoring   kube-state-metrics        7d
monitoring   kubelet                   7d
monitoring   node-exporter             7d
monitoring   prometheus-adapter        7d
monitoring   prometheus-k8s            7d
monitoring   prometheus-operator       7d
```


## PodMonitors


**Criar Pod com Metrics**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-podmetrics
  labels:
    app: nginx-podmetrics
spec:
  containers:
  - name: nginx-podmetrics
    image: nginx:latest
    ports:
    - containerPort: 80
      name: http
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
    volumeMounts:
    - name: nginx-metrics-config
      mountPath: /etc/nginx/conf.d/default.conf
      subPath: nginx.conf
  - name: nginx-exporter
    image: nginx/nginx-prometheus-exporter:1.5
    args:
    - '-nginx.scrape-uri=http://localhost/metrics'
    ports:
    - containerPort: 9113
      name: metrics
    resources:
      requests:
        cpu: "0.05"
        memory: "64Mi"
      limits:
        cpu: "0.3"
        memory: "128Mi"
  volumes:
  - configMap:
      defaultMode: 420
      name: nginx-metrics-config
    name: nginx-metrics-config

```


**Criar Pod Monitor**


**Criar configmap de configuração para o nosso pod-metrics**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-podmetrics-config
  namespace: default
  labels:
    app: nginx-podmetrics
  annotations:
    description: Configuração customizada do nginx

data:
  nginx.conf: |
    server {
        listen       80;
        server_name  localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }

        location /metrics {
            stub_status on;
            access_log  off;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }

```

**Pod Metrics**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-podmetrics
  labels:
    app: nginx-podmetrics
spec:
  containers:
  - name: nginx-podmetrics
    image: nginx:latest
    ports:
    - containerPort: 80
      name: http
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
    volumeMounts:
    - name: nginx-podmetrics-config
      mountPath: /etc/nginx/conf.d/default.conf
      subPath: nginx.conf
  - name: nginx-podmetrics-exporter
    image: nginx/nginx-prometheus-exporter:1.5
    args:
    - '-nginx.scrape-uri=http://localhost/metrics'
    ports:
    - containerPort: 9113
      name: metrics
    resources:
      requests:
        cpu: "0.05"
        memory: "64Mi"
      limits:
        cpu: "0.3"
        memory: "128Mi"
  volumes:
  - configMap:
      defaultMode: 420
      name: nginx-podmetrics-config
    name: nginx-podmetrics-config
```


**Pod Monitor**

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PodMonitor
metadata:
  name: nginx-podmonitor
  labels:
    app: nginx-podmonitor
spec:
  namespaceSelector:
    matchNames:
    - default
  selector:
    matchLabels:
      app: nginx-podmetrics
  podMetricsEndpoints:
    - interval: 15s
      targetPort: 9113
      path: /metrics

```


**Aplicar tudo no nosso cluster**

```bash
$ kubectl apply -f nginx-podmetrics-configmap.yaml 
configmap/nginx-podmetrics-config created
$
$ kubectl apply -f nginx-podmetrics.yaml 
pod/nginx-podmetrics created
$
$ $ kubectl apply -f nginx-podmonitor.yaml      
podmonitor.monitoring.coreos.com/nginx-podmonitor created
$
```


**Validar**

```bash
$ kubectl get podmonitors.monitoring.coreos.com     
NAME               AGE
nginx-podmonitor   31s

$ kubectl describe podmonitors.monitoring.coreos.com
Name:         nginx-podmonitor
Namespace:    default
Labels:       app=nginx-podmonitor
Annotations:  <none>
API Version:  monitoring.coreos.com/v1
Kind:         PodMonitor
Metadata:
  Creation Timestamp:  2026-02-08T08:49:55Z
  Generation:          1
  Resource Version:    7544094
  UID:                 33f19436-51c3-4c37-80c0-8a6e2e7d909a
Spec:
  Namespace Selector:
    Match Names:
      default
  Pod Metrics Endpoints:
    Interval:     15s
    Path:         /metrics
    Target Port:  9113
  Selector:
    Match Labels:
      App:  nginx-podmetrics
```


**Fazer port forward do prometheus**

```bash
$ kubectl port-forward -n monitoring svc/prometheus-k8s 39090:9090
```


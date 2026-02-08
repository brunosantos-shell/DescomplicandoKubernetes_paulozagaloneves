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
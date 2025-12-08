# Daemonset

## Create node-exporter 

Criar um pod com node-exporter, em cada nó do cluster, para exportar as métricas do nó.

**Arquivo:** k8s-node-exporter-daemonset.yaml

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter-daemonset
  labels:
    app: node-exporter-daemonset
spec:
  selector:
    matchLabels:
      app: node-exporter-daemonset
  template:
    metadata:
      labels:
        app: node-exporter-daemonset
    spec:
      hostNetwork: true     # Usar a rede do host (cuidado com conflitos de porta)
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.10.2
        ports:
        - containerPort: 9100
          hostPort: 9100       # Mapeia a porta 9100 do container para a porta 9100 do host
        resources:
          requests:
            cpu: "0.10"
            memory: "128Mi"
          limits:
            cpu: "0.20"
            memory: "256Mi"
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
      volumes:
      - name: proc
        hostPath: 
          path: /proc      # Monta o sistema de arquivos /proc do host
      - name: sys
        hostPath:
          path: /sys       # Monta o sistema de arquivos /sys do host 

```

```bash
$ k apply -f k8s-prometheus-daemonset.yaml
daemonset.apps/node-exporter-daemonset created
```
## Desafio Aula 2

### Parte 1:

Criar namespace treinamento-ch2

Ficheiro k8s-treinamento-namespace.yaml

```YAML
apiVersion: v1
kind: Namespace
metadata:
  name: treinamento-ch2
```

```bash
kubectl apply -f k8s-treinamento-namespace.yaml
```

### Parte 2: O Teste de Estresse (O Erro Esperado)

Ficheiro k8s-podfaminto.yaml

```YAML
apiVersion: v1
kind: Pod
metadata:
  name: pod-faminto
  namespace: treinamento-ch2
spec:
  containers:
    - name: stress-container
      image: polinux/stress
      command: ["stress", "--vm", "1", "--vm-bytes", "250M", "--vm-hang", "1"]
      resources:
        requests:
          memory: "100Mi"
        limits:
          memory: "200Mi"
```

```bash
kubectl apply -f k8s-podfaminto.yaml
```

```bash
kubectl get pod -n treinamento-ch2 -w
NAME          READY   STATUS             RESTARTS      AGE
pod-faminto   0/1     CrashLoopBackOff   6 (89s ago)   7m26s
pod-faminto   0/1     OOMKilled          7 (5m4s ago)   11m
pod-faminto   0/1     CrashLoopBackOff   7 (13s ago)    11m
```

```bash
kubectl describe pod pod-faminto -n treinamento-ch2

Name:             pod-faminto
Namespace:        treinamento-ch2
Priority:         0
Service Account:  default
Node:             aks-agentpool-31830996-vmss000000/************
Start Time:       Wed, 26 Nov 2025 11:35:57 +0000
Labels:           <none>
Annotations:      <none>
Status:           Running
IP:               ********
IPs:
  IP:  *********
Containers:
  stress-container:
    Container ID:  containerd://143f267ca7ec96e1604fdc98e56f2ebfff3d8e8da80eac2c1ce6c5ec005b0fe8
    Image:         polinux/stress
    Image ID:      docker.io/polinux/stress@sha256:b6144f84f9c15dac80deb48d3a646b55c7043ab1d83ea0a697c09097aaad21aa
    Port:          <none>
    Host Port:     <none>
    Command:
      stress
      --vm
      1
      --vm-bytes
      250M
      --vm-hang
      1
    State:          Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Wed, 26 Nov 2025 11:39:09 +0000
      Finished:     Wed, 26 Nov 2025 11:39:09 +0000
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Wed, 26 Nov 2025 11:37:34 +0000
      Finished:     Wed, 26 Nov 2025 11:37:34 +0000
    Ready:          False
    Restart Count:  5
    Limits:
      memory:  200Mi
    Requests:
      memory:     100Mi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-92xf2 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True
  Initialized                 True
  Ready                       False
  ContainersReady             False
  PodScheduled                True
Volumes:
  kube-api-access-92xf2:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/memory-pressure:NoSchedule op=Exists
                             node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason     Age                  From               Message
  ----     ------     ----                 ----               -------
  Normal   Scheduled  3m14s                default-scheduler  Successfully assigned treinamento-ch2/pod-faminto to aks-agentpool-31830996-vmss000000
  Normal   Pulled     3m12s                kubelet            Successfully pulled image "polinux/stress" in 1.817s (1.817s including waiting). Image size: 4041495 bytes.
  Normal   Pulled     3m11s                kubelet            Successfully pulled image "polinux/stress" in 583ms (583ms including waiting). Image size: 4041495 bytes.
  Normal   Pulled     2m56s                kubelet            Successfully pulled image "polinux/stress" in 611ms (611ms including waiting). Image size: 4041495 bytes.
  Normal   Pulled     2m26s                kubelet            Successfully pulled image "polinux/stress" in 607ms (607ms including waiting). Image size: 4041495 bytes.
  Normal   Pulled     97s                  kubelet            Successfully pulled image "polinux/stress" in 593ms (593ms including waiting). Image size: 4041495 bytes.
  Normal   Pulling    3s (x6 over 3m14s)   kubelet            Pulling image "polinux/stress"
  Normal   Created    2s (x6 over 3m12s)   kubelet            Created container: stress-container
  Normal   Started    2s (x6 over 3m12s)   kubelet            Started container stress-container
  Normal   Pulled     2s                   kubelet            Successfully pulled image "polinux/stress" in 610ms (610ms including waiting). Image size: 4041495 bytes.
  Warning  BackOff    1s (x16 over 3m10s)  kubelet            Back-off restarting failed container stress-container in pod pod-faminto_treinamento-ch2(a9984cf4-f821-4c63-a055-5d712084c1f8)
```

Razão da falha "OOMKilled"

```bash
State:          Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Wed, 26 Nov 2025 11:39:09 +0000
      Finished:     Wed, 26 Nov 2025 11:39:09 +0000
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Wed, 26 Nov 2025 11:37:34 +0000
      Finished:     Wed, 26 Nov 2025 11:37:34 +0000
```

Motivo da falha
O OOMKilled mostra que o container tentou usar mais meória do que o limite definido ("200 Mi")


Referência:
 https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/
 https://learn.microsoft.com/pt-br/troubleshoot/azure/azure-kubernetes/availability-performance/troubleshoot-oomkilled-aks-clusters


 ### Parte 3: A Correção

Criar ficheiro k8s-podcomportado.yaml

```YAML
apiVersion: v1
kind: Pod
metadata:
  name: pod-faminto
  namespace: treinamento-ch2
spec:
  containers:
    - name: stress-container
      image: polinux/stress
      command: ["stress", "--vm", "1", "--vm-bytes", "250M", "--vm-hang", "1"]
      resources:
        requests:
          memory: "100Mi"
        limits:
          memory: "275Mi"
```

Aplicar as alterações

 ```bash
 kubectl apply -f .\k8s-podcomportado.yaml
The Pod "pod-faminto" is invalid: spec: Forbidden: pod updates may not change fields other than `spec.containers[*].image`,`spec.initContainers[*].image`,`spec.activeDeadlineSeconds`,`spec.tolerations` (only additions to existing tolerations),`spec.terminationGracePeriodSeconds` (allow it to be set to 1 if it was previously negative)
  core.PodSpec{
        Volumes:        {{Name: "kube-api-access-92xf2", VolumeSource: {Projected: &{Sources: {{ServiceAccountToken: &{ExpirationSeconds: 3607, Path: "token"}}, {ConfigMap: &{LocalObjectReference: {Name: "kube-root-ca.crt"}, Items: {{Key: "ca.crt", Path: "ca.crt"}}}}, {DownwardAPI: &{Items: {{Path: "namespace", FieldRef: &{APIVersion: "v1", FieldPath: "metadata.namespace"}}}}}}, DefaultMode: &420}}}},
        InitContainers: nil,
        Containers: []core.Container{
                {
                        ... // 6 identical fields
                        EnvFrom: nil,
                        Env:     nil,
                        Resources: core.ResourceRequirements{
-                               Limits: core.ResourceList{s"memory": {i: resource.int64Amount{value: 209715200}, Format: "BinarySI"}},
+                               Limits: core.ResourceList{
+                                       s"memory": {i: resource.int64Amount{value: 314572800}, s: "300Mi", Format: "BinarySI"},
+                               },
                                Requests: {s"memory": {i: {...}, s: "100Mi", Format: "BinarySI"}},
                                Claims:   nil,
                        },
                        ResizePolicy:  nil,
                        RestartPolicy: nil,
                        ... // 13 identical fields
                },
        },
        EphemeralContainers: nil,
        RestartPolicy:       "Always",
        ... // 29 identical fields
  }
 ```

 Ups... não permite alterar recursos de um pod.

Vamos apagar então o faminto
 ```bash
kubectl delete -f .\k8s-podfaminto.yaml
pod "pod-faminto" deleted from treinamento-ch2 namespace
 ```

E agora criar o comportado

```bash
 kubectl apply -f .\k8s-podcomportado.yaml
pod/pod-faminto created
```

E validar

```bash
kubectl get pod -n treinamento-ch2 -w
NAME          READY   STATUS    RESTARTS   AGE
pod-faminto   1/1     Running   0          11s
```
Agora é que reparei que usei o mesmo nome.

Vou trocar o nome do pod 

Editar ficheiro k8s-podcomportado.yaml

```YAML
apiVersion: v1
kind: Pod
metadata:
  name: pod-comportado
  namespace: treinamento-ch2
spec:
  containers:
    - name: stress-container
      image: polinux/stress
      command: ["stress", "--vm", "1", "--vm-bytes", "250M", "--vm-hang", "1"]
      resources:
        requests:
          memory: "100Mi"
        limits:
          memory: "275Mi"
```

Apagar faminto de novo

```bash
kubectl delete -f .\k8s-podfaminto.yaml
pod "pod-faminto" deleted from treinamento-ch2 namespace
```

Criar pod comportado com nome correto

```bash
kubectl apply -f .\k8s-podcomportado.yaml
pod/pod-comportado created
```

Criar pod faminto de novo

```bash
kubectl apply -f .\k8s-podfaminto.yaml
pod/pod-faminto created
```

Validar pods 

```bash
kubectl get pod -n treinamento-ch2 -w
NAME             READY   STATUS      RESTARTS      AGE
pod-comportado   1/1     Running     0             104s
pod-faminto      0/1     OOMKilled   1 (12s ago)   13s
pod-faminto      0/1     CrashLoopBackOff   1 (12s ago)   14s
pod-faminto      0/1     OOMKilled          2 (14s ago)   16s
pod-faminto      0/1     CrashLoopBackOff   2 (12s ago)   27s
pod-faminto      0/1     OOMKilled          3 (29s ago)   44s
pod-faminto      0/1     CrashLoopBackOff   3 (14s ago)   57s
pod-faminto      1/1     Running            4 (49s ago)   92s
pod-faminto      0/1     OOMKilled          4 (50s ago)   93s
pod-faminto      0/1     CrashLoopBackOff   4 (11s ago)   103s
pod-faminto      0/1     OOMKilled          5 (89s ago)   3m1s
```

A pressa é inimiga da perfeição! A pressão faz-nos cometer erros!



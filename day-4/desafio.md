# Desafio 2025-12-04

Startup probe → roda apenas no início, pra garantir que a aplicação conseguiu subir corretamente.

Readiness probe e Liveness probe → ficam rodando em loop depois que o container está no ar.

Readiness checa se pode receber requisições.

Liveness checa se ainda está saudável — se não estiver, o Kubernetes reinicia o container.


```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: meu-servico
  namespace: producao
spec:
  replicas: 3
  selector:
    matchLabels:
      app: meu-servico
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  # inicia configuracao do pod
  template:
    metadata:
      labels:
        app: meu-servico
        version: "v2-problematica"
    spec:
      containers:
      - name: meu-servico-container
        image: linuxtips/memory-eater:0.2
        # Simulando limites muito baixos para forçar OOMKill
        resources:
          limits:
            memory: "32Mi"
        # Sem probes = Kubernetes operando às cegas
```
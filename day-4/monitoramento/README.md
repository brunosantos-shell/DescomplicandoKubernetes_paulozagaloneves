# Monitoring

## Criar namespace monitoramento

Vamos manter todos os recursos de monitoramento dentro do namespace **monitoramento**

```bash
$ kubectl apply -f k8s-namespace.yaml
```

## Instalar Node Exporter como Daemonset

```bash
$ kubectl apply -f k8s-node-exporter-daemonset.yaml
```

## Instalar e Configurar Prometheus

```bash
$ kubectl apply -f k8s-prometheus-mon.yaml
```

## Instalar e Configurar Grafana

```bash
$ kubectl apply -f k8s-grafana-mon.yaml
```

## Aceder ao Grafana

### port-forwarding 

```bash
$ kubectl port-forward svc/grafana -n monitoring 3000:3000
```

### Acesso e Configuração

Aceder:

http://localhost:3000

**User:** admin

**Senha:** admin


### Adicionar Dashboard

Adicionar o Dashboard Node Exporter Full

**Dashboards** => **New** => **Import** 

Find and import dashboards for common applications at grafana.com/dashboards

**1860**                    

**Load** => **Import**
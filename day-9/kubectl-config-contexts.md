# Tutorial: Gerenciando Contextos com `kubectl config`

O comando `kubectl config` é utilizado para gerenciar os arquivos de configuração do Kubernetes (kubeconfig), permitindo alternar entre diferentes clusters, usuários e namespaces.

## 1. Visualizar a Configuração Atual
Para ver o conteúdo completo do seu arquivo kubeconfig:
```bash
kubectl config view
```

## 2. Listar Contextos
Um contexto é a combinação de um cluster, um usuário e um namespace. Para listar todos os contextos disponíveis:
```bash
kubectl config get-contexts
```

## 3. Identificar o Contexto Atual
Para saber em qual contexto você está operando no momento:
```bash
kubectl config current-context
```

## 4. Alternar entre Contextos
Para mudar para um contexto específico:
```bash
kubectl config use-context <nome-do-contexto>
```

## 5. Criar ou Modificar um Contexto
Para criar um novo contexto vinculando um cluster e um usuário existentes:
```bash
kubectl config set-context <nome-do-contexto> --cluster=<nome-do-cluster> --user=<nome-do-usuario> --namespace=<nome-do-namespace>
```

## 6. Definir o Namespace Padrão para o Contexto Atual
Para evitar digitar `--namespace` em todos os comandos:
```bash
kubectl config set-context --current --namespace=<nome-do-namespace>
```

## 7. Remover um Contexto
Para deletar um contexto específico do seu kubeconfig:
```bash
kubectl config delete-context <nome-do-contexto>
```

## 8. Configurar Clusters e Credenciais
Para adicionar manualmente um cluster ou um usuário:
```bash
# Adicionar Cluster
kubectl config set-cluster <nome-do-cluster> --server=https://<ip-do-cluster>:6443

# Adicionar Usuário (Token)
kubectl config set-credentials <nome-do-usuario> --token=<seu-token>
```

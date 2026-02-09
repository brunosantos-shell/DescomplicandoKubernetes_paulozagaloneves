# ADR-001 — Arquitetura de Segurança, Observabilidade e Resiliência – CashFlow API

**Status:** Proposto  
**Data:** 08 de Fevereiro de 2026  

## Contexto
Necessidade de implantar a **CashFlow API** num cluster Kubernetes, atendendo a requisitos rigorosos de conformidade bancária e estabilidade.

---

## Critérios para Aceitação

Para que esta ADR passe do estado **"Proposto"** para **"Aceite"**, os seguintes critérios precisam ser formalmente verificados e aprovados pela equipa de **Arquitetura / Segurança**:

### Validação Técnica
- Confirmação de que a arquitetura funciona corretamente nos ambientes **DEV** ou **QA**.

### Conformidade do CI/CD
- Verificação de que o pipeline CI/CD cumpre os requisitos de segurança e integridade:
  - Scan de imagem sem vulnerabilidades **Critical** ou **High**
  - Assinatura da imagem com **Cosign**

### Implementação no Cluster
- Garantia de que o deploy utiliza:
  - **Gateway API**
  - Certificados **TLS automáticos**

### Monitorização
- Confirmação de que o endpoint `/metrics` expõe métricas
- Recolha de métricas via **ServiceMonitor**

---

## 1. Segurança da Cadeia de Suprimentos

### 1.1 Imagem Base — Distroless

**Decisão:**  
Utilizar imagens **Distroless** (ex.: *Google Distroless*).

**Justificação:**  
Ao contrário de imagens baseadas em distribuições generalistas como **Ubuntu** ou **Alpine**, as imagens Distroless incluem apenas a aplicação e as suas dependências de runtime. Não disponibilizam gestores de pacotes (`apt`, `apk`) nem shells (`bash`, `sh`), reduzindo significativamente a superfície de ataque e eliminando a maioria das CVEs comuns do sistema operativo.

**Alternativa:**  
Podem ser utilizadas imagens **Wolfi**, fornecidas pela **Chainguard**, uma distribuição *distroless-like* focada em segurança e *supply chain integrity*, que oferece imagens com ausência de vulnerabilidades conhecidas acima de severidades acordadas contratualmente, mediante licenciamento.

---

### 1.2 Ferramentas de Pipeline (CI/CD) — Trivy

**Decisão:**  
Implementar o **Trivy** no pipeline de CI para escaneamento de imagens.

**Justificação:**  
O Trivy é um scanner de código aberto abrangente que, além de vulnerabilidades de imagens, verifica repositórios de código, **IaC** (Terraform, etc.) e manifestos Kubernetes.

Cada nova versão da API será sempre escaneada, garantindo a ausência de vulnerabilidades acima de um determinado nível de severidade. Caso sejam detetadas novas vulnerabilidades, a equipa será notificada de imediato.

---

### 1.3 Integridade da Imagem — Cosign (Sigstore)

**Decisão:**  
Utilizar o **Cosign** para assinar as imagens após o build.

**Justificação:**  
Garante que apenas imagens assinadas pela chave privada da organização sejam executadas no cluster, prevenindo ataques *man-in-the-middle* no registo de imagens. No cluster, será utilizado um **Admission Controller** (ex.: Kyverno ou OPA Gatekeeper) para validação das assinaturas.

---

## 2. Estratégia de Acesso (Network & TLS)

### 2.1 Exposição do Serviço — Gateway API com NGINX Gateway Fabric

**Decisão:**  
Utilizar a **Gateway API** com **NGINX Gateway Fabric**, em conjunto com Services do tipo **ClusterIP**.

**Justificação:**  
O Ingress encontra-se em modo de manutenção, sendo a **Gateway API** o modelo recomendado para novas implementações. O NGINX Gateway Fabric é uma escolha natural para organizações que já utilizavam o NGINX Ingress Controller.

O Gateway será o *entrypoint* do tráfego externo, encaminhando as requisições para os Services da API através de regras centralizadas de roteamento. Esta abordagem permite a gestão de certificados TLS num único ponto de entrada (*single Load Balancer*), otimizando custos e centralizando o controlo de tráfego **L7**.

---

### 2.2 Gestão de Certificados — Cert-Manager + Let’s Encrypt

**Decisão:**  
Instalar o **Cert-Manager**.

**Justificação:**  
Automatiza o ciclo de vida dos certificados TLS (emissão, renovação e aplicação em *Secrets* Kubernetes) através do protocolo **ACME**, garantindo HTTPS sem intervenção manual.

---

### 2.3 Objeto de Roteamento — HTTPRoute

**Decisão:**  
Criar objetos **HTTPRoute**.

**Justificação:**  
Nestes recursos serão definidos os *hosts* (ex.: `api.cashflow.com`) e as regras de *path* responsáveis por direcionar o tráfego para o Service da aplicação.

---

## 3. Observabilidade Total

### 3.1 Descoberta de Métricas — ServiceMonitor

**Decisão:**  
Instalar o **kube-prometheus** e criar **CRDs do tipo ServiceMonitor**.

**Justificação:**  
O kube-prometheus fornece um conjunto completo de componentes de observabilidade, incluindo recolha, armazenamento e visualização de métricas, bem como dashboards pré-configurados para monitorização do cluster.

A monitorização da API será realizada através de um **ServiceMonitor**, que define de forma declarativa os critérios de descoberta automática de Services e os parâmetros de scraping, incluindo endpoint `/metrics`, portas, seletores de labels e intervalos de recolha.

---

### 3.2 Alertas — Alertmanager

**Decisão:**  
Configurar regras de alerta no **Alertmanager**.

**Justificação:**  
O Alertmanager será responsável por agrupar, silenciar e encaminhar notificações (Slack, Microsoft Teams, Email, etc.) sempre que as métricas recolhidas pelo Prometheus indiquem falhas no cluster ou na API.

---

## 4. Resiliência e Disponibilidade

### 4.1 Gestão de Memória — Resource Requests & Limits

**Decisão:**  
Definir *memory limits* superiores ao consumo de pico inicial e *memory requests* que garantam espaço mínimo no nó.

**Justificação:**  
A correta configuração de `limits.memory` evita **OOMKill** em picos previsíveis, enquanto `requests.memory` garante que o *scheduler* posiciona o Pod num nó com recursos suficientes.

---

### 4.2 Probes de Saúde — Startup Probe

**Decisão:**  
Implementar uma **Startup Probe** com `failureThreshold` ajustado ao tempo de arranque da aplicação (ex.: 35–45s), seguida de uma **Readiness Probe**.

**Justificação:**  
A Startup Probe desativa temporariamente as restantes probes até que a aplicação esteja operacional, evitando reinícios prematuros e falhas de readiness durante a inicialização da base de dados.

---

## Consequências

### Benefícios
- Elevado nível de segurança (imagens limpas e assinadas)
- Automação completa de TLS
- Observabilidade nativa do cluster e da aplicação
- Gestão adequada de recursos
- Alinhamento com requisitos de conformidade e auditoria

### Trade-offs / Riscos
- Maior complexidade inicial no pipeline CI/CD
- Necessidade de gestão de chaves do Cosign
- Aumento da complexidade inicial dos manifestos Kubernetes

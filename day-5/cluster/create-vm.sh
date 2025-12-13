#!/bin/bash

# Parâmetros padrão
SERVER_NAME="k8s-cp-01"
USERNAME="debian"
IP_ADDRESS="192.168.1.40"

# Função para exibir ajuda
show_help() {
    echo "Uso: $0 [opções]"
    echo "Opções:"
    echo "  --servername <nome>     Nome do servidor (padrão: k8s-cp-01)"
    echo "  --username <usuário>    Nome do usuário (padrão: debian)"
    echo "  --ip_address <ip>       Endereço IP (padrão: 192.168.1.40)"
    echo "  --help                  Exibir esta ajuda"
    echo ""
    echo "Exemplo:"
    echo "  $0 --servername k8s-worker-01 --username debian --ip_address 192.168.1.41"
}

# Parse dos argumentos da linha de comando
while [[ $# -gt 0 ]]; do
    case $1 in
        --servername)
            SERVER_NAME="$2"
            shift 2
            ;;
        --username)
            USERNAME="$2"
            shift 2
            ;;
        --ip_address)
            IP_ADDRESS="$2"
            shift 2
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "Opção desconhecida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validar parâmetros obrigatórios
if [[ -z "$SERVER_NAME" || -z "$USERNAME" || -z "$IP_ADDRESS" ]]; then
    echo "Erro: Todos os parâmetros são obrigatórios"
    show_help
    exit 1
fi

echo "Configuração:"
echo "  Servidor: $SERVER_NAME"
echo "  Usuário: $USERNAME"
echo "  IP: $IP_ADDRESS"
echo ""

# Baixar a imagem cloud do Debian 13 (se não existir)
if [ ! -f "debian-13-genericcloud-amd64.qcow2" ]; then
    echo "Baixando imagem base do Debian 13..."
    wget -O debian-13-genericcloud-amd64.qcow2 https://cdimage.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2
else
    echo "Imagem base já existe, pulando download..."
fi

# Copiar a imagem para criar o disco da VM
cp debian-13-genericcloud-amd64.qcow2 ${SERVER_NAME}.qcow2

# Ajustar permissões do arquivo de disco
sudo chmod 644 ${SERVER_NAME}.qcow2

# Criar arquivos de cloud-init
cat > user-data.yaml <<EOF
#cloud-config
users:
  - name: ${USERNAME}
    ssh_authorized_keys:
      - ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFpdONRrtDO74K+p6PoGRzSW0lzbPHN68m8EgxPk2EAy paulo.zagalo.neves@gmail.com
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
    lock_passwd: false
ssh_pwauth: true
disable_root: false
EOF

cat > network-config.yaml <<EOF
version: 2
ethernets:
  enp1s0:
    dhcp4: false
    addresses: 
      - ${IP_ADDRESS}/24
    gateway4: 192.168.1.1
    nameservers:
      addresses:
        - 1.1.1.1
        - 8.8.8.8
EOF

cat > meta-data.yaml <<EOF
instance-id: ${SERVER_NAME}
local-hostname: ${SERVER_NAME}
EOF

# Executar virt-install
echo "Criando VM ${SERVER_NAME}..."
virt-install \
    --name ${SERVER_NAME} \
    --memory 4096 \
    --vcpus 4 \
    --os-variant debian13 \
    --disk ${SERVER_NAME}.qcow2,size=20,format=qcow2 \
    --network bridge=br0,model=virtio \
    --graphics spice,listen=0.0.0.0 \
    --noautoconsole \
    --import \
    --cloud-init user-data=user-data.yaml,network-config=network-config.yaml,meta-data=meta-data.yaml

echo "VM ${SERVER_NAME} criada com sucesso! Use 'virsh console ${SERVER_NAME}' para acessar o console."

# Limpar arquivos temporários de cloud-init
rm user-data.yaml network-config.yaml meta-data.yaml
echo "Arquivos temporários de cloud-init removidos."    

echo "Para acessar a VM, use o comando: ssh ${USERNAME}@${IP_ADDRESS}"

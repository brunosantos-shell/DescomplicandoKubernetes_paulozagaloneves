```bash
# Baixar a imagem cloud do Debian 13
wget -O debian-13-genericcloud-amd64.qcow2 https://cdimage.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2

cp debian-13-genericcloud-amd64.qcow2 k8s-cp-01.qcow2

sudo chmod 644 k8s-cp-01.qcow2

# Criar arquivos de cloud-init
cat > user-data.yaml <<EOF
#cloud-config
users:
  - name: debian
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
      - 192.168.1.40/24
    gateway4: 192.168.1.1
    nameservers:
      addresses:
        - 1.1.1.1
        - 8.8.8.8
EOF

cat > meta-data.yaml <<EOF
instance-id: k8s-cp-01
local-hostname: k8s-cp-01
EOF

# Executar virt-install
virt-install \
    --name debian13-vm \
    --memory 4096 \
    --vcpus 4 \
    --os-variant debian13 \
    --disk k8s-cp-01.qcow2,size=20,format=qcow2 \
    --network bridge=br0,model=virtio \
    --graphics spice,listen=0.0.0.0 \
    --console pty,target_type=serial \
    --import \
    --cloud-init user-data=user-data.yaml,network-config=network-config.yaml,meta-data=meta-data.yaml
```

**Notes:**
- Now uses separate cloud-init files (user-data.yaml and meta-data.yaml) which are more reliable than inline heredoc.
- The `--import` flag indicates we're using a pre-built cloud image instead of an ISO installer.
- SPICE graphics are enabled for better performance and features (clipboard sharing, USB redirection).
- You can connect using `remote-viewer spice://localhost:5900` or similar SPICE client.
- Network configured for static IP 192.168.1.40 on interface enp1s0.
- SSH access configured with your ed25519 public key.
- Downloads the official Debian 13 Trixie cloud image which contains a bootable system.
- Network configuration is now in a separate network-config.yaml file for better organization.

**Para copiar/renomear a imagem corretamente:**
```bash
# Método correto para copiar a imagem
sudo cp debian-13-genericcloud-amd64.qcow2 /var/lib/libvirt/images/debian13-vm.qcow2
sudo chown qemu:qemu /var/lib/libvirt/images/debian13-vm.qcow2
sudo chmod 644 /var/lib/libvirt/images/debian13-vm.qcow2

# Se usar SELinux (verificar com: getenforce)
sudo restorecon /var/lib/libvirt/images/debian13-vm.qcow2

# Então usar no virt-install:
--disk /var/lib/libvirt/images/debian13-vm.qcow2,size=20,format=qcow2
```

- **Problema com cópia simples:** Permissões, ownership e contexto SELinux incorretos impedem o libvirt de acessar a imagem.
- Clean up files: `rm user-data.yaml network-config.yaml meta-data.yaml`
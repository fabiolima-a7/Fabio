#!/bin/bash

# ==============================================================================
# SCRIPT DE CORREÇÃO DE CHAVES SSH (ECDSA) PARA COMPATIBILIDADE (X2Go / Libssh)
# ==============================================================================

# Garante que o script está sendo executado como root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Erro: Este script precisa ser executado como root ou com sudo."
  exit 1
fi

SSHD_CONFIG="/etc/ssh/sshd_config"
ECDSA_KEY="/etc/ssh/ssh_host_ecdsa_key"
RSA_KEY="/etc/ssh/ssh_host_rsa_key"

echo "🔄 Iniciando a verificação de chaves SSH..."

# 1. Verificar e Gerar a chave ECDSA se não existir
if [ ! -f "$ECDSA_KEY" ]; then
    echo "🔑 Chave ECDSA não encontrada. Gerando nova chave..."
    ssh-keygen -t ecdsa -f "$ECDSA_KEY" -N ""
    if [ $? -eq 0 ]; then
        echo "✅ Chave ECDSA gerada com sucesso."
    else
        echo "❌ Erro ao gerar a chave ECDSA."
        exit 1
    fi
else
    echo "ℹ️ A chave ECDSA já existe em $ECDSA_KEY."
fi

# 2. Configurar o sshd_config para garantir o carregamento das chaves
echo "📝 Ajustando configurações em $SSHD_CONFIG..."

# Função para adicionar o HostKey se não estiver configurado
configurar_hostkey() {
    local key_path=$1
    # Verifica se a linha já existe (mesmo comentada)
    if grep -qE "^#?HostKey[[:space:]]+$key_path" "$SSHD_CONFIG"; then
        # Descomenta a linha se estiver comentada
        sed -i -E "s|^#?(HostKey[[:space:]]+$key_path)|\1|" "$SSHD_CONFIG"
    else
        # Se não existir, adiciona ao final do arquivo
        echo "HostKey $key_path" >> "$SSHD_CONFIG"
    fi
}

configurar_hostkey "$RSA_KEY"
configurar_hostkey "$ECDSA_KEY"

# 3. Reiniciar o serviço SSH
echo "🔄 Reiniciando o serviço SSH..."
if command -v systemctl >/dev/null 2>&1; then
    systemctl restart sshd
elif command -v service >/dev/null 2>&1; then
    service sshd restart
else
    /etc/init.d/sshd restart
fi

# 4. Validar se o servidor agora anuncia ECDSA
echo "🔍 Validando a configuração localmente..."
sleep 2 # Aguarda o SSH subir completamente

if command -v ssh-keyscan >/dev/null 2>&1; then
    SAIDA_SCAN=$(ssh-keyscan -t ecdsa localhost 2>/dev/null)
    if [[ "$SAIDA_SCAN" == *"ecdsa-sha2-nistp256"* ]]; then
        echo "🎉 Sucesso! O servidor agora está anunciando chaves ECDSA."
        echo "🚀 Você já pode tentar a conexão via X2Go."
    else
        echo "⚠️ Atenção: O ssh-keyscan não retornou a chave ECDSA esperada. Verifique os logs do SSH."
    fi
else
    echo "ℹ️ Comando 'ssh-keyscan' não encontrado para validação automática, mas as configurações foram aplicadas."
fi
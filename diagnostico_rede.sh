#!/bin/bash

DATA=$(date +"%Y-%m-%d_%H-%M-%S")
ARQUIVO="diagnostico_rede_${DATA}.txt"

{
echo "=================================================="
echo "DIAGNÓSTICO DE REDE"
echo "Data: $(date)"
echo "Hostname: $(hostname)"
echo "=================================================="

echo
echo "########## IP ADDR ##########"
ip addr

echo
echo "########## IP ROUTE ##########"
ip route

echo
echo "########## IP ROUTE GET 8.8.8.8 ##########"
ip route get 8.8.8.8

echo
echo "########## DNS (/etc/resolv.conf) ##########"
cat /etc/resolv.conf

echo
echo "########## PING 8.8.8.8 ##########"
ping -c 4 8.8.8.8

echo
echo "########## PING 1.1.1.1 ##########"
ping -c 4 1.1.1.1

echo
echo "########## PING www.google.com ##########"
ping -c 4 www.google.com

echo
echo "########## TRACEROUTE 8.8.8.8 ##########"
traceroute 8.8.8.8

echo
echo "########## TABELA ARP ##########"
ip neigh

echo
echo "########## ESTATÍSTICAS DAS INTERFACES ##########"
ip -s link

echo
echo "=================================================="
echo "FIM DO DIAGNÓSTICO"
echo "=================================================="

} > "$ARQUIVO" 2>&1

echo "Diagnóstico salvo em: $ARQUIVO"
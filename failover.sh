#!/bin/bash

#Gateway padrao
GW_DEFAULT="`ip ro | grep -i default | cut -f3 -d" "`"

#Arquivo de Log
LOGFILE=/var/log/failover.log

#Tempo de espera para teste de conexão
tempo_espera=120

#Número de pacote do ping
numero_pacotes=10

#Internet ifaces
iflink1=enp6s0
iflink2=enp7s0

#Gw's
gwlink1=<gateway 1>
gwlink2=<gateway 2>

#Tables
tablelink1=200
tablelink2=201

#Ping destiny
endereco_ping_link1=208.67.222.222
endereco_ping_link2=208.67.220.220

#Arquivos balance
arquivo=/usr/local/firewall/failover/loadbalance

#Arquivos email
email76="/usr/local/firewall/failover/email76.sh"
emailnet="/usr/local/firewall/failover/emailnet.sh"

#Arquivos rota
addrotaestatica=/usr/local/firewall/failover/addrotaestatica.sh
delrotaestatica=/usr/local/firewall/failover/delrotaestatica.sh

#Não alterar
#Variáveis destinadas ao controle
i=0
link1=1
link2=1
falha=1
contador=0

#Ativação banlanceamento de links
sh $arquivo >> $LOGFILE

while [ $i -le 10 ];
do
	
#Determining Routes
ip route add $endereco_ping_link1/32 via $gwlink1 >> $LOGFILE
ip route add $endereco_ping_link2/32 via $gwlink2 >> $LOGFILE

#Gets date
DATE=`date '+%d-%m-%Y %H:%M:%S'` >> $LOGFILE

#########
#Link1###
#########
#Detecta se esta em link up antes de testar ping.
cmd_link1=$(ip addr show $iflink1 | grep state | awk '{print $9}')
if [ "$cmd_link1" != "DOWN" ]
then
cmd_link1_route=$(ip route show table $tablelink1 | awk '{print $2}')
if [ "$cmd_link1_route" != "via" ]
then
ip route add default dev $iflink1 via $gwlink1 table $tablelink1
fi
if (ping -I $iflink1 -c $numero_pacotes $endereco_ping_link1 >> $LOGFILE)
then
link1="1"
else
link1="0"
fi
else
link1="0"
fi

#########
#Link2###
#########
#Detecta se esta em link up antes de testar ping.
cmd_link2=$(ip addr show $iflink2 | grep state | awk '{print $9}')
if [ "$cmd_link2" != "DOWN" ] 
then
cmd_link2_route=$(ip route show table $tablelink2 | awk '{print $2}')
if [ "$cmd_link2_route" != "via" ]
then
ip route add default dev $iflink2 via $gwlink2 table $tablelink2
fi
if (ping -I $iflink2 -c $numero_pacotes $endereco_ping_link2 >> $LOGFILE)
then
link2="1"
else
link2="0"
fi
else
link2="0"
fi

#Testing comparations
if [ "$link1" = "1" ] && [ "$link2" = "1" ];then
sh $arquivo 
echo " Subindo o LOADBALANCE -  `date +%d/%m/%y-%H:%M:%S`" >> $LOGFILE

echo "Add rota estatica de sites" >> $LOGFILE
sh $addrotaestatica
falha="1"

elif [ "$link1" = "0" ] && [ "$link2" = "1" ];then
echo "------------------" >> $LOGFILE
echo "Evento de Queda..." >> $LOGFILE
echo "Link L1 (76 TELECOM) OFFLINE!" >> $LOGFILE
echo $DATE >> $LOGFILE

echo "------------------" >> $LOGFILE
ip route del default
ip route add default via $gwlink2
ip route flush cache

echo "Deleta rota estatica de sites" >> $LOGFILE
sh $delrotaestatica

if [ "$falha" = "1" ]; then
echo " envia email 76 off" >> $LOGFILE
sh $email76 >> $LOGFILE
fi

elif [ "$link1" = "1" ] && [ "$link2" = "0" ];then
echo "------------------" >> $LOGFILE
echo "Evento de Queda..." >> $LOGFILE
echo "Link L2 (NET CLARO) OFFLINE! " >> $LOGFILE

echo $DATE >> $LOGFILE
echo "------------------" >> $LOGFILE
ip route del default
ip route add default via $gwlink1
ip route flush cache

echo "Deleta rota estatica de sites" >> $LOGFILE
sh $delrotaestatica

if [ "$falha" = "1" ]; then
echo "envia email net off" >> $LOGFILE
sh $emailnet >> $LOGFILE
fi

elif [ "$link1" = "0" ] && [ "$link2" = "0" ];then
echo "------------------" >> $LOGFILE
echo "Evento de Queda..." >> $LOGFILE
echo "Link L1/L2 Invativos!" >> $LOGFILE
echo $DATE >> $LOGFILE
echo "------------------" >> $LOGFILE
fi

sleep $tempo_espera
falha=0
contador=$((contador+1))
echo " "
echo " Contador:  " $contador >> $LOGFILE
echo " "
if [ "$contador" = "30" ]; then
falha=1
contador=0
fi

done

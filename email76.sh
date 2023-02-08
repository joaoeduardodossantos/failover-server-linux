#!/bin/bash
envio="email"
destino="email destino"
servidor="smtp"
usuario="email"
senha="senha"

sendEmail -o tls=no -f $envio -t $destino -u "FailOver: mensagem -  `date`" -o message-file=/usr/local/firewall/failover/falha1 -s $servidor -xu $usuario -xp $senha

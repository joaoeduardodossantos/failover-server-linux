#!/bin/bash

#Vars
#link
iflink="enp7s0"
gwlink="<gateway>"

# Ativa rotas
route add -host www.google.com gw $gwlink dev $iflink


#!/bin/bash

#Vars
#link
iflink="enp7s0"
gwlink="<gateway>"

# Ativa rotas
route del -host www.goolgle.com gw $gwlink dev $iflink


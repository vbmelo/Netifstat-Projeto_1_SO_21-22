#!/bin/bash

#Handling the errors...
# PRECISA-SE DO ARGUMENTO NUMERICO. Apenas um numero como argumento.
re='^[0-9]+([.][0-9]+)?$';
argumentos=( "$@" );
count_ArgNums=0;
if (($# < 2)) 
then
    if [[ $# -eq 0 ]] # Se nao tiver um argumento PARE.
    then
        echo "error: not enough arguments, at least one number as argument is required." >&2; exit 1
    else
        for argumento in "${argumentos[@]}"
        do
            if [[ $argumento =~ $re ]] ; then #se algum argumento for um numero continue:
            echo "argument $argumento is a number... CONTINUING";
            tempo=$argumento; #tempo de execucao do comando = argumento numerico
            count_ArgNums+=1;
            else
            echo "error: argument $argumento is NOT a number, at least one number as argument is required." >&2; exit 1
            fi
        done
    fi

else #Se tiver mais de um argumento, avalie se contem APENAS um numero como argumento.
    for argumento in "${argumentos[@]}"
    do
        if [[ $argumento =~ $re ]]; then #se algum argumento for um numero faca:
            echo "argument $argumento is a number... CONTINUING";
            tempo=$argumento; #tempo de execucao do comando = argumento numerico
            count_ArgNums+=1;
            if [[ $count_ArgNums -gt 1 ]] ; then
                echo "error: only one number as argument is allowed" >&2; exit 1
            fi
        else
            echo "argument $argumento is NOT a number";
        fi
    done
fi
#Testando o tempo
echo tempo $tempo


#Nomes das Interfaces - guardados em um array: itf_name
IFS=$'\n' read -r -d '' -a itf_name < <( ifconfig -a | grep ": " | awk '{print $1}' | tr -d : && printf '\0' )
itf_length=${#itf_name[@]} #Quantidade de Interfaces

#IMPRIMINDO - Interfaces e quantidade de interfaces: 
# echo you have: "$itf_length" interfaces

printf "%-10s %10s %10s %10s %10s \n" "NETIF" "TX" "RX" "TRATE" "RRATE";
#Para cada interface, imprima os bytes de pacotes TX de cada interface...
for interface in "${itf_name[@]}"
    do
        #TX em bytes
        IFS=$'\n' read -r -d '' -a TxBytes_inicial < <( ifconfig -a $interface | grep "TX packets " | awk '{print $5}' && printf '\0' )
        #RX em bytes
        IFS=$'\n' read -r -d '' -a RxBytes_inicial < <( ifconfig -a $interface | grep "RX packets " | awk '{print $5}' && printf '\0' )


        printf "%-10s %10d %10d %10d %10d \n" $interface $TxBytes_inicial $RxBytes_inicial $TRate $RRate
    done
echo $@
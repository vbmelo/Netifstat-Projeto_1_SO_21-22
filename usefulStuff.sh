# #ifconfig -a $1 | grep "RX\|packets" | awk '{print$1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6" "$7}'
# # ifconfig -a lo | grep "bytes" | awk '{print $3}'
# pega o terceiro item do ifconfig da interface lo, filtrado pelo grep
# pela palavra "bytes", apos isso o comando awk eh utilizado para pegar todos
# os packeges, pois sao o 3 item impressos por linha
#!/bin/bash
echo NETIF$'\t'TX$'\t'RX;
# read a b c d e f g<<< $(ifconfig -a $1 | grep "RX\|packets" | awk '{print$1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6" "$7}')
# echo $a $b $c $d $e $f $g
IFS=$' ' read -r -d '' itfArray <<< "$(ifconfig -a | grep ": " | awk '{print $1}')"
itfNum="$(ifconfig -a | grep ": " | awk 'NR = 1 {print $1}')"
itf_0="$(ifconfig -a $1 | grep "packets" | awk 'NR <= 2 {print $0}')"
itf_1="$(ifconfig -a $1 | grep "packets" | awk 'NR > 2 && NR <=4 {print $0}')"
# read -r rx pckt pcktNum bt btNum btNumA btNumB <<< $($teste | awk '{$1 $2 $3 $4 $5 $6 $7}')
# echo imprimindooo $pckt $pcktNum $bt $btNum $btNumA $btNumB
# [[ iName="lo" ]]; #interface's name
# read teste <<< $(ifconfig -a lo | awk '{/inet[[:space:]]/}');
echo ${itfNum}$'\n'${itf_0}$'\n'${itf_1}

for element in "${itfArray[@]}"
    do
        echo Element: "$element"
    done

## NEW VERSION 
#!/bin/bash
echo NETIF$'\t\t'TX$'\t'RX$'\t'TRATE$'\t'RRATE;

#Nomes das Interfaces
IFS=$'\n' read -r -d '' -a itf_name < <( ifconfig -a | grep ": " | awk '{print $1}' | tr -d : && printf '\0' )
itf_length=${#itf_name[@]} #Quantidade de Interfaces

#IMPRIMINDO - Interfaces e quantidade de interfaces: 
echo you have: "$itf_length" interfaces

for interface in "${itf_name[@]}"
    do
       echo iterface name: "$interface";
    done

#Trying to get TX bytes
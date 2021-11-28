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

#########################################################

printf "%-10s %10s %10s %10s %10s \n" "NETIF" "TX" "RX" "TRATE" "RRATE";
#Para cada interface, salve os bytes iniciais de pacotes TX e RX de cada interface...
#Desde a execucao do programa.
for interface in "${itf_name[@]}"
    do
        #TX em bytes
        IFS=$'\n' read -r -d '' -a TxBytes_inicial < <( ifconfig -a $interface | grep "TX packets " | awk '{print $5}' && printf '\0' )
        #RX em bytes
        IFS=$'\n' read -r -d '' -a RxBytes_inicial < <( ifconfig -a $interface | grep "RX packets " | awk '{print $5}' && printf '\0' )

        printf "%-10s %10d %10d %10d %10d \n" $interface $TxBytes_inicial $RxBytes_inicial $TRate $RRate
done

#sleeping for $tempo/10
echo sleeping for $tempo seconds...
sleep $tempo
echo just wake up!

echo !!! DADOS NOVOS !!!
printf "%-10s %10s %10s %10s %10s \n" "NETIF" "TX" "RX" "TRATE" "RRATE";
#Para cada interface, imprima os bytes de pacotes TX de cada interface...
for interface in "${itf_name[@]}"
    do
        #TX em bytes
        IFS=$'\n' read -r -d '' -a TxBytes_final < <( ifconfig -a $interface | grep "TX packets " | awk '{print $5}' && printf '\0' )
        #RX em bytes
        IFS=$'\n' read -r -d '' -a RxBytes_final < <( ifconfig -a $interface | grep "RX packets " | awk '{print $5}' && printf '\0' )

        TRate=$(( ($TxBytes_final-$TxBytes_inicial)/$tempo ))

        printf "%-10s %10d %10d %10d %10d \n" $interface $TxBytes_final $RxBytes_final $TRate $RRate
done
        echo TRate:  $TRate


######################################################################################
#TRate Test
for tx_f in "${TxBytes_final[@]}"
    do
        echo tx_final: "$tx_f"
done
for rx_f in "${RxBytes_final[@]}"
do
        echo rx_final: "$rx_f"
done

#TRate Stuff
TRate=();

for ((i=0,j=$itf_length;i<j;i++))
do
    TRate_value=$(( (${TxBytes_final[i]} - ${TxBytes_inicial[i]}) / $tempo ))
    if [[ $TRate_value -eq 0 ]]; then
        TRate_value=$(( ${TxBytes_final[i]} / $tempo ))
    fi
    TRate+=("$TRate_value");
    echo Teste --- tx_inicial: "${TxBytes_inicial[i]}" $'\t' tx_final: "${TxBytes_final[i]}" $'\t' t_rate: "$TRate_value"
done

echo teste TRate array
for i in "${TRate[@]}"
do
    echo testttt "$i"
done
echo "${TRate[@]}"

### ou  ####
#TRate Stuff
TRate=();
for ((i=0,j=$itf_length;i<j;i++))
do
    dif=$(( ${TxBytes_final[i]} - ${TxBytes_inicial[i]} ))
    TRate_value="$( echo "scale=1; $dif / $tempo" | bc )"
    if [[ $dif -eq 0 ]]; then
        TRate_value="$( echo "scale=2; ${TxBytes_final[i]} / $tempo" | bc )"
    fi
    TRate+=("$TRate_value");
    echo Teste --- tx_inicial: "${TxBytes_inicial[i]}" $'\t' tx_final: "${TxBytes_final[i]}" $'\t' t_rate: "$TRate_value"
done

echo teste TRate array
for i in "${TRate[@]}"
do
    echo testttt "$i"
done
echo "${TRate[@]}"

###b##########################
keyword=${argumentos[i+1]};
                echo "$keyword";
                for itf in "${itf_name[@]}"
                do
                    if ! [[ $keyword =~ $itf ]]; then # se o nome nao corresponder a uma interface, delete ela do array...
                        echo Deleting: "$itf";
                        itf_name=("${itf_name[@]/$itf}");
                    fi
                done



#####################################################################
# Esta era a maneira mais eficiente (termos de tempo de computacao e complexidade, porem nao funciona como desejado)
keyword=${argumentos[i+1]};
                echo "$keyword";
                for itf in "${itf_name[@]}"
                do
                    if ! [[ $itf =~ "$keyword" || "$keyword" =~ $itf ]]; then # se o nome nao corresponder a uma interface, delete ela do array...
                        echo Deleting: "$itf";
                        itf_to_delete=("$itf"); #Criando um array com os itens que deseja deletar
                    fi
                done
                declare -A delk
                for itf in "${itf_to_delete[@]}" ; do delk[$itf]=1 ; done #Array com os itens que deseja deletar
                for k in "${!itf_name[@]}" ; do
                        [ "${delk[${itf_name[$k]}]-}" ] && unset 'itf_name[k]'
                done
                itf_name=("${itf_name[@]}");
                itf_length=${#itf_name[@]}; # temos que declarar novamente a variavel com o tamanho do array das interfaces, pois este foi alterado (used to do a big messy bug... now fixed!)

################# solucao brute force, ineficiente da mesma forma ###########3
# for target in "${itf_to_delete[@]}"; do
                #     for i in "${!itf_name[@]}"; do
                #         if [[ ${itf_name[i]} = $target ]]; then
                #         unset 'itf_name[i]'
                #         fi
                #     done
                # done
                # for i in "${!itf_name[@]}"; do
                # new_itf_name+=( "${itf_name[i]}" )
                # done
                # itf_name=("${new_itf_name[@]}")
                # unset new_itf_name



                ###     testing if the unmatched items were deleted from the array      ###
for itf in "${itf_name[@]}"
do
    echo remains: "$itf";
done

for dlt in "${itf_index[@]}" # Testing whether the corresponding index of the deleted interface name has been appended to its array
do
    echo deleted index: "$dlt";
done
for dlt in "${tx_i_to_delete[@]}" # Testing whether the corresponding index of the deleted interface name has been appended to its array
do
    echo tx i to delete: "$dlt";
done
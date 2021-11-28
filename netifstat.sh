#!/bin/bash
###    Handling the ARGUMENTS...   ###
##  PRECISA-SE DO ARGUMENTO NUMERICO. Apenas um numero como argumento.

#######################################################################    PROCURAR SOBRE GETOPT!!!    ##########################################################3
# optarg guarda o argumento
# opt = getopt(argc, argv, "cnt:v:")
# optind indice dos argumentos


echo Argumentos: $@
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
            tempo=$argumento; #tempo de execucao do comando = argumento numericoLC_NUMERIC="en_US.UTF-8"
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

###     Handling the INTERFACES names   ###
##  Nomes das Interfaces - guardados em um array: itf_name
IFS=$'\n' read -r -d '' -a itf_name < <( ifconfig -a | grep ": " | awk '{print $1}' | tr -d : && printf '\0' )
itf_length=${#itf_name[@]} #Quantidade de Interfaces

IFS=$'\n' read -r -d '' -a TxBytes_inicial < <( ifconfig -a | grep "TX packets " | awk '{print $5}' && printf '\0' )
IFS=$'\n' read -r -d '' -a RxBytes_inicial < <( ifconfig -a | grep "RX packets " | awk '{print $5}' && printf '\0' )


###     Handling the Execution Time     ###
echo sleeping for $tempo seconds...
# sleep $tempo      #If you want to testar, sujiro que comenete esta linha :)
echo just wake up!

IFS=$'\n' read -r -d '' -a TxBytes_final < <( ifconfig -a | grep "TX packets " | awk '{print $5}' && printf '\0' )
IFS=$'\n' read -r -d '' -a RxBytes_final < <( ifconfig -a | grep "RX packets " | awk '{print $5}' && printf '\0' )


###     Handling the RATES!     ###
TRate=();
for ((i=0,j=$itf_length;i<j;i++))
do
    dif=$(( ${TxBytes_final[i]} - ${TxBytes_inicial[i]} ))
    TRate_value="$( echo "scale=1; $dif / $tempo" | bc )"
    if [[ $dif -eq 0 ]]; then
        TRate_value="$( echo "scale=2; ${TxBytes_final[i]} / $tempo" | bc )"
    fi
    TRate+=("$TRate_value");
    #Testing it...
    # echo Teste --- tx_inicial: "${TxBytes_inicial[i]}" $'\t' tx_final: "${TxBytes_final[i]}" $'\t' t_rate: "$TRate_value"
done

RRate=();
for ((i=0,j=$itf_length;i<j;i++))
do
    dif=$(( ${RxBytes_final[i]} - ${RxBytes_inicial[i]} ))
    RRate_value="$( echo "scale=1; $dif / $tempo" | bc )"
    if [[ $dif -eq 0 ]]; then
        RRate_value="$( echo "scale=2; ${RxBytes_final[i]} / $tempo" | bc )"
    fi
    RRate+=("$RRate_value");
    #Testing it...
    # echo Teste --- Rx_inicial: "${RxBytes_inicial[i]}" $'\t' Rx_final: "${RxBytes_final[i]}" $'\t' R_rate: "$RRate_value"
done


###     Handling the Outputs    ###
##  Basic Case Output

printf "%-15s %15s %15s %15s %15s \n" "NETIF" "TX" "RX" "TRATE" "RRATE";

for ((i=0;i<$itf_length;i++))
do
    LC_NUMERIC="en_US.UTF-8" printf "%-15s %15d %15d %15.2f %15.2f \n" ${itf_name[i]} ${TxBytes_final[i]} ${RxBytes_final[i]} ${TRate[i]} ${RRate[i]}
done

###     Other outputs   ###
##  Based in the given arguments

#   regex mask to find whats between "" after the -c argument
# mask='["]\w+["]'; -> not necessario, bash ja retira as "" do argumento e passa ele como string...
itf_to_delete=(); # array com as interfaces que nao correspondem as que queremos peloa arg -c "itf que queremos"
tx_i_to_delete=();
tx_f_to_delete=();
rx_i_to_delete=();
rx_f_to_delete=();
itf_index=();   # array com os indices das interfaces apagadas
for ((i=0;i<$#;i++))
do
    if ! [[ ${argumentos[i]} =~ $re ]] ; then #se algum argumento nao for um numero continue:
        case ${argumentos[i]} in
            -c)
                ###     Tratando de excluir as interfaces que nao correspondem a keyword passada apos -c    ###
                keyword=${argumentos[i+1]};#keyword passada entre "" apos o -c
                for ((i=0;i<${#itf_name[@]};i++)) 
                    do
                        if ! [[ ${itf_name[i]} =~ $keyword ]]; then # se o nome nao corresponder a uma interface, adicione ela ao array com as interfaces a serem deletadas
                            echo Deleting: "${itf_name[i]}";
                            itf_to_delete+=("${itf_name[i]}"); #Criando um array com os itens que deseja deletar
                            itf_index+=("$i"); #Salvando os indices de cada interface a ser deletada, para posteriormente deletar dos arrays tx, rx e rates
                        fi
                done
                declare -A delk
                for itf in "${itf_to_delete[@]}" ; do delk[$itf]=1 ; done #Array com os itens que deseja deletar
                for k in "${!itf_name[@]}" ; do
                        [ "${delk[${itf_name[$k]}]-}" ] && unset 'itf_name[k]'
                done
                itf_name=("${itf_name[@]}");
               
                ###     Tratando de apagar os indices correspondentes as interfaces deletadas dos arrays de TX, RX e Rates      ###

                for ((i=0;i<$itf_length;i++)) 
                    do
                        if [[ ${itf_index[i]} =~ ${!TxBytes_inicial[i]} || ${itf_index[i]} =~ ${!TxBytes_final[i]} || ${itf_index[i]} =~ ${!RxBytes_inicial[i]} || ${itf_index[i]} =~ ${!RxBytes_final[i]} ]] ; then
                            echo to be deleted - TX i: ${TxBytes_inicial[i]};
                            tx_i_to_delete+=("${TxBytes_inicial[i]}");  
                            echo to be deleted - TX f: ${TxBytes_final[i]};
                            tx_f_to_delete+=("${TxBytes_final[i]}");
                            echo to be deleted - RX i: ${RxBytes_inicial[i]};
                            rx_i_to_delete+=("${RxBytes_inicial[i]}"); 
                            echo to be deleted - RX f: ${RxBytes_final[i]};
                            rx_f_to_delete+=("${RxBytes_final[i]}");
                        fi
                done

                declare -A delk
                for itf in "${tx_i_to_delete[@]}" ; do delk[$itf]=1 ; done #Array com os itens que deseja deletar
                for k in "${!TxBytes_inicial[@]}" ; do
                        [ "${delk[${TxBytes_inicial[$k]}]-}" ] && unset 'TxBytes_inicial[k]'
                done
                TxBytes_inicial=("${TxBytes_inicial[@]}");

                declare -A delk
                for itf in "${tx_f_to_delete[@]}" ; do delk[$itf]=1 ; done #Array com os itens que deseja deletar
                for k in "${!TxBytes_final[@]}" ; do
                        [ "${delk[${TxBytes_final[$k]}]-}" ] && unset 'TxBytes_final[k]'
                done
                TxBytes_final=("${TxBytes_final[@]}");

                declare -A delk
                for itf in "${rx_i_to_delete[@]}" ; do delk[$itf]=1 ; done #Array com os itens que deseja deletar
                for k in "${!RxBytes_inicial[@]}" ; do
                        [ "${delk[${RxBytes_inicial[$k]}]-}" ] && unset 'RxBytes_inicial[k]'
                done
                RxBytes_inicial=("${RxBytes_inicial[@]}");

                declare -A delk
                for itf in "${rx_f_to_delete[@]}" ; do delk[$itf]=1 ; done #Array com os itens que deseja deletar
                for k in "${!RxBytes_final[@]}" ; do
                        [ "${delk[${RxBytes_final[$k]}]-}" ] && unset 'RxBytes_final[k]'
                done
                RxBytes_final=("${RxBytes_final[@]}");


                itf_length=${#itf_name[@]}; # temos que declarar novamente a variavel com o tamanho do array das interfaces, pois este foi alterado (used to do a big messy bug... now fixed!)

            ;;


            -b)
            
            ;;


            -k)
            
            ;;


            -m)
            
            ;;


            -p)
            
            ;;


            -t)
            
            ;;


            -r)
            
            ;;


            -T)
            
            ;;


            -R)
            
            ;;


            -v)
            
            ;;


            -l)
            
            ;;

            *)
                echo  "${argumentos[i]}" "is an unsuported argument"$'\n'
            ;;
        esac
    fi
done

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

printStats() {
    printf "%-15s %15s %15s %15s %15s \n" "NETIF" "TX" "RX" "TRATE" "RRATE";

    for ((i=0;i<$itf_length;i++))
    do
        LC_NUMERIC="en_US.UTF-8" printf "%-15s %15d %15d %15.2f %15.2f \n" ${itf_name[i]} ${TxBytes_final[i]} ${RxBytes_final[i]} ${TRate[i]} ${RRate[i]}
    done
}

printStats

### ERRO NO PRINT, o indices do itf_name array mudou, pore, os indices dos rates nao mudaram...
# testar com: ./netifstat.sh 10 -c "w"
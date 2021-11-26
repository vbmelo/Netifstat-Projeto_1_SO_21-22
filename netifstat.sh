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

IFS=$'\n' read -r -d '' -a TxBytes_final < <( ifconfig -a $interface | grep "TX packets " | awk '{print $5}' && printf '\0' )
IFS=$'\n' read -r -d '' -a RxBytes_final < <( ifconfig -a $interface | grep "RX packets " | awk '{print $5}' && printf '\0' )


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
for ((i=0;i<$#;i++))
do
    if ! [[ ${argumentos[i]} =~ $re ]] ; then #se algum argumento nao for um numero continue:
        case ${argumentos[i]} in
            -c)
                keyword=${argumentos[i+1]};
                echo "$keyword";
                for itf in "${itf_name[@]}"
                do
                    if ! [[ $itf =~ $keyword ]]; then # se o nome corresponder a uma interface, delete ela...
                        echo "$itf";
                    fi
                done

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

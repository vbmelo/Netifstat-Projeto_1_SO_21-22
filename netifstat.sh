#!/bin/bash
#----------------------------------------------------
#                                                   -
#           Trabalho de Sistemas Operativos         -
#                      2021/2022                    -
#                      @Authors:                    -   
#                     Victor Melo                   -                
#                         &                         -
#                   Catarina Marques                -
#                                                   -
#----------------------------------------------------

###    Handling the ARGUMENTS...   ###
##  PRECISA-SE DO ARGUMENTO NUMERICO. Apenas um numero como argumento.
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

sleepTime(){
    for ((i = ($tempo), j = 0; i>0, j<$tempo; i--, j++))
        do
            #sleep 1
            echo 'Please wait' $i seconds...
    done
         #If you want to testar, sujiro que comenete esta linha :)
    echo just wake up!
}

gatherData() {  #funcao que armazena os valores do TX, RX, RRATE e TRATE das respectivas interfaces
        ###     Handling the INTERFACES names   ###
    ##  Nomes das Interfaces - guardados em um array: itf_name
    IFS=$'\n' read -r -d '' -a itf_name < <( ifconfig -a | grep ": " | awk '{print $1}' | tr -d : && printf '\0' )
    itf_length=${#itf_name[@]} #Quantidade de Interfaces

    IFS=$'\n' read -r -d '' -a TxBytes_inicial < <( ifconfig -a | grep "TX packets " | awk '{print $5}' && printf '\0' )
    IFS=$'\n' read -r -d '' -a RxBytes_inicial < <( ifconfig -a | grep "RX packets " | awk '{print $5}' && printf '\0' )

    IFS=$'\n' read -r -d '' -a TxBytes_final < <( ifconfig -a | grep "TX packets " | awk '{print $5}' && printf '\0' )
    IFS=$'\n' read -r -d '' -a RxBytes_final < <( ifconfig -a | grep "RX packets " | awk '{print $5}' && printf '\0' )

    ###     Handling the RATES!     ###
    TRate=()
    TX=()

    for ((i=0,j=$itf_length;i<j;i++))
    do
        TX=$(( ${TxBytes_final[i]} - ${TxBytes_inicial[i]} ))
        TRate_value="$( echo "scale=1; $TX / $tempo" | bc )"
        if [[ $TX -eq 0 ]]; then
            TRate_value="$( echo "scale=2; ${TxBytes_final[i]} / $tempo" | bc )"
        fi
        TRate+=("$TRate_value");
    done

    RRate=()
    RX=()

    for ((i=0,j=$itf_length;i<j;i++))
    do
        RX=$(( ${RxBytes_final[i]} - ${RxBytes_inicial[i]} ))
        RRate_value="$( echo "scale=1; $RX / $tempo" | bc )"
        if [[ $RX -eq 0 ]]; then
            RRate_value="$( echo "scale=2; ${RxBytes_final[i]} / $tempo" | bc )"
        fi
        RRate+=("$RRate_value");
    done

}

byteConversor() {   #Funcao para calcular os valores em bytes, kilobytes e megabytes
    if [[ $1 -eq 2 ]] ; then 
        for ((i=0;i<${#TRate[@]};i++))
        do
            if ! [[ ${TRate[i]} = 0 ]] ; then
            TX[i]="$( echo "(${TX[i]} + 1023) / 1024" )"
            RX[i]="$( echo "scale=2; (${RX[i]} + 1023) / 1024")"
            TRate[i]="$( echo "scale=2; (${TRate[i]} + 1023) / 1024" | bc )"
            RRate[i]="$( echo "scale=2; (${RRate[i]} + 1023) / 1024" | bc )"
            fi
        done
    fi
    if [[ $1 -eq 3 ]]; then 
        for ((i=0;i<${#TRate[@]};i++))
        do
            if ! [[ ${TRate[i]} = 0 ]] ; then
            TX[i]="$( echo "(${TX[i]} + 1048575) / 1048576" )"
            RX[i]="$( echo "(${RX[i]} + 1048575) / 1048576" )"
            TRate[i]="$( echo "scale=2; (${TRate[i]} + 1048575) / 1048576" | bc )"
            RRate[i]="$( echo "scale=2; (${RRate[i]} + 1048575) / 1048576" | bc )"
            fi
        done
    fi
}

reverseArray() {
    min=0
    max=$(( ${#itf_name[@]} -1 ))

    while [[ min -lt max ]]
    do
        x="${itf_name[$min]}"
        itf_name[$min]="${itf_name[$max]}"
        itf_name[$max]="$x"

        # Move closer
        (( min++, max-- ))
    done
}



printStats() {  # Funcao para printar o output desejado do comando.
    if ! [[ $1 -eq 1 ]] ; then # se o argumento 1 for diferente de 1, imprima normalmente os stats
    printf "%-15s %15s %15s %15s %15s \n" "NETIF" "TX" "RX" "TRATE" "RRATE";
        for ((i=0;i<$itf_length;i++))
        do
            LC_NUMERIC="en_US.UTF-8" printf "%-15s %15d %15d %15.2f %15.2f \n" ${itf_name[i]} ${TxBytes_final[i]} ${RxBytes_final[i]} ${TRate[i]} ${RRate[i]}
        done
    fi

    if [[ $2 -eq 2 ]] ; then # se o argumento 2 for igual a 2, imprima a versao extendida para loop da funcao
        if [[ $3 -eq 3 ]] ; then # se o arg 3 for igual a 3, imprima  o cabecalho inicial.
        printf "%-15s %15s %15s %15s %15s %20s %20s \n" "NETIF" "TX" "RX" "TRATE" "RRATE" "TXTOT" "RXTOT";
        fi

        for ((i=0;i<$itf_length;i++))
        do
            LC_NUMERIC="en_US.UTF-8" printf "%-15s %15d %15d %15.2f %15.2f %20.2f %20.2f \n" ${itf_name[i]} ${TxBytes_final[i]} ${RxBytes_final[i]} ${TRate[i]} ${RRate[i]} ${TXtot[i]}  ${RXtot[i]}
        done
    fi

    
}

# printStats #fot test purposes only

###     Other outputs    ###
gatherData  #armazenando os dados iniciais (necessario armazenar inicialmente para prosseguir com as opcoes de argumentos).
loop=0; # loop setado para falso, se o programa tiver a opcao l, o loop sera ativo e loop=1.
for ((i=0;i<$#;i++))
do
    if [[ ${argumentos[i]} == "-c" ]]; then
        itf_to_delete=(); # array com as interfaces que nao correspondem as que queremos peloa arg -c "itf que queremos"
        tx_i_to_delete=();
        tx_f_to_delete=();
        rx_i_to_delete=();
        rx_f_to_delete=();
        trate_to_delete=();
        rrate_to_delete=();
        itf_index=();
        ###     Tratando de excluir as interfaces que nao correspondem a keyword passada apos -c    ###
        keyword=${argumentos[i+1]};#keyword passada entre "" apos o -c
        for ((i=0;i<${#itf_name[@]};i++)) 
            do
                if ! [[ ${itf_name[i]} =~ ^$keyword$ ]]; then # se o nome nao corresponder a uma interface, adicione ela ao array com as interfaces a serem deletadas
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
        
        ###     Apagando os indices correspondentes as interfaces deletadas dos arrays de TX, RX e Rates      ###
        for ((i=0;i<$itf_length;i++)) 
            do
                if ! [[ ${itf_index[i]} = ${!TxBytes_inicial[i]} && ${itf_index[i]} = ${!TxBytes_final[i]} && ${itf_index[i]} = ${!RxBytes_inicial[i]} && ${itf_index[i]} = ${!RxBytes_final[i]} ]] ; then
                    tx_i_to_delete+=("${TxBytes_inicial[i]}");  
                    tx_f_to_delete+=("${TxBytes_final[i]}");
                    rx_i_to_delete+=("${RxBytes_inicial[i]}"); 
                    rx_f_to_delete+=("${RxBytes_final[i]}");
                    trate_to_delete+=("${TRate[i]}"); 
                    rrate_to_delete+=("${RRate[i]}");
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

        declare -A delk
        for itf in "${trate_to_delete[@]}" ; do delk[$itf]=1 ; done #Array com os itens que deseja deletar
        for k in "${!TRate[@]}" ; do
                [ "${delk[${TRate[$k]}]-}" ] && unset 'TRate[k]'
        done
        TRate=("${TRate[@]}");

        declare -A delk
        for itf in "${rrate_to_delete[@]}" ; do delk[$itf]=1 ; done #Array com os itens que deseja deletar
        for k in "${!RRate[@]}" ; do
                [ "${delk[${RRate[$k]}]-}" ] && unset 'RRate[k]'
        done
        RRate=("${RRate[@]}");

        itf_length=${#itf_name[@]}; # temos que declarar novamente a variavel com o tamanho do array das interfaces, pois este foi alterado (used to do a big messy bug... now fixed!)
        continue;
    fi

    if [[ ${argumentos[i]} == "-b" ]] ; then
        continue;
    fi  

    if [[ ${argumentos[i]} == "-k" ]]; then
        byteConversor 2
        continue;
    fi  

    if [[ ${argumentos[i]} == "-m" ]] ; then
        byteConversor 3
        continue;
    fi                  

    # if [[ ${argumentos[i]} == "-p" ]] ; then

    # fi  

    # if [[ ${argumentos[i]} == "-t" ]]; then

    # fi

    # if [[ ${argumentos[i]} == "-r" ]]; then

    # fi

    # if [[ ${argumentos[i]} == "-T" ]]; then

    # fi

    # if [[ ${argumentos[i]} == "-R" ]]; then

    # fi

    if [[ ${argumentos[i]} == "-v" ]]; then
        reverseArray
        continue;
    fi

    if [[ ${argumentos[i]} == "-l" ]]; then
        loop=1; # variavel que controla se o programa sera executado em modo loop 1 - true | 0 - false
        tempoLoop=${argumentos[i+1]};#tempo de loop passada entre "" apos o -l
        counter=0;
        TXtot=();
        RXtot=();
        while [[ $loop -eq 1 ]]
        do
            TXtot=();
            RXtot=();
            for ((i = 0; i < ${#TRate[@]}; i++))
                do
                    TXtot+=("${TRate[i]}");
                    RXtot+=("${RRate[i]}");
            done

            if [[ $counter -eq 0  ]] ; then
                printStats 1 2 3
                counter+=1;
                echo $'\n'
            fi

            gatherData
            sleep $tempoLoop
            printStats 1 2 0
            echo $'\n'
        done
    fi
done

if [[ $loop -ne 1 ]]; then
    sleepTime
    printStats
fi


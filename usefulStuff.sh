#!/bin/bash
#----------------------------------------------------
#                                                   -
#                  Sistemas Operativos              -
#                   Trabalho Prático 1              -
#                      2021/2022                    -
#                      @Authors:                    -   
#                     Victor Melo                   -                
#                         &                         -
#                   Catarina Marques                -
#                                                   -
#----------------------------------------------------


#  Mandatory numeric argument: number of seconds
echo Arguments: $@
re='^[0-9]+([.][0-9]+)?$';
arguments=( "$@" );
count_ArgNums=0;

sleeping_time=${!#};    # Number of seconds entered by user
# Check if the option is valid. If not, do not proceed 
if [[ $sleeping_time != ?(-)+([0-9]) ]] || [ $sleeping_time -eq 0 ]  ; then
    echo "Error: Please enter the number of seconds."
    exit
fi

sleepTime() {
    echo "Please wait $sleeping_time seconds"
    for ((i = ($sleeping_time), j = 0; i>0, j<$sleeping_time; i--, j++))
        do
            sleep 1
            echo .
    done
    hasSlept=1;
}

# TX, RX, TRATE, RRATE 
gatherData() { 
   
    # Interfaces names - stored in array: itf_name
    IFS=$'\n' read -r -d '' -a itf_name < <( ifconfig -a | grep ": " | awk '{print $1}' | tr -d : && printf '\0' )
    itf_length=${#itf_name[@]} # Number of interfaces

    IFS=$'\n' read -r -d '' -a TxBytes_start < <( ifconfig -a | grep "TX packets " | awk '{print $5}' && printf '\0' ) #
    IFS=$'\n' read -r -d '' -a RxBytes_start < <( ifconfig -a | grep "RX packets " | awk '{print $5}' && printf '\0' )
    sleepTime
    IFS=$'\n' read -r -d '' -a TxBytes_end < <( ifconfig -a | grep "TX packets " | awk '{print $5}' && printf '\0' )
    IFS=$'\n' read -r -d '' -a RxBytes_end < <( ifconfig -a | grep "RX packets " | awk '{print $5}' && printf '\0' )

    TX=()      # TX array
    RX=()      # RX array
    TRate=()   # TRATE array
    RRate=()   # RRATE array

    for ((i=0,j=$itf_length;i<j;i++))   # For each interface calculate TX, RX, TRATE, RRATE
    do
        TX_subtraction=($(( ${TxBytes_end[i]} - ${TxBytes_start[i]} )))
        TX[$i]=$(bc <<<"scale=0; $TX_subtraction");

        RX_subtraction=($(( ${RxBytes_end[i]} - ${RxBytes_start[i]} )))
        RX[$i]=$(bc <<<"scale=0; $RX_subtraction");

        TRate_value="$( echo "scale=1; ${TX[$i]} / $sleeping_time" | bc )"
        TRate+=("$TRate_value");

        RRate_value="$( echo "scale=1; ${RX[$i]} / $sleeping_time" | bc )"
        RRate+=("$RRate_value");
    done
}

# Function that converts the values to kilobytes and megabytes 
# byteConversor() {  
#     if [[ $1 -eq 2 ]] ; then 
#         for ((i=0;i<${#TRate[@]};i++))
#         do
#             if ! [[ ${TRate[i]} = 0 ]] ; then
#             TRate[$i]=$(bc <<<"scale=1; ${TRate[$i]} / 1024");
#             RRate[$i]=$(bc <<<"scale=1; ${RRate[$i]} / 1024");
#             fi
#         done
#     fi
#     if [[ $1 -eq 3 ]]; then 
#         for ((i=0;i<${#TRate[@]};i++))
#         do
#             if ! [[ ${TRate[i]} = 0 ]] ; then
#             TRate[$i]="$( echo "scale=1; ${TRate[$i]} / 1048576" | bc )"
#             RRate[$i]="$( echo "scale=1; ${RRate[$i]} / 1048576" | bc )"
#             fi
#         done
#     fi
# }

# Reversing function 
switchArrayItems() {
    ## NEEDS FIX com -c!
    mn=$1; # min
    mx=$(($2)); # max

    # Switching interfaces names 
    x=${itf_name[$mn]}
    itf_name[$mn]=${itf_name[$mx]}
    itf_name[$mx]=$x

    # Switching TXs
    x=${TX[$mn]}
    TX[$mn]=${TX[$mx]}
    TX[$mx]=$x

    # Switching RXs
    x=${RX[$mn]}
    RX[$mn]=${RX[$mx]}
    RX[$mx]=$x

    # Switching TRATES
    x=${TRate[$mn]}
    TRate[$mn]=${TRate[$mx]}
    TRate[$mx]=$x

    # Switching RRATES
    x=${RRate[$mn]}
    RRate[$mn]=${RRate[$mx]}
    RRate[$mx]=$x

    if [[ $loop -eq 1 ]] ;then
        x=${TXtot[$mn]}
        TXtot[$mn]=${TXtot[$mx]}
        TXtot[$mx]=$x

        x=${RXtot[$mn]}
        RXtot[$mn]=${RXtot[$mx]}
        RXtot[$mx]=$x
    fi
    
}

reverse() {
    if [[ "$itf_length" -gt 1 ]] ; then
        min=0;
        max=$(( $itf_length - 1 ))
        while [[ min -lt max ]]
        do
            switchArrayItems "$min" "$max";
            (( min++, max-- ));
        done
    fi
}
regexSearch() {
        i=$1;
        itf_to_delete=(); 
        tx_f_to_delete=();
        rx_f_to_delete=();
        trate_to_delete=();
        rrate_to_delete=();
        itf_index=();
        itf_length_old=$itf_length;

        # Exclude interfaces that not match the passed keyword in -c  

                 # entered keyword "" after -c
        for ((i=0;i<${#itf_name[@]};i++)) 
            do
                if ! [[ ${itf_name[i]} =~ ^$keyword$ ]]; then # If interface name does not match keyword, add interface name to array to delete
                    itf_to_delete+=("${itf_name[i]}"); # Array with items to delete
                    itf_index+=("$i"); # Store indexes of each network interface to delete TX, RX and Rates arrays
                fi
        done

        declare -A delk
        for itf in "${itf_to_delete[@]}" ; do delk[$itf]=1 ; done # Array with items to delete
        for k in "${!itf_name[@]}" ; do
                [ "${delk[${itf_name[$k]}]-}" ] && unset 'itf_name[k]'
        done
        itf_name=("${itf_name[@]}");
        
        # Delete indexes TX, RX and Rates   
        for ((i=0;i<$itf_length;i++)) 
            do
                if ! [[ ${itf_index[i]} = ${!TxBytes_start[i]} && ${itf_index[i]} = ${!TX[i]} && ${itf_index[i]} = ${!RxBytes_start[i]} && ${itf_index[i]} = ${!RX[i]} ]] ; then
                    tx_f_to_delete+=("${TX[i]}");
                    rx_f_to_delete+=("${RX[i]}");
                    trate_to_delete+=("${TRate[i]}"); 
                    rrate_to_delete+=("${RRate[i]}");
                fi
        done

        declare -A delk
        for itf in "${tx_f_to_delete[@]}" ; do delk[$itf]=1 ; done 
        for k in "${!TX[@]}" ; do
                [ "${delk[${TX[$k]}]-}" ] && unset 'TX[k]'
        done
        TX=("${TX[@]}");

        declare -A delk
        for itf in "${rx_f_to_delete[@]}" ; do delk[$itf]=1 ; done 
        for k in "${!RX[@]}" ; do
                [ "${delk[${RX[$k]}]-}" ] && unset 'RX[k]'
        done
        RX=("${RX[@]}");

        declare -A delk
        for itf in "${trate_to_delete[@]}" ; do delk[$itf]=1 ; done 
        for k in "${!TRate[@]}" ; do
                [ "${delk[${TRate[$k]}]-}" ] && unset 'TRate[k]'
        done
        TRate=("${TRate[@]}");

        declare -A delk
        for itf in "${rrate_to_delete[@]}" ; do delk[$itf]=1 ; done 
        for k in "${!RRate[@]}" ; do
                [ "${delk[${RRate[$k]}]-}" ] && unset 'RRate[k]'
        done
        RRate=("${RRate[@]}");

        if [[ op_p -eq 1 && ${#itf_name[@]} -gt $maxInterfaces ]]; then
            itf_length=$maxInterfaces;
        else
            itf_length=${#itf_name[@]}; # New number of interfaces array declaration
        fi
}

loop() {
    i=$1
    loop=1; # loop=1 --> the program will run in loop mode
     # time between cycles 
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
            sleep $loop_time
            printStats 1 2 0
            echo $'\n'
    done
}

# Function that prints the output
printStats() { 
    if ! [[ $1 -eq 1 ]] ; then # If arg1 equals to '1': standard print 
    printf "%-15s %15s %15s %15s %15s \n" "NETIF" "TX" "RX" "TRATE" "RRATE";
        for ((i=0;i<$itf_length;i++))
        do
            LC_NUMERIC="en_US.UTF-8" printf "%-15s %15.0f %15.0f %15.1f %15.1f \n" ${itf_name[i]} ${TX[i]} ${RX[i]} ${TRate[i]} ${RRate[i]}
        done
    fi

    if [[ $2 -eq 2 ]] ; then        # If arg2 equals to '2': loop print 
        if [[ $3 -eq 3 ]] ; then    # If arg3 equals to '3': header print 
        printf "%-15s %15s %15s %15s %15s %20s %20s \n" "NETIF" "TX" "RX" "TRATE" "RRATE" "TXTOT" "RXTOT";
        fi

        for ((i=0;i<$itf_length;i++))
        do
            LC_NUMERIC="en_US.UTF-8" printf "%-15s %15.0f %15.0f %15.2f %15.1f %20.1f %20.1f \n" ${itf_name[i]} ${TX[i]} ${RX[i]} ${TRate[i]} ${RRate[i]} ${TXtot[i]}  ${RXtot[i]}
        done
    fi
}

###     Other outputs    ###

# gatherData  # Initial data storage

loop=0;     # Loop set to false. If option -l is active then loop=1
for ((i=0;i<$#;i++))
do
    if [[ ${arguments[i]} == "-c" ]]; then
        op_c=1;
        keyword=${arguments[i+1]};
        idx=$1;
        continue;
    fi

    if [[ ${argumentos[i]} == "-b" ]] ; then
        continue;           # If -b continue and 
    fi 

    if [[ ${arguments[i]} == "-k" ]]; then
        byteConversor=2;     # If -k calls the function byteConversor with '2' --> convert to kilobytes            
        continue;
    fi  

    if [[ ${arguments[i]} == "-m" ]] ; then
        byteConversor=3;     # If -m calls the function byteConversor with '3' --> convert to megabytes  
        continue;
    fi                  

    if [[ ${arguments[i]} == "-p" ]] ; then
        op_p=1;
        if [[ ${arguments[i+1]} -ne $sleepTime ]] ; then
            maxInterfaces=${arguments[i+1]};
        elif [[ ${arguments[i+1]} -eq $sleepTime ]] ; then
            echo "-p needs a numeric argument after it."
            exit
        fi

        continue;
    fi  

    # if [[ ${arguments[i]} == "-t" ]]; then
        # op_t=1;
    # fi

    # if [[ ${arguments[i]} == "-r" ]]; then
        # op_r=1;
    # fi

    # if [[ ${arguments[i]} == "-T" ]]; then
        # op_T=1;
    # fi

    # if [[ ${arguments[i]} == "-R" ]]; then
        # op_R=1;
    # fi

    if [[ ${arguments[i]} == "-v" ]]; then
        op_v=1;
        continue;
    fi

    if [[ ${argumentos[i]} == "-l" ]]; then
        loop=1;
        loop_time=${argumentos[i+1]};
        loopClamp=0;
        continue;
    fi

done
# loopClamp?
if [[ $loop -ne 1 ]]; then
    hasSlept=0

    # Interfaces names - stored in array: itf_name
    IFS=$'\n' read -r -d '' -a itf_name < <( ifconfig -a | grep ": " | awk '{print $1}' | tr -d : && printf '\0' )
    itf_length=${#itf_name[@]} # Number of interfaces
    if [[ op_p -eq 1 ]]; then
        itf_length=$maxInterfaces;
    fi

    IFS=$'\n' read -r -d '' -a TxBytes_start < <( ifconfig -a | grep "TX packets " | awk '{print $5}' && printf '\0' ) #
    IFS=$'\n' read -r -d '' -a RxBytes_start < <( ifconfig -a | grep "RX packets " | awk '{print $5}' && printf '\0' )

    if [[ hasSlept -ne 1 ]] ; then
        sleepTime
    fi

    IFS=$'\n' read -r -d '' -a TxBytes_end < <( ifconfig -a | grep "TX packets " | awk '{print $5}' && printf '\0' )
    IFS=$'\n' read -r -d '' -a RxBytes_end < <( ifconfig -a | grep "RX packets " | awk '{print $5}' && printf '\0' )

    TX=()      # TX array
    RX=()      # RX array
    TRate=()   # TRATE array
    RRate=()   # RRATE array

    for ((i=0;i<$itf_length;i++))   # For each interface calculate TX, RX, TRATE, RRATE
    do
        TX_subtraction=($(( ${TxBytes_end[i]} - ${TxBytes_start[i]} )))
        RX_subtraction=($(( ${RxBytes_end[i]} - ${RxBytes_start[i]} )))
        if [[ $byteConversor == 2 ]] ; then
            TX[$i]=$(bc <<<"scale=0; $TX_subtraction / 1024");
            RX[$i]=$(bc <<<"scale=0; $RX_subtraction / 1024");
        elif [[ $byteConversor == 3 ]] ; then
            TX[$i]=$(bc <<<"scale=0; $TX_subtraction / 1048576");
            RX[$i]=$(bc <<<"scale=0; $RX_subtraction / 1048576");
        else
            TX[$i]=$(bc <<<"scale=0; $TX_subtraction");
            RX[$i]=$(bc <<<"scale=0; $RX_subtraction");
        fi

        TRate_value="$( echo "scale=1; ${TX[$i]} / $sleeping_time" | bc )"
        TRate+=("$TRate_value");

        RRate_value="$( echo "scale=1; ${RX[$i]} / $sleeping_time" | bc )"
        RRate+=("$RRate_value");
    done

    if [[ op_v -eq 1 ]]; then
        reverse
    fi

    if [[ op_c -eq 1 ]]; then
        regexSearch $idx
    fi



    printf "%-15s %15s %15s %15s %15s \n" "NETIF" "TX" "RX" "TRATE" "RRATE";
        for ((i=0;i<$itf_length;i++))
        do
            LC_NUMERIC="en_US.UTF-8" printf "%-15s %15.0f %15.0f %15.1f %15.1f \n" ${itf_name[i]} ${TX[i]} ${RX[i]} ${TRate[i]} ${RRate[i]}
        done

    #loopClamp desativado, repita tudo novamente.

fi
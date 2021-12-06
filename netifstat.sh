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
arguments=( "$@" );
loop=0;
sleeping_time=${!#};    # Number of seconds entered by user
# Check if the option is valid. If not, do not proceed 
if [[ $sleeping_time != ?(-)+([0-9]) ]] || [ $sleeping_time -eq 0 ]  ; then
    echo "Error: Please enter the number of seconds."
    exit
fi

###     Functions   ###
sleepTime() {
    echo "Please wait $sleeping_time seconds"
    for ((i = ($sleeping_time), j = 0; i>0, j<$sleeping_time; i--, j++))
        do
            sleep 1
            echo .
    done
    hasSlept=1;
}

switchArrayItems() {
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
        # Switching TRATES Total
        x=${TXtot[$mn]}
        TXtot[$mn]=${TXtot[$mx]}
        TXtot[$mx]=$x
         # Switching RRATES Total
        x=${RXtot[$mn]}
        RXtot[$mn]=${RXtot[$mx]}
        RXtot[$mx]=$x
    fi
}

reverse() {
    arr=("$@");
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

sortItOut() {
    arr=("$@");
    for ((i = 0; i<$itf_length; i++))
    do
        for((j = 0; j<$itf_length-i-1; j++))
        do
            if [ ${arr[j]} -gt ${arr[$((j+1))]} ]
            then
                # swap
                temp=${arr[j]}
                arr[$j]=${arr[$((j+1))]}  
                arr[$((j+1))]=$temp
            fi
        done
    done
    
}

###     Arguments    ##
sortClamp=0;    #   Sort clamp is set to 0, only one sorting method allowed.
loopClamp=0;    #   Loop clamp is default set to 0;
for ((i=0;i<$#;i++))
do
    if [[ ${arguments[i]} == "-c" ]]; then
        op_c=1;
        keyword=${arguments[i+1]};
        idx=$1;
        continue;
    fi

    if [[ ${argumentos[i]} == "-b" ]] ; then
        continue;           # If -b continue 
    fi 

    if [[ ${arguments[i]} == "-k" ]]; then
        byteConversor=2;     # If -k byteConversor=2 --> convert to kilobytes            
        continue;
    fi    

    if [[ ${arguments[i]} == "-m" ]] ; then
        byteConversor=3;     # If -m byteConversor=3 --> convert to megabytes  
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

    if [[ ${arguments[i]} == "-t" ]]; then
            if [[ $sortClamp -gt 1 ]] ; then
            echo "error: only one sorting argument is valid."
            exit
        fi
        op_t=1;
        sortGuide=("${TX[@]}"); #sortItOut by t's
        sortClamp=$(($sortClamp + 1)); #only allow's one sort argument.
        continue;
    fi

    if [[ ${arguments[i]} == "-r" ]]; then
            if [[ $sortClamp -gt 1 ]] ; then
            echo "error: only one sorting argument is valid."
            exit
        fi
        op_r=1;
        sortGuide=("${RX[@]}");#sortItOut by r's
        sortClamp=$(($sortClamp + 1)); #only allow's one sort argument.
        continue;
    fi

    if [[ ${arguments[i]} == "-T" ]]; then
            if [[ $sortClamp -gt 1 ]] ; then
            echo "error: only one sorting argument is valid."
            exit
        fi
        op_T=1;
        sortGuide=("${TRate[@]}"); #sortItOut by T's
        sortClamp=$(($sortClamp + 1)); #only allow's one sort argument.
        continue;
    fi

    if [[ ${arguments[i]} == "-R" ]]; then
            if [[ $sortClamp -gt 1 ]] ; then
            echo "error: only one sorting argument is valid."
            exit
        fi
        op_R=1;
        sortGuide=("${RRate[@]}"); #sortItOut by R's
        sortClamp=$(($sortClamp + 1)); #only allow's one sort argument.
        continue;
    fi

    if [[ ${arguments[i]} == "-v" ]]; then
            if [[ $sortClamp -gt 1 ]] ; then
            echo "error: only one sorting argument is valid."
            exit
        fi
        op_v=1;
        sortClamp=$(($sortClamp + 1)); #only allow's one sort argument.
        continue;
    fi

    if [[ ${arguments[i]} == "-l" ]]; then
        loopClamp=0;
        loop=1;     
        continue;
    fi

done

hasSlept=0
while [[ $loopClamp -eq 0 ]]; do
    
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

    TX=();     # TX array
    RX=();     # RX array
    TRate=();   # TRATE array
    RRate=();   # RRATE array
    TXtot=();
    RXtot=();

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

    for ((i = 0; i < $itf_length; i++))
        do
            TXtot+=("${TRate[i]}");
            RXtot+=("${RRate[i]}");
    done

    if [[ op_v -eq 1 ]]; then
        reverse
    fi

    if [[ op_c -eq 1 ]]; then
        regexSearch $idx
    fi

    if [[ op_t -eq 1 || op_r -eq 1 || op_T -eq 1 || op_R -eq 1 ]]; then
        sortItOut $sortGuide
    fi

    if [[ $loop -eq 1 ]]; then
        printf "%-15s %15s %15s %15s %15s %20s %20s \n" "NETIF" "TX" "RX" "TRATE" "RRATE" "TXTOT" "RXTOT";
        for ((i=0;i<$itf_length;i++))
            do
                LC_NUMERIC="en_US.UTF-8" printf "%-15s %15.0f %15.0f %15.1f %15.1f %20.1f %20.1f \n" ${itf_name[i]} ${TxBytes_final[i]} ${RxBytes_final[i]} ${TRate[i]} ${RRate[i]} ${TXtot[i]}  ${RXtot[i]}
            done
        printf "\n"
        numbTimes+=1
        sleep $sleeping_time
    else
        printf "%-15s %15s %15s %15s %15s \n" "NETIF" "TX" "RX" "TRATE" "RRATE";
        for ((i=0;i<$itf_length;i++))
        do
            LC_NUMERIC="en_US.UTF-8" printf "%-15s %15.0f %15.0f %15.1f %15.1f \n" ${itf_name[i]} ${TX[i]} ${RX[i]} ${TRate[i]} ${RRate[i]}
        done
        printf $'\n'
        echo "saindo do loop" $loopClamp
        break
    fi
done
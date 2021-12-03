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

sleepTime(){
    echo "Please wait $sleeping_time seconds"
    for ((i = ($sleeping_time), j = 0; i>0, j<$sleeping_time; i--, j++))
        do
            sleep 1
            echo .
    done
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
byteConversor() {  
    if [[ $1 -eq 2 ]] ; then 
        for ((i=0;i<${#TRate[@]};i++))
        do
            if ! [[ ${TRate[i]} = 0 ]] ; then
            TRate[i]="$( echo "scale=1; ${TRate[i]} / 1024" | bc )"
            RRate[i]="$( echo "scale=1; ${RRate[i]} / 1024" | bc )"
            fi
        done
    fi
    if [[ $1 -eq 3 ]]; then 
        for ((i=0;i<${#TRate[@]};i++))
        do
            if ! [[ ${TRate[i]} = 0 ]] ; then
            TRate[i]="$( echo "scale=1; ${TRate[i]} / 1048576" | bc )"
            RRate[i]="$( echo "scale=1; ${RRate[i]} / 1048576" | bc )"
            fi
        done
    fi
}

# Reversing function 
reverseArray() {
    ## NEEDS FIX com -c!
    mn=$1; # min
    mx=$(($2)); # max

    # Switching interfaces names 
    x=${itf_name[$mn]}
    itf_name[$mn]=${itf_name[$mx]}
    itf_name[$mx]=$x

    # Switching TXs
    x=${TxBytes_end[$mn]}
    TxBytes_end[$mn]=${TxBytes_end[$mx]}
    TxBytes_end[$mx]=$x

    # Switching RXs
    x=${RxBytes_end[$mn]}
    RxBytes_end[$mn]=${RxBytes_end[$mx]}
    RxBytes_end[$mx]=$x

    # Switching TRATES
    x=${TRate[$mn]}
    TRate[$mn]=${TRate[$mx]}
    TRate[$mx]=$x

    # Switching RRATES
    x=${RRate[$mn]}
    RRate[$mn]=${RRate[$mx]}
    RRate[$mx]=$x
    
}

loop() {
    loop=1; # loop=1 --> the program will run in loop mode
    loop_time=${argumentos[i+1]}; # time between cycles 
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

gatherData   # Initial data storage
loop=0;      # Loop set to false. If option -l is active then loop=1

for ((i=0;i<$#;i++))
do
    if [[ ${arguments[i]} == "-c" ]]; then
        itf_to_delete=(); 
        tx_i_to_delete=();
        tx_f_to_delete=();
        rx_i_to_delete=();
        rx_f_to_delete=();
        trate_to_delete=();
        rrate_to_delete=();
        itf_index=();

        # Exclude interfaces that not match the passed keyword in -c  

        keyword=${arguments[i+1]};          # entered keyword "" after -c
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
                if ! [[ ${itf_index[i]} = ${!TxBytes_start[i]} && ${itf_index[i]} = ${!TxBytes_end[i]} && ${itf_index[i]} = ${!RxBytes_start[i]} && ${itf_index[i]} = ${!RxBytes_end[i]} ]] ; then
                    tx_i_to_delete+=("${TxBytes_start[i]}");  
                    tx_f_to_delete+=("${TxBytes_end[i]}");
                    rx_i_to_delete+=("${RxBytes_start[i]}"); 
                    rx_f_to_delete+=("${RxBytes_end[i]}");
                    trate_to_delete+=("${TRate[i]}"); 
                    rrate_to_delete+=("${RRate[i]}");
                fi
        done

        declare -A delk
        for itf in "${tx_i_to_delete[@]}" ; do delk[$itf]=1 ; done 
        for k in "${!TxBytes_start[@]}" ; do
                [ "${delk[${TxBytes_start[$k]}]-}" ] && unset 'TxBytes_start[k]'
        done
        TxBytes_start=("${TxBytes_start[@]}");

        declare -A delk
        for itf in "${tx_f_to_delete[@]}" ; do delk[$itf]=1 ; done 
        for k in "${!TxBytes_end[@]}" ; do
                [ "${delk[${TxBytes_end[$k]}]-}" ] && unset 'TxBytes_end[k]'
        done
        TxBytes_end=("${TxBytes_end[@]}");

        declare -A delk
        for itf in "${rx_i_to_delete[@]}" ; do delk[$itf]=1 ; done 
        for k in "${!RxBytes_start[@]}" ; do
                [ "${delk[${RxBytes_start[$k]}]-}" ] && unset 'RxBytes_start[k]'
        done
        RxBytes_start=("${RxBytes_start[@]}");

        declare -A delk
        for itf in "${rx_f_to_delete[@]}" ; do delk[$itf]=1 ; done 
        for k in "${!RxBytes_end[@]}" ; do
                [ "${delk[${RxBytes_end[$k]}]-}" ] && unset 'RxBytes_end[k]'
        done
        RxBytes_end=("${RxBytes_end[@]}");

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

        itf_length=${#itf_name[@]}; # New number of interfaces array declaration
        continue;
    fi

    # OPTIONS

    if [[ ${argumentos[i]} == "-b" ]] ; then
        continue;           # If -b continue and 
    fi 

    if [[ ${arguments[i]} == "-k" ]]; then
        byteConversor 2     # If -k calls the function byteConversor with '2' --> convert to kilobytes            
        continue;
    fi  

    if [[ ${arguments[i]} == "-m" ]] ; then
        byteConversor 3     # If -m calls the function byteConversor with '3' --> convert to megabytes  
        continue;
    fi                  

    # if [[ ${arguments[i]} == "-p" ]] ; then

    # fi  

    # if [[ ${arguments[i]} == "-t" ]]; then

    # fi

    # if [[ ${arguments[i]} == "-r" ]]; then

    # fi

    # if [[ ${arguments[i]} == "-T" ]]; then

    # fi

    # if [[ ${arguments[i]} == "-R" ]]; then

    # fi

    if [[ ${arguments[i]} == "-v" ]]; then
        min=0;
        max=$(( $itf_length -1 ))
        while [[ min -lt max ]]
        do
            reverseArray "$min" "$max";
            (( min++, max-- ));
        done
    fi

    if [[ ${argumentos[i]} == "-l" ]]; then
        loop
        continue;
    fi

done

if [[ $loop -ne 1 ]]; then
    printStats
fi
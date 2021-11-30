#!/bin/bash

#BRUNO E MARCEL

#Função auxiliar que troca os elementos dos diversos arrays de lugar
SwapArray() {
        #$1 vai ser o j
        j=$1;
        #j plus one
        k=$2;

        #Trocar o array das interfaces
        temp=${NETIF_array[$j]};
        NETIF_array[$j]=${NETIF_array[$k]};
        NETIF_array[$k]=$temp;

        #Trocar o array do RX_array
        temp=${RX_array[$j]};
        RX_array[$j]=${RX_array[$k]};
        RX_array[$k]=$temp;

        #Trocar o array do TX_array
        temp=${TX_array[$j]};
        TX_array[$j]=${TX_array[$k]};
        TX_array[$k]=$temp;

        #Trocar o array do RRATE_array
        temp=${RRATE_array[$j]};
        RRATE_array[$j]=${RRATE_array[$k]};
        RRATE_array[$k]=$temp;

        #Trocar o array do TRATE_array
        temp=${TRATE_array[$j]};
        TRATE_array[$j]=${TRATE_array[$k]};
        TRATE_array[$k]=$temp;

        #Trocar o array do RXTOT_array
        temp=${RXTOT_array[$j]};
        RXTOT_array[$j]=${RXTOT_array[$k]};
        RXTOT_array[$k]=$temp;

        #Trocar o array do TXTOT_array
        temp=${TXTOT_array[$j]};
        TXTOT_array[$j]=${TXTOT_array[$k]};
        TXTOT_array[$k]=$temp;
}

#Função que ordena os diversos arrays de acordo com o RX
SortArrays () {
    sortFlag=$1;
    reverseFlag=$2;
    N=$3;

    #Bubble sort genérico
    for (( i = 0; i < $N; i++ )); do
        flag=0;
        for ((j = 0; j < $N-$i-1; j++ )); do

            #estabelece os operandos de acordo com o flag
            operand1=0;
            operand2=0;

            case $sortFlag in
                abc)
                    operand1=1;
                    operand2=0;

                    string1=${NETIF_array[$j]};
                    string2=${NETIF_array[$j+1]};

                    #pega o menor tamanho entre os dois arrays
                    length=${#string1};
                    if [ ${#string2} -lt $length ]; then
                        length=${#string2}
                    fi

                    for (( k = 0; k < $length; k++ )); do
                        char1=${operand1:$k:1};
                        char2=${operand2:$k:1};

                        val1=$(printf "%d\n" "'$char1");
                        val2=$(printf "%d\n" "'$char2");

                        if [ $val1 -lt $val2 ]; then
                        #Troca os arrays de posição
                        operand1=0;
                        operand2=1;
                        break;
                        fi
                    done

                    ;;
                t)
                    operand1=${TX_array[$j]};
                    operand2=${TX_array[$j+1]};
                    ;;

                r)
                    operand1=${RX_array[$j]};
                    operand2=${RX_array[$j+1]};
                    ;;

                T)
                    operand1=${RRATE_array[$j]};
                    operand2=${RRATE_array[$j+1]};
                    ;;

                R)
                    operand1=${TRATE_array[$j]};
                    operand2=${TRATE_array[$j+1]};
                    ;;
            esac

            #Ordenação no sentido normal
            if [[ $(bc <<<"$operand1<$operand2") -eq 1 ]]; then
                #Troca os arrays de posição
                SwapArray "$j" ""$(($j+1));

                flag=1;
                continue;
            fi

        done
        if [[ $flag -eq 0 ]]; then
            break;
        fi
    done

    #Reverte o array se a flag da reversão estiver ligada
    if [[ $reverseFlag -eq 1 ]]; then
        min=0;
        max=$(( $N -1 ))

        while [[ min -lt max ]]
        do
            # Swap current first and last elements
            SwapArray "$min" "$max";

            # Move closer
            (( min++, max-- ));
        done
    fi
}

#PONTO DE ENTRADA DO PROGRAMA#

#A opção dos segundos é sempre o último parãmetro.
sleepInterval=${!#};

#Checando se a opção dos segundos é valida. Se não for, não prosseguir.
if [[ $sleepInterval != ?(-)+([0-9]) ]] || [ $sleepInterval -eq 0 ]  ; then
    echo "O parâmetro 'número de segundos' é obrigatório e deve ser um número natural não nulo."
    exit
fi

#Tratando as opções passadas para o programa e estabelendo as flags lógicas
byteFactor=1; #Integral que vai dividir as informações de byte tirada das interfaces; Responsável pela conversão de byte para kilobytes e megabytes

interfaceMaxIndex=0;
interfaceMax=1000;  #o numero máximo de interfaces para mostrar

sortFlag="abc";   #string que representa qual dos arrays deve ser avaliado para determinar a ordem do sort; por padrão é por ordem alfabética
reverseFlag=0; #0 é falso, 1 é verdadeiro
loopFlag=0; #ditto ^

index=0;    #posição da opção sendo iterada; Usada para ter acesso à opção seguinte (-c e -p)
expressionIndex=0;    #posição da opção que contem a expressão de seleção de interface
regex="n/a"; #string que guarda a expressão normal para seleção de interface

#Trocar o if por um case switch?
for option in "$@"; do

    #Incrementa o contador
    index=$(($index+1));

    #-c; Seleciona uma interface
    if [[ $option == "-c" ]]; then
        if [ $(($index+1)) -lt $# ] && [ -n ${expressionIndex} ]; then
            expressionIndex=$(($index + 1))
        fi
        continue;
    fi

    #-b; Mostra as informações em byte
    if [[ $option == "-b" ]]; then
        byteFactor=1;
        continue;
    fi

    #-k; Mostra as informações em byte
    if [[ $option == "-k" ]]; then
        byteFactor=1000;
        continue;
    fi

    #-p; Controla a quantidade max de interfaces
    if [[ $option == "-p" ]]; then
        if [ $(($index+1)) -lt $# ]; then
            interfaceMaxIndex=$(($index + 1));
        fi
        continue;
    fi

    #-m; Mostra as informações em byte
    if [[ $option == "-m" ]]; then
        byteFactor=1000000;
        continue;
    fi

    #-t; Ordena por TX
    if [[ $option == "-t" ]]; then
        sortFlag='t';
        continue;
    fi

    #-r; Ordena por RX
    if [[ $option == "-r" ]]; then
        sortFlag='r';
        continue;
    fi

    #-T; Ordena por TRate
    if [[ $option == "-T" ]]; then
        sortFlag='T';
        continue;
    fi

    #-R; Ordena por RRate
    if [[ $option == "-R" ]]; then
        sortFlag='R';
        continue;
    fi

    #-v; Inverte a ordem do sort
    if [[ $option == "-v" ]]; then
        #Inverte o valor lógico da flag, caso o usuário NETIF_arraycoloque -v mais de uma vez.
        let "reverseFlag -= 1"
        reverseFlag=${reverseFlag#-};
        continue;
    fi

    #-l; Programa roda em loop
    if [[ $option == "-l" ]]; then
        #Inverte o valor lógico da flag, caso o usuário coloque -l mais de uma vez.
        let "loopFlag -= 1"
        loopFlag=${loopFlag#-};
        continue;
    fi

    #receber a expressão de seleção
    if [ $index -eq $expressionIndex ]; then
        regex=$option;
        continue;
    fi

    #receber o maximo de interfaces
    if [ $index -eq $interfaceMaxIndex ] && [[ $option == ?(-)+([0-9]) ]]; then
        interfaceMax=$option;
        continue;
    fi
done

#Essa declaração de arrays vem antes do loop porque ele deve se manter entre suas interações.
#Array do RXTOT
RXTOT_array=();
#Array do TXTOT
TXTOT_array=();
#Uma flag para popular os arrays RXTOT E TXTOT com zeros na primeira iteração
zeroLatch=1;

#ESSE BLOCO ADIANTE VAI SER LOOPADO INFINITAMENTE COM O INTERVALO DADO PELO UTILIZADOR SE A FLAG DE LOOP ESTIVER LIGADA.
loopLatch=1;
firstIteration=1;
while [ $loopLatch -eq 1 ]; do
    #Desativar a trava se a falg do loop estiver desligada.
    loopLatch=$loopFlag;

    #DECLARA TODOS OS ARRAYS RESPONSÁVEL PELA ESTRUTURA DE DADOS#
    #Array dos nomes das interfaces
    IFS=$'\n' read -r -d '' -a NETIF_array < <( ifconfig -a | grep ": " | awk '{print $1}' | tr -d : && printf '\0' )
    N=${#NETIF_array[@]};   #tamanho do array

    #Array ANTIGO do RX
    IFS=$'\n' read -r -d '' -a RX_array_OLD < <( ifconfig -a | grep "RX packets" | awk '{print $5}' | tr -d : && printf '\0' )

    #Array ANTIGO do TX
    IFS=$'\n' read -r -d '' -a TX_array_OLD < <( ifconfig -a | grep "TX packets" | awk '{print $5}' | tr -d : && printf '\0' )

    #Pausa o programa pela quantidade especificada pelo usuário.
    if [ $firstIteration -eq 1 ]; then
        echo "Aguarde $sleepInterval segundo(s)..."
    else
        echo "";
    fi
    sleep $sleepInterval;

    #Array NOVO do RX
    IFS=$'\n' read -r -d '' -a RX_array < <( ifconfig -a | grep "RX packets" | awk '{print $5}' | tr -d : && printf '\0' )

    #Array NOVO do TX
    IFS=$'\n' read -r -d '' -a TX_array < <( ifconfig -a | grep "TX packets" | awk '{print $5}' | tr -d : && printf '\0' )

    #Array do R Rate
    RRATE_array=();
    #Array do T Rate
    TRATE_array=();

    #Se o número de interfaces coletada exceder a quantidade de interfaces permitida pelo usuário (parâmetro -p), então clamp.
    if [ $N -gt $interfaceMax ]; then
        N=$interfaceMax;
    fi

    #Estabelecer o R e T rate para cada interface
    for (( i=0; i < $N; i++ )); do
        #Tira a diferença do RX antes e depois.
        RDif=($((RX_array[$i]-RX_array_OLD[$i])));
        #O novo valor do RX_Array[i] vai ser a diferença DIVIDIDO pela variável responsável pela conversão de b para kb e mb.
        RX_array[$i]=$(bc <<<"scale=0;$RDif/$byteFactor");
        #O valor do RRATE_array[i] vai ser a diferença dividida pela quantidade em segundos que o programa esperou, para conseguir a taxa.
        RRATE_array[$i]=$(bc <<<"scale=1;($RDif/$byteFactor)/$sleepInterval");

        #A mesma coisa mas com o TX.
        TDif=($((TX_array[$i]-TX_array_OLD[$i])));
        TX_array[$i]=$(bc <<<"scale=0;$TDif/$byteFactor");
        TRATE_array[$i]=$(bc <<<"scale=1;($TDif/$byteFactor)/$sleepInterval");

        #Incrementa os valores de TXTOT e RXTOT pela diferença (somente se a flag loop estiver ligada)
        if [ $loopFlag -eq 1 ]; then

            #Popula com zero se necessário
            if [ $zeroLatch -eq 1 ]; then
                RXTOT_array[$i]=0;
                TXTOT_array[$i]=0;
            fi

            var1=${RXTOT_array[$i]};
            var2=${RX_array[$i]};
            RXTOT_array[$i]=$(bc <<< "scale=2;$var1+$var2")

            var1=${TXTOT_array[$i]};
            var2=${TX_array[$i]};
            TXTOT_array[$i]=$(bc <<< "scale=2;$var1+$var2")
        fi

    done

    #Ordenar o array
    SortArrays "$sortFlag" "$reverseFlag" "$N"

    #Printar a tabela

    #Faz o print na formatação SEM a flag loop
    if [ $loopFlag -eq 0 ]; then
        printf "%-10s %10s %10s %10s %10s\n" "NETIF" "TX" "RX" "TRATE" "RRATE";
        for (( i=0; i < $N; i++ )); do
            #Não printar a interface se ela não se encaixa no regex
            if [ $regex == "n/a" ] || [[ ${NETIF_array[$i]} =~ ^$regex$ ]]; then
                printf "%-10s %10s %10s %10s %10s\n" ${NETIF_array[$i]} ${TX_array[$i]} ${RX_array[$i]} ${TRATE_array[$i]} ${RRATE_array[$i]};
            fi
        done
    #Faz o print na formatação COM a flag loop
    else
        printf "%-10s %10s %10s %10s %10s %10s %10s\n" "NETIF" "TX" "RX" "TRATE" "RRATE" "TXTOT" "RXTOT";
        for (( i=0; i < $N; i++ )); do
            #Não printar a interface se ela não se encaixa no regex
            if [ $regex == "n/a" ] || [[ ${NETIF_array[$i]} =~ ^$regex$ ]]; then
                    printf "%-10s %10s %10s %10s %10s %10s %10s\n" ${NETIF_array[$i]} ${TX_array[$i]} ${RX_array[$i]} ${TRATE_array[$i]} ${RRATE_array[$i]} ${TXTOT_array[$i]} ${RXTOT_array[$i]};
            fi
        done
    fi

    #Desliga a flag de popular os TXTOT e RXTOT com zeros
    zeroLatch=0;
    firstIteration=0;
done
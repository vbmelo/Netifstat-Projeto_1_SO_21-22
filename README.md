# Netifstat-Projeto_1_SO_21.22
Projeto da Cadeira de Sistemas Operativos, ano letivo 2021/2022. Foco em fazer um comando para terminal UNIX em BASH, Monitorização de interfaces de rede em bash.
Due untill 06/12/2021

O script netifstat.sh permite a visualização da quantidade de dados transmitidos e
recebidos nas interfaces de rede selecionadas e as respetivas taxas de transferência para períodos de
tempo pré-estabelecidos. Este script tem um parâmetro obrigatório que é o número de segundos que
serão usados para calcular as taxas de transferência. A selecção das interfaces de rede a visualizar
pode ser realizada através de uma expressão regular (opção -c). A visualização pode ser realizada em
bytes (opção -b), kilobytes (opçao -k) ou megabytes (opção -m). A visualização está formatada
como uma tabela, com um cabeçalho, aparecendo as interfaces de rede por ordem alfabética. O
número de interfaces a visualizar é controlado pela opção -p. Existem opções para alterar a
ordenação da tabela (-t – sort on TX↑, -r – sort on RX↑, -T – sort on TRATE↑, -R – sort on
RRATE↑ e -v – reverse). Quando é usada a opção -l, o script deve funcionar em loop, sem
terminar, imprimindo a cada s segundos nova informação. Neste caso (uso da opção -l), a tabela deve
ter mais 2 colunas que indicam as quantidades de dados transmitidos e recebidos desde o início da
execução do script, enquanto que as colunas que já existiam se referem sempre aos últimos s
segundos.

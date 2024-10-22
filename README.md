# Projeto1-SO
 PRIMEIRA VEZ DE EXECUCAO-> copiar todos os ficheiros e diretorias (bem todos os ficheiro/diretorias descendentes desta) para a diretoria "backup"

EXECUCOES SEGUINTES-> copiar apenas os ficheiros novos e os que foram modificados (estes vao substiruir os existentes e podem er detetados comparando as datas de modificacao)-> se algum ficheiro deixar de existir deve ser eliminado no backup-> nao sao guardadas as datas de modificacao de diretorias, apenas de ficheiros

-> Cada comando cp deve copiar apenas um ficheiro e deve usar a opção -a para que sejam preservadas as datas de modificação.

--------------------------------------------------

exemplo output:

cp -a src/audio.mp3 bak1/audio.mp3
mkdir bak1/dirA
cp -a src/dirA/code.c bak1/dirA/code.c
While backuping src/dirA: 0 Errors; 0 Warnings; 0 Updated; 1 Copied (2500B); 0 Deleted (0B)

-------------------------------------------------

-> 2 parametros entrada (diretoria dos ficheiros a copiar e diteroria destino de backup)
-> -c para listar todos os comandos usados na execucao do script
-> [-b tfile] avaliar so os ficheiro com tfile expressao regular
-> [-r regexpr] indica que apenas devem ser copiados os ficheiros que verificam uma expressão regular
------------------------
./backup.sh [-c] [-b tfile] [-r regexpr] dir_trabalho dir_backup
------------------------

FASES

-> backup_files.sh
    
backup so de ficheiros e atualizacao dos alterados
so tem o -c

-> backup.sh
    
ficheiros + diretorias + subdiretorias
ja tem o -c, -b e -r
dica?: "o script backup.sh pode invocar-se a si próprio recursivamente"

-> backup_summary.sh
    
acresce a formatacao de saida com "While backuping src/dirA: 0 Errors; 0 Warnings; 0 Updated; 1 Copied (2500B); 0 Deleted (0B)"
-> backup_check.sh
    
verifica se o conteúdo dos ficheiros na diretoria de backup é igual ao conteúdo dos ficheiros correspondentes na diretoria de trabalho usando o comando md5sum
se for detetado um erro impromir algo tipo "src/text.txt bak1/text.txt differ."


-----------------------------

para comprar datas:
date -d "Tue Oct 15 08:49:09" + %s
devolve um numero e podemos guardar em variaveis e comparar assim

para o -b que e suposto procurar os files que tem tfile expressao regular:
$a=shop
$if [[ $a =~ so ]]; then echo MATCH; fi
#compara se $a tem a expressao so

saber se onfile e mais recente que outro ou nao:
if [[$f1 -nt $f2]]; then

os hidden files tambem tem de ser copiados

#variaveis para flags
checking=false
exclude_check=false
exclude_file=""
regexpr=""
regexpr_check=false
#variaveis para summary
errors=0
warnings=0
updated=0
copied=0
copied_size=0
deleted=0
deleted_size=0

function main(){
    #nao consegui por isto numa função a parte
    while getopts ":cb:r:" opt; do
        case ${opt} in 
            c)
                checking=true
                ;;
            b)
                exclude_check=true
                exclude_file="$OPTARG"
                
                ;;
            r)
                regexpr_check=true
                regexpr="$OPTARG"
                ;;
            \?)
                echo "Invalid option"
                exit 1
                ;;
        esac
    done
    shift $((OPTIND - 1))
    
    check_arg_amt "$@"
    src_dir="$1"
    dst_dir="$2"
    
    check_arg_path

    backup_folder="$dst_dir/backup"
    if check_backup_existence ; 
    then
        echo "o check funciona"
        do_initial_backup "$backup_folder"
    else
        echo "o backup existe"
        compare "$backup_folder" "$src_dir"
    fi
    summary
}
function size(){
    arg=$1
    file="${arg#?}"
    if [ -f $file ]; then
        size=$(du -sb $file | cut -f1)
    else
        size=$(find $file -type f -exec stat --format="%s" {} + | awk '{s+=$1} END {print s}')
    fi

    if [[ "$arg" == c* ]]; then     #c para copy
        ((copied_size=$copied_size + $size))
    elif [[ "$arg" == d* ]]; then   #d para delete
        ((deleted_size=$copied_size + $size))
    fi


}
#function warning(){
    #ainda nao sei
#}
function summary(){
    echo "$errors Errors; $warnings Warnings; $updated Updated; $copied Copied ($copied_size B); $deleted Deleted ($deleted_size B)"
}

#flag -c
function simulation()
{
   
    if $checking; then
        echo "$*"
    else
        "$@"
    fi
}
#Temos de checkar se o número de argumentos é válido
function check_arg_amt()
{
    
    if [ $# != 2 ]; 
    then
        echo -e "\033[31mThe number of arguments is wrong.\033[0m"
        exit 1
    fi

}


#checkar se os diretórios dados sao válidos
function check_arg_path()
{
    if [ ! -d "$src_dir" ] || [ ! -d "$dst_dir" ]; 
    then 
         echo -e "\033[31mThe directories inputed do not exist.\033[0m"
         exit 1
    fi

}

function check_backup_existence()
{

    if [ -d "$dst_dir/backup" ];
    then
        return 1;
    fi

    return 0;
}


function do_initial_backup()
{
    new_folder=$1
    simulation mkdir -p "$new_folder"
    
    compare "$new_folder" "$src_dir"  #estavasse a duplicar e nao a ler cada file, nao era o suposto duplicar
    
}

#flag -b
function exclude()
{
        
    #ja funciona, aqui o problema era o file excluir vir do windows, por isso nao
    #estava no formato certo
    for line in $(cat "$exclude_file"); do
        line="${line//$'\r'/}" #tira o \r do formato do windows
        if [[ "$1" == "$line" ]]; then
            return 0
        fi
    done


    return 1
}

#flag -r
function choose()
{
    if [[ "$1" =~ "$regexpr" ]]; then
        return 1
    fi
    return 0
}


function compare_data()
{
    src_file=$1
    dst_file=$2

    if [  "$src_file" -nt "$dst_file" ] && [ "$(stat -c %Y "$src_file")" -ne "$(stat -c %Y "$dst_file")" ]; #isto esta horrivel mas é a unica maneira que encontrei para nao assumir source novo quando na realidade sao iguais
    then
        echo "source mais novo"
        return 0;
    elif [  "$src_file" -ot "$dst_file" ] ; then
        echo "backup mais novo"
        ((warnings+=1))
        #warning "$src_file" "$dst_file"
        return 1
    fi
    echo "iguais"
    return 1
    
}

function make_directory(){
    dst_dir=$1
    dir_name=$2
    new_dir="$dst_dir/$dir_name"

    simulation mkdir -p "$new_dir" 
   

}
function delete(){
    src_dir=$1
    dst_dir=$2

    for file in $(find "$dst_dir" -mindepth 1 -maxdepth 1); do
        file_name=$(basename "$file")
        if [ -z "$(ls -A "$dst_dir")" ]; then
            continue
        fi

        
        if [ -d "$dst_dir/$file_name" ] && [ ! -d "$src_dir/$file_name" ]; then
            echo "Removendo a $file_name do $dst_dir, não existe em $src_dir"
            num_files=$(find $file -type f | wc -l)
            ((deleted= $deleted + $num_files))
            size "d$file"   #este d serve para distinguir entre delete e copy na função
            simulation rm -r "$file"
        elif [ ! -f "$src_dir/$file_name" ] && [ -f "$dst_dir/$file_name" ]; 
        then
            echo "Removendo $file_name do $dst_dir, não existe em $src_dir"
            ((deleted+=1))
            size "d$file"   #este d serve para distinguir entre delete e copy na função
            simulation rm "$file" 
        fi
       
    done
}
function compare()
{
    dst_dir=$1
    src_dir=$2

    #analisar files de fonte->backup
    for file in $(find "$src_dir" -mindepth 1 -maxdepth 1); do
        file_name=$(basename "$file")
        if [ -z "$(ls -A "$src_dir")" ]; then
            continue
        fi
        #funciona recursivamente para todos os ficheiros dentro de outras direitorias
        #MUITO IMPORTANTE PARA O PC NAO ARREBENTAR
        #!!!muda para a cena ca em baixo porque assim nao triplica o ficheiro backup !!!!
        #./backup.sh  "/mnt/c/Users/franc/Documents/GitHub/Projeto1-SO/tests/test1" "/mnt/c/Users/franc/Documents/GitHub/Projeto1-SO/test2"
        if [[  -d "$file" ]]; then
            make_directory "$dst_dir" "$file_name" 
            new_dir="$dst_dir/$file_name"
            if compare "$new_dir" "$src_dir/$file_name"; then
                dst_dir=$1      #fui redundante aqui mas honestaemnte nao sabia como fazer de outra maneira
                src_dir=$2      #assim ao sair da recursiva com o return 0 de quando sai dos for ele retoma com os diretorios normais e continua de onde tinha deixado
                continue
            fi
        fi
        
        #exclude the file and procede with the next file
        if  [[ "$exclude_check" == true ]];
        then
        if  exclude "$file_name" ;
            then 
            continue
        fi
        fi

        if  [[ "$regexpr_check" == true ]];
        then
        if  choose "$file_name" ;
            then 
            continue
        fi
        fi

        src_file="$src_dir/$file_name"
        
        
        if [ -f "$dst_dir/$file_name" ]; 
        then
            
            dst_file="$dst_dir/$file_name"
            if compare_data "$src_file" "$dst_file" ; 
            then #executa quando retornar 0
            echo "substitui"
                ((updated+=1))
                simulation cp -a "$src_file" "$dst_file" #substitui o ficheiro 2 com o 1
            fi
        else
        echo "criei"
        ((copied+=1))
            size "c$src_file"   #este c serve para distinguir entre delete e copy na função
            simulation cp -a "$src_file" "$dst_dir" 
        fi

    done

 #analisar files de backup->fonte
    delete "$src_dir" "$dst_dir"
    
    return 0
}
main "$@"
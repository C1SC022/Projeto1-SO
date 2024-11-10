checking=false



function main(){
    #nao consegui por isto numa função a parte
    while getopts ":cb:r:" opt; do
        case ${opt} in 
            c)
                checking=true
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
        compare "$backup_folder"
        delete "$src_dir" "$backup_folder"
    fi
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
    
    compare "$new_folder"   #estavasse a duplicar e nao a ler cada file, nao era o suposto duplicar
    exit 0
}




function compare_data()
{
    src_file=$1
    dst_file=$2

    if [  "$src_file" -nt "$dst_file" ];
    then
        echo "source mais novo"
        return 0;
    elif [  "$dst_file" -nt "$src_file" ] ; then
        echo "backup mais novo"
        return 1
    else
    echo "iguais"
    return 1
    fi
}

function delete(){
    src_dir=$1
    dst_dir=$2

    IFS=$'\n'
    for file in $(find "$dst_dir" -mindepth 1 -maxdepth 1); do
    unset IFS
        if [[ ! -f "$file" ]]; then
            continue
        fi
        file_name=$(basename "$file")

        
       if [ ! -f "$src_dir/$file_name" ]; 
        then
            echo "Removendo $file_name do $dst_dir, não existe em $src_dir"
            simulation rm "$file" 
        fi
       
    done
}

function compare()
{
    dst_dir=$1
    IFS=$'\n'
    #analisar files de fonte->backup
    for file in $(find "$src_dir" -mindepth 1 -maxdepth 1); do
    unset IFS
        if [[ ! -f "$file" ]]; then
            continue
        fi
        file_name=$(basename "$file")
        
        

        src_file="$src_dir/$file_name"
        
        
        if [ -f "$dst_dir/$file_name" ]; 
        then
            
            dst_file="$dst_dir/$file_name"
            if compare_data "$src_file" "$dst_file" ; 
            then #executa quando retornar 0
            echo "substitui"
                simulation cp -a "$src_file" "$dst_file" #substitui o ficheiro 2 com o 1
            fi
        else
        echo "criei"
            simulation cp -a "$src_file" "$dst_dir" 
        fi

    done

 
    
}


main "$@"

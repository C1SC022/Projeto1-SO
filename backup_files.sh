src_dir="$1"
dst_dir="$2"


function main(){

    check_arg_amt "$@"
    check_arg_path

    backup_folder="$dst_dir/backup"
    if check_backup_existence ; 
    then
        echo "o check funciona"
        do_initial_backup "$backup_folder"
    else
        echo "o backup existe"
        compare "$backup_folder"
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
    mkdir -p "$new_folder"

    find "$src_dir" -maxdepth 1 -type f -exec cp {} "$new_folder" \;
    echo -e "The files in \033[33m$src_dir\033[0m have been copied to the \033[32m$new_folder\033[0m directory."
    exit 0
}


function compare_data()
{
    src_file=$1
    dst_file=$2

    if [ "$src_file" -nt "$dst_file" ]; 
    then
        echo "source mais novo"
        return 0;
    fi
echo "backup mais novo"
    return 1;
}

function compare()
{
    dst_dir=$1

    #analisar files de fonte->backup
    for file in "$src_dir"/*; do
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
                cp -a "$src_file" "$dst_file" #substitui o ficheiro 2 com o 1
            fi
        else
        echo "criei"
            cp -a "$src_file" "$dst_dir" 
        fi

    done

 #analisar files de backup->fonte
    for file in "$dst_dir"/*; do
        file_name=$(basename "$file")
        

       if [ ! -f "$src_dir/$file_name" ]; 
        then
            echo "Removendo $file_name do $dst_dir, não existe em $src_dir"
            rm "$file" 
        fi
    done
}


main "$@"

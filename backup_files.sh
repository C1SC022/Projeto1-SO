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
    fi
}



#Temos de checkar se o número de argumentos é válido
function check_arg_amt()
{

    if [ $# != 2 ]; 
    then
        echo "The number of arguments is wrong"
        exit 1
    fi

}


#checkar se os diretórios dados sao válidos
function check_arg_path()
{

    if [ ! -d "$src_dir" ] || [ ! -d "$dst_dir" ]; 
    then 
         echo "The directories inputed do not exist!"
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
    echo "The files in $src_dir have been copied to the $new_folder"
    exit 0
}


function compare_data()
{
    file1=$1
    file2=$2

    if [ "$file1" -nt "$file2" ]; 
    then
        return 0;
    fi

    return 1;
}

function compare()
{


    #analisar files de fonte->backup
    for file in "$src_dir"/*; do
        file_name=$(basename "$file")
        src_file="$src_dir/$file_name"
        

        if [ -f "$dst_dir/$file_name" ]; 
        then
            dst_file="$dst_dir/$file_name"
            if compare_data "$src_file" "$dst_file" ; 
            then #executa quando retornar 0
                cp "$src_file" "$dst_file" #substitui o ficheiro 2 com o 1
            fi
        else
            cp "$src_file" "$dst_dir"
        fi

    done

 #analisar files de backup->fonte
    for file in "$dst_dir"/*; do
        file_name=$(basename "$file")
        

        if [ ! -f "$src_dir/$file_name" ]; 
        then
            echo "Removendo $file do $dst_dir, não existe em $src_dir"
            rm "$file" "$dst_dir" 
        fi
    done
}


main "$@"

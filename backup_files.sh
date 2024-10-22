src_dir="$1"
dst_dir="$2"


function main(){

    check_arg_amt "$@"
    check_arg_path
    do_backup
}



#Temos de checkar se o número de argumentos é válido
function check_arg_amt()
{

    if [ $# != 2 ]; then
        echo "The number of arguments is wrong"
        exit 1
    fi

}




#checkar se os diretórios dados sao válidos
function check_arg_path()
{

    if [ ! -d "$src_dir" ] || [ ! -d "$dst_dir" ]; then 
         echo "The directories inputed do not exist!"
         exit 1
    fi

}



function do_backup()
{

    new_folder="$dst_dir/backup"
    mkdir -p "$new_folder"

    find "$src_dir" -maxdepth 1 -type f -exec cp {} "$new_folder" \;
    echo "The files in $src_dir have been copied to the $new_folder"
    exit 0
}


main "$@"
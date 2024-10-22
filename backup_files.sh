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




function compareData()
{
    file1=$1
    file2=$2

    if [ "$file1" -nt "$file2" ]; then
        return 0;
    else
        return 1;
    fi
}

function compare()
{


    #analisar files de fonte->backup
    for file in "$src_dir"/*; do
        file_name=$(basename "$file")
        file1="$src_dir/$file_name"
        

        if [[ -f "$dst_dir/$file_name" ]]; then
            file2="$dst_dir/$file_name"
            if compareData "$file1" "$file2" ; then #executa quando returnar 0
                cp "$file1" "$file2" #substitui o ficheiro 2 com o 1
            fi
        else
            cp "$file1" "$dst_dir"
        fi

    done


}


main "$@"

checking=false
exclude_check=false
exclude_file=""
regexpr=""
regexpr_check=false


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
    if check_existence "$backup_folder"; 
    then
        echo "o check funciona"
        make_directory "$dst_dir" "backup"
        compare "$backup_folder" "$src_dir"
    else
        echo "o backup existe"
        compare "$backup_folder" "$src_dir"
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

function check_existence()
{
    dir=$1
    if [ -d "$dir" ];
    then
        return 1;
    fi

    return 0;
}

function make_directory(){
    dst_dir=$1
    dir_name=$2

    new_dir="$dst_dir/$dir_name"


    if   check_existence "$new_dir"; then
        simulation mkdir -p "$new_dir" 
    fi

}


#flag -b
function exclude()
{
        
    #ja funciona, aqui o problema era o file excluir vir do windows, por isso nao
    #estava no formato certo
    IFS=$'\n'
    for line in $(cat "$exclude_file"); do
    unset IFS
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
        file_name=$(basename "$file")

        if [[ -d "$file" ]] && [ ! -z "$(ls -A "$file")" ] && [ -d "$src_dir/$file_name" ]; then
            new_dir="$dst_dir/$file_name"
            if delete "$src_dir/$file_name" "$new_dir" ; then
                # Reset directory variables after recursive call
                src_dir="$1"
                dst_dir="$2"
                continue
            fi
        fi


        if [[ -d "$dst_dir/$file_name" && ! -d "$src_dir/$file_name" ]]; then
            echo "Removendo a $file_name do $dst_dir, não existe em $src_dir"
            simulation rm -r "$file"
        elif [[ ! -f "$src_dir/$file_name" && -f "$dst_dir/$file_name" ]]; then
        
            echo "Removendo $file_name do $dst_dir, não existe em $src_dir"
            simulation rm "$file" 
        fi
       
    done
    return 0
}
function compare()
{
    dst_dir=$1
    src_dir=$2
    IFS=$'\n'
    # Skip processing if the source directory is empty

    if [ -z "$(ls -A "$src_dir")" ]; then
        
            return 0
    fi
    #analisar files de fonte->backup
    for file in $(find "$src_dir" -mindepth 1 -maxdepth 1); do
    unset IFS
        file_name=$(basename "$file")


        # Handle directories recursively
        if [[ -d "$file" ]]; then
            make_directory "$dst_dir" "$file_name"
            new_dir="$dst_dir/$file_name"
            if compare "$new_dir" "$src_dir/$file_name"; then
                # Reset directory variables after recursive call
                dst_dir="$1"
                src_dir="$2"
                continue
            fi
        fi

        # Check for excluded files
        if [[ "$exclude_check" == true ]] && exclude "$file_name"; then
            continue
        fi

        # Check against regular expressions
        if [[ "$regexpr_check" == true ]] && choose "$file_name"; then
            continue
        fi

        # Define source and destination paths
        src_file="$src_dir/$file_name"

        # Check if the file already exists in the destination
        if [ -f "$dst_dir/$file_name" ]; then
            dst_file="$dst_dir/$file_name"
            if compare_data "$src_file" "$dst_file"; then
                echo "substitui"
                simulation cp -a "$src_file" "$dst_file" # Replace file in the destination
            fi
        else
            echo "criei"
            simulation cp -a "$src_file" "$dst_dir"
        fi

    done

    
    return 0
}
main "$@"

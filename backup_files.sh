# Declaration of global variables
checking=false

default_dirname_src=""
default_dirname_dst=""

function main(){
    # Check the existence of the "c" parameter
    while getopts ":c" opt; 
    do
        if [ "$opt" = "c" ]; 
        then 
                checking=true
        else
                exit 1
        fi
    done
    shift $((OPTIND - 1))   # Remove the processed options
    
    # Check the amount of arguments
    check_arg_amt "$@"
    # Assign the arguments to the variables
    src_dir="$1"
    dst_dir="$2"
    
    # Check if the directories exist
    check_arg_path

    default_dirname_src=$(dirname "$src_dir")
    default_dirname_dst=$(dirname "$dst_dir")

    if check_backup_existence ; 
    then
        # Create backup directory
        do_initial_backup "$dst_dir"
    else
        # Compare then delete
        compare 
        delete 
    fi
}

# Parameter -c
function simulation()
{
    # Write the command to be executed if the checking variable is true
    if ! $checking; 
    then
        "$@"
    fi
   
    # Compare the default directory names and remove them from the output
    for i in "$@"; do
        if [[ "$i" =~ "$default_dirname_src" ]]; then
            echo -n "${i/"$default_dirname_src/"}"
        elif [[ "$i" =~ "$default_dirname_dst" ]]; then
            echo -n "${i/"$default_dirname_dst/"}"
        else
            echo -n "$i"
        fi
        if [[ "$i" != "${@: -1}" ]]; then
            echo -n " "
        fi
    done
    echo
}

function check_arg_amt()
{
    # Check if the number of arguments is different from 2
    if [ $# != 2 ]; 
    then
        exit 1
    fi
}

function check_arg_path()
{
    dir_name=$(dirname "$dst_dir")

    # Check if the directories exist and if the path before the backup directory exists
    if [ ! -d "$src_dir" ] || [ ! -d "$dir_name" ]; 
    then 
        exit 1
    fi
}

function check_backup_existence()
{
    # Check if the backup directory exists
    if [ -d "$dst_dir" ];
    then
        return 1;
    fi
    return 0;
}

function do_initial_backup()
{
    # Create the backup directory
    new_folder=$1
    simulation mkdir "$new_folder"
    
    # Copy the files from the source directory to the backup directory
    compare "$new_folder"   
    exit 0
}

function compare_date()
{
    # Compare the modification date of the files
    src_file=$1
    dst_file=$2

    if [  "$src_file" -nt "$dst_file" ];
    then
        # The source file is newer
        return 0;
    elif [  "$dst_file" -nt "$src_file" ] ; 
    then
        # The destination file is newer
        return 1
    else
    # The files have the same modification date
    return 1
    fi
}

function delete()
{
    # Delete the files that are not in the source directory
    IFS=$'\n'

    # Analyze files from backup
    for file in $(find "$dst_dir" -mindepth 1 -maxdepth 1 -type f); 
    do
        unset IFS
        
        file_name=$(basename "$file")

        # If the file does not exist in the source directory, delete it
        if [ ! -f "$src_dir/$file_name" ]; 
        then
            if ! $checking;then
                rm "$file" 
            fi
        fi  
    done
}

function compare()
{
    # Compare the files from the source directory to the backup directory
    IFS=$'\n'

    for file in $(find "$src_dir" -mindepth 1 -maxdepth 1 -type f); 
    do
        unset IFS

        file_name=$(basename "$file")

        dst_file="$dst_dir/$file_name"
        # Check if the file exists in the backup directory
        if [ -f "$dst_file" ]; 
        then
            # If the file exists, compare the modification date
            
            if compare_date "$file" "$dst_file" ; 
            then 
                # If the source file is newer, replace the backup file
                simulation cp -a "$file" "$dst_file" 
            fi
        else
            # If the file does not exist, create it
            simulation cp -a "$file" "$dst_file" 
        fi
    done
}
main "$@"

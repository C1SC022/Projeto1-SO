# Declaration of global variables
checking=false

function main(){
    # Check the existence of the "c" parameter
    while getopts ":c" opt; 
    do
        if [ "$opt" = "c" ]; 
        then 
                checking=true
        else
                echo "Invalid option"
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

    # Assign the backup folder
    backup_folder="$dst_dir/backup"
    if check_backup_existence ; 
    then
        # Create backup directory
        do_initial_backup "$backup_folder"
    else
        # Compare then delete
        compare "$backup_folder"
        delete "$src_dir" "$backup_folder"
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
    echo "$*"
}

function check_arg_amt()
{
    # Check if the number of arguments is different from 2
    if [ $# != 2 ]; 
    then
        echo -e "\033[31mThe number of arguments is wrong.\033[0m"
        exit 1
    fi
}

function check_arg_path()
{
    # Check if the directories exist
    if [ ! -d "$src_dir" ] || [ ! -d "$dst_dir" ]; 
    then 
         echo -e "\033[31mThe directories inputed do not exist.\033[0m"
         exit 1
    fi
}

function check_backup_existence()
{
    # Check if the backup directory exists
    if [ -d "$dst_dir/backup" ];
    then
        return 1;
    fi
    return 0;
}

function do_initial_backup()
{
    # Create the backup directory
    new_folder=$1
    simulation mkdir -p "$new_folder"
    
    # Copy the files from the source directory to the backup directory
    compare "$new_folder"   
    exit 0
}

function compare_data()
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
    src_dir=$1
    dst_dir=$2
    IFS=$'\n'

    # Analyze files from backup
    for file in $(find "$dst_dir" -mindepth 1 -maxdepth 1); 
    do
    unset IFS
        # Check if it's a file
        if [[ ! -f "$file" ]]; 
        then
            continue
        fi
        file_name=$(basename "$file")

        # If the file does not exist in the source directory, delete it
        if [ ! -f "$src_dir/$file_name" ]; 
        then
            simulation rm "$file" 
        fi  
    done
}

function compare()
{
    # Compare the files from the source directory to the backup directory
    dst_dir=$1
    IFS=$'\n'

    for file in $(find "$src_dir" -mindepth 1 -maxdepth 1); 
    do
        unset IFS
        # Check if it's a file
        if [[ ! -f "$file" ]]; 
        then
            continue
        fi

        file_name=$(basename "$file")

        # Check if the file exists in the backup directory
        if [ -f "$dst_dir/$file_name" ]; 
        then
            # If the file exists, compare the modification date
            dst_file="$dst_dir/$file_name"
            if compare_data "$file" "$dst_file" ; 
            then 
                # If the source file is newer, replace the backup file
                simulation cp -a "$file" "$dst_file" 
            fi
        else
            # If the file does not exist, create it
            simulation cp -a "$file" "$dst_dir" 
        fi
    done
}
main "$@"

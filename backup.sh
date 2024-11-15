# Declaration of global variables
checking=false
exclude_check=false
exclude_file=""
regexpr=""
regexpr_check=false

function main(){
    # Check the existence of the parameters (-c, -b, -r)
    while getopts ":cb:r:" opt; 
    do
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
    if ! check_dir_existence "$backup_folder"; 
    then
        # Create the backup directory
        create_directory "$dst_dir" "backup"
        compare "$backup_folder" "$src_dir"
    else
        # Compare then delete
        compare "$backup_folder" "$src_dir"
        delete "$src_dir" "$backup_folder"
    fi
}

# Parameter -c
function simulation()
{
    # Write the command to be executed if the checking variable is true
    if $checking; 
    then
        echo "$*"
    else
        "$@"
    fi
}

# Parameter -b
function exclude()
{
    # Read the file line by line and check if the file is in the exclude list
    IFS=$'\n'
    for line in $(cat "$exclude_file"); 
    do
        unset IFS
        line="${line//$'\r'/}" # Remove carriage return (Windows problem)
        if [[ "$1" == "$line" ]]; 
        then
            return 0
        fi
    done
    return 1
}

# Parameter -r
function choose()
{
    # Check if the file name matches the regular expression
    if [[ "$1" =~ "$regexpr" ]]; 
    then
        return 1
    fi
    return 0
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
    if  ! check_dir_existence "$src_dir"  ||  ! check_dir_existence "$dst_dir" ; 
    then 
         echo -e "\033[31mThe directories inputed do not exist.\033[0m"
         exit 1
    fi

}

function check_dir_existence()
{
    # General function to check if a directory exists
    if [ -d "$1" ];
    then
        return 0;
    fi
    return 1;
}

function check_file_existence()
{
    # General function to check if a file exists
    if [ -f "$1" ];
    then
        return 0;
    fi
    return 1;
}

function create_directory()
{
    # Create the directory asked if it doesn't exist
    dst_dir=$1
    dir_name=$2

    new_dir="$dst_dir/$dir_name"

    if  ! check_dir_existence "$new_dir"; 
    then
        simulation mkdir -p "$new_dir" 
    fi
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
    for dst_file in $(find "$dst_dir" -mindepth 1 -maxdepth 1); 
    do
        unset IFS
        file_name=$(basename "$dst_file")

        # Handle directories recursively
        if  check_dir_existence "$dst_file"  && [ ! -z "$(ls -A "$dst_file")" ] &&  check_dir_existence "$src_dir/$file_name" ; 
        then
            new_dir="$dst_dir/$file_name"
            if delete "$src_dir/$file_name" "$new_dir" ; 
            then
                # Reset directory variables after recursive call
                src_dir="$1"
                dst_dir="$2"
                continue
            fi
        fi

        # If the directory does not exist in the source, delete it
        if  check_dir_existence "$dst_file" && ! check_dir_existence "$src_dir/$file_name" ; 
        then
            simulation rm -r "$dst_file"
        # If the file does not exist in the source, delete it
        elif  ! check_file_existence "$src_dir/$file_name" && check_file_existence "$dst_file" ; 
        then
            simulation rm "$dst_file" 
        fi    
    done
    return 0
}

function compare()
{
    # Compare the files from the source directory to the backup directory
    dst_dir=$1
    src_dir=$2
    IFS=$'\n'

    # In recursive calls, check if the source directory is empty to skip processing
    if [ -z "$(ls -A "$src_dir")" ]; 
    then     
        return 0
    fi

    for src_file in $(find "$src_dir" -mindepth 1 -maxdepth 1); 
    do
        unset IFS
        file_name=$(basename "$src_file")

        # Handle directories recursively, create or enter the new directory
        if  check_dir_existence "$src_file" ; 
        then
            create_directory "$dst_dir" "$file_name"
            new_dir="$dst_dir/$file_name"
            if compare "$new_dir" "$src_dir/$file_name"; 
            then
                # Reset directory variables after recursive call
                dst_dir="$1"
                src_dir="$2"
                continue
            fi
        fi

        # Check for excluded files
        if [[ "$exclude_check" == true ]] && exclude "$file_name"; 
        then
            continue
        fi

        # Check against regular expressions
        if [[ "$regexpr_check" == true ]] && choose "$file_name"; 
        then
            continue
        fi

        # Check if the file exists in the destination directory
        if  check_file_existence "$dst_dir/$file_name" ; 
        then
            # If the file exists, compare the modification date
            dst_file="$dst_dir/$file_name"
            if compare_data "$src_file" "$dst_file"; 
            then
                # If the source file is newer, replace the destination file
                simulation cp -a "$src_file" "$dst_file" 
            fi
        else
            # If the file does not exist, create it
            simulation cp -a "$src_file" "$dst_dir"
        fi
    done
    # Return 0 in order to go back to the previous directory   
    return 0
}
main "$@"

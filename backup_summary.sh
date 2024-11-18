# Declaration of global variables
# Parameters
checking=false
exclude_check=false
exclude_file=""
regexpr=""
regexpr_check=false

default_dirname_src=""
default_dirname_dst=""
# Statistics
errors=0
warnings=0
updated=0
copied=0
copied_size=0
deleted=0
deleted_size=0
summary_list=(0 0 0 0 0 0 0)

function main()
{
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
                ((errors++))
                echo -e "\033[31mERROR: the option $1 is an invalid option; Should not happen\033[0m"
                summary
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
    
    default_dirname_src=$(dirname "$src_dir")
    default_dirname_dst=$(dirname "$dst_dir")

    if ! check_dir_existence "$dst_dir"; 
    then
        # Create the backup directory
        create_directory "$dst_dir"
        compare "$dst_dir" "$src_dir"
    else
        # Compare and delete
        compare "$dst_dir" "$src_dir"
    fi
    # Summary of the general statistics
    summary "list" "${list_summary[@]}"
}

function size()
{
    # Regist the size of the files to be copied or deleted
    arg=$1
    file="${arg#?}"

    # Check if it's a file
    if check_file_existence "$file"; 
    then
        size=$(du -sb "$file" | cut -f1)
    # Check if the directory is empty
    elif [ ! -z "$(ls -A "$file")" ]; 
    then
        # Calculate the size of the directory
        size=$(find "$file" -type f -exec stat --format="%s" {} + | awk '{s+=$1} END {print s}')
    fi

    # Check the argument and add the size to the respective variable
    if [[ "$arg" == c* ]];  #c for copy
    then     
        ((copied_size=$copied_size + $size))
    elif [[ "$arg" == d* ]] && [ ! -z "$(ls -A "$file")" ]; #d for delete
    then   
        ((deleted_size=$deleted_size + $size))
    fi
}

function list_summary()
{
    # Update the general statistics
    list_summary[0]=$((list_summary[0] + $errors))
    list_summary[1]=$((list_summary[1] + $warnings))
    list_summary[2]=$((list_summary[2] + $updated))
    list_summary[3]=$((list_summary[3] + $copied))
    list_summary[4]=$((list_summary[4] + $copied_size))
    list_summary[5]=$((list_summary[5] + $deleted))
    list_summary[6]=$((list_summary[6] + $deleted_size))
}
function summary()
{
 if [[ $1 == "list" ]]; then
        shift # Remove the first argument
        local sum_list=("$@") # Use the list arguments
        echo -e "\033[32mWhile backuping general: ${sum_list[0]} Errors; ${sum_list[1]} Warnings; ${sum_list[2]} Updated; ${sum_list[3]} Copied (${sum_list[4]} B); ${sum_list[5]} Deleted (${sum_list[6]} B)\033[0m"
    else
        # Use the directory statistics
        echo -e "\033[32mWhile backuping ${1/"$default_dirname_src/"}: $errors Errors; $warnings Warnings; $updated Updated; $copied Copied (${copied_size}B); $deleted Deleted (${deleted_size}B)\033[0m"
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
        ((errors++))
        echo -e "\033[31mERROR: the number of arguments is wrong; Should not happen\033[0m"
        summary
        exit 1
    fi
}

function check_arg_path()
{
    dir_name=$(dirname "$dst_dir")
    # Check if the directories exist and if the path before the backup directory exists
    if  ! check_dir_existence "$src_dir" ||  ! check_dir_existence "$dir_name"; 
    then 
        ((errors++))
        echo -e "\033[31mERROR: the directories inputed do not exist; Should not happen\033[0m"
        summary
        exit 1
    fi
}

function check_dir_existence()
{
    # Check if the directory exists
    if [ -d "$1" ];
    then
        return 0;
    fi
    return 1;
}

function check_file_existence()
{
    # Check if the file exists
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

    if  ! check_dir_existence "$new_dir"; then
        simulation mkdir "$new_dir" 
    fi
}
# Parameter -b
function exclude()
{
    # Read the file line by line and check if the file is in the exclude list
    IFS=$'\n'
    for line in $(cat "$exclude_file"); do
        unset IFS
        line="${line//$'\r'/}" # Remove carriage return (Windows problem)
        if [[ "$1" == "$line" ]]; then
            return 0
        fi
    done
    return 1
}

# Parameter -r
function choose()
{
    # Check if the file name matches the regular expression
    if [[ "$1" =~ "$regexpr" ]]; then
        return 1
    fi
    return 0
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
        echo -e "\033[33mWARNING: backup entry $dst_file is newer than $src_file; Should not happen\033[0m"
        ((warnings++1))
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


        # If the directory does not exist in the source, delete it
        if  check_dir_existence "$dst_file" && ! check_dir_existence "$src_dir/$file_name" ; 
        then
            # Count the number of files to be deleted for size calculation
            num_files=$(find "$dst_file" -type f | wc -l)
            ((deleted += num_files))
            size "d$dst_file"   
            simulation rm -r "$dst_file"

        # If the file does not exist in the source, delete it
        elif  ! check_file_existence "$src_dir/$file_name" && check_file_existence "$dst_file" ;
        then
            ((deleted++))
            size "d$dst_file"   
            simulation rm "$dst_file"
        fi
    done
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
        summary $src_dir
        return 0
    fi

    # Loop through the files in the source directory
    for src_file in $(find "$src_dir" -mindepth 1 -maxdepth 1 -type f); 
    do
        unset IFS
        file_name=$(basename "$src_file")
       
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

        dst_file="$dst_dir/$file_name"
        # Check if the file exists in the destination directory
        if  check_file_existence "$dst_file"; 
        then           
            # If the file exists, compare the modification date
            if compare_date "$src_file" "$dst_file" ; 
            then 
                # If the source file is newer, replace the destination file and update the statistics
                ((updated++))
                simulation cp -a "$src_file" "$dst_file" #substitui o ficheiro 2 com o 1
            fi
        else
            # If the file does not exist, create it and update the statistics
            ((copied++))
            size "c$src_file"  
            simulation cp -a "$src_file" "$dst_file" 
        fi
    done  

    # Call the delete function to delete the files that are not in the source directory
    if check_dir_existence "$dst_dir"; 
    then
        delete "$src_dir" "$dst_dir"
    fi
    # Update the general statistics
    list_summary
    # Call the summary function to display the statistics
    summary $src_dir

    IFS=$'\n'
    # Loop through the directories in the source directory
    for src_file in $(find "$src_dir" -mindepth 1 -maxdepth 1 -type d);
    do
        # Reset statistics
        errors=0
        warnings=0
        updated=0
        copied=0
        copied_size=0
        deleted=0
        deleted_size=0
        
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
    done
    
    # Return 0 in order to go back to the previous directory   
    return 0
}
main "$@"

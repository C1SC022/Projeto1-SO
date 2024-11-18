# Declaration of global variables
src_dir="$1"
dst_dir="$2"

function main()
{
    # Check if the source directory exists
    if ! check_directory_existence "$src_dir";
    then
        echo "A source directory doesn't exist."
        exit
    fi

    # Check if the backup directory indicated exists
    if  ! check_directory_existence "$dst_dir";
    then
        echo "A backup folder still doesn't exist in that directory."
        exit # Exit's the script
    else
        echo "The backup folder exists in the $dst_dir directory."
        
    fi
    check_backup_differences
}

function check_directory_existence()
{
    if [ -d "$1" ];
    then
        return 0; # Source directory exists return true (0)
    fi

    return 1; # Doesn't exist return false (1)
}


function check_backup_differences()
{

    # Loop through the source files and check if they exist in the backup directory
    find "$src_dir" -type f | while IFS= read -r src_file; 
    do
        rel_path="${src_file#$src_dir/}"
        b_file="$dst_dir/$rel_path"
        #echo "$rel_path"

        # Check if the file exists in the backup
        if  check_file_existence "$b_file"; 
        then
            echo "$filename exists in source but not in backup"
            continue
        fi

        # Compare md5sum's of the source and backup file
        src_md5=$(md5sum "$src_file" | awk '{print $1}')
        b_md5=$(md5sum "$b_file" | awk '{print $1}')

        if [ "$src_md5" != "$b_md5" ]; 
        then
            echo "$src_file & $b_file differ."
        fi
    done

    # Loop through the backup files and check if they exist in the source directory
    find "$dst_dir" -type f | while IFS= read -r b_file; 
    do
        rel_path="${b_file#$dst_dir/}"
        src_file="$dst_dir/$rel_path"
        #echo "$rel_path"

        # Check if the file exists in the source
        if  check_file_existence "$src_file"; 
        then
            echo "$filename exists in backup but not in source."
        fi
    done

}

function check_file_existence()
{
    if [ -f "$1" ];
    then
        return 1 # file exists return false (1)
    fi 
    
    return 0 # it doesn't exist return true (0)
}



main "$@" # Initiate main
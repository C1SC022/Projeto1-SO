src_dir="$1"
dst_dir="$2"

function main()
{
    if  check_backup_existence;
    then
        echo -e "\033[31mA backup folder still doesn't exist in that directory.\033[0m"
        end
    else
        echo -e "The backup folder exists in the \033[33m$dst_dir\033[0m directory."
        dst_dir="$dst_dir/backup"
        check_backup_differences
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

function check_backup_differences()
{
    echo -e "\033[32mBeginning comparison...\033[0m"

    find "$src_dir" -type f | while IFS= read -r src_file; do
        rel_path="${src_file#$src_dir/}"
        b_file="$dst_dir/$rel_path"
        #echo "$rel_path"

        # Check if the file exists in the backup
        if ! check_file_existence "$b_file"; then
            echo "$filename exists in source but not in backup"
            continue
        fi

        # Compare MD5 checksums of the source and backup file
        src_md5=$(md5sum "$src_file" | awk '{print $1}')
        b_md5=$(md5sum "$b_file" | awk '{print $1}')

        if [ "$src_md5" != "$b_md5" ]; then
            echo -e "\033[33m$src_file\033[0m & \033[33m$b_file\033[0m differ."
        fi
    done

    # Loop through backup files and check if they exist in source
    find "$dst_dir" -type f | while IFS= read -r b_file; do
        rel_path="${b_file#$dst_dir/}"
        src_file="$dst_dir/$rel_path"
        #echo "$rel_path"

        if ! check_file_existence "$src_file"; then
            echo "$filename exists in backup but not in source."
        fi
    done

    echo -e "\033[32mComparison complete\033[0m"

}

function check_file_existence()
{
    if [ ! -f "$1" ];
    then
        return 1
    else 
        return 0
    fi
}



main "$@"
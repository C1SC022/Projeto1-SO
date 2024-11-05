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
    fi
    check_backup_differences

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

    for src_file in "$src_dir"/*;
    do
        filename=$(basename "$src_file")
        echo "source file: $src_file"
        echo "filename: $filename"
        b_file="$dst_dir/$filename"
        #echo "backup file: $b_file"
        if ! check_file_existence "$b_file";
        then
            echo "$filename exists in source but not in backup"
            continue
        fi

        src_md5=$(md5sum "$src_file" | awk '{print $1}')
        b_md5=$(md5sum "$b_file" | awk '{print $1}')

        #echo "src_md5: $src_md5"
        #echo "b_md5: $b_md5"

        if [ "$src_md5" != "$b_md5" ]; 
        then
            echo -e "\033[33m$src_file\033[0m & \033[33m$b_file\033[0m differ."
        fi

    
    done
    for b_file in "$dst_dir/"*; 
    do
        filename=$(basename "$b_file")
        src_file="$src_dir/$filename"
        
        if [ ! -f "$src_file" ]; 
        then
            echo "$filename exists in backup but not in source."
        fi
    done

    echo "Comparing complete"

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
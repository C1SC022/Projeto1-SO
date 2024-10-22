src_dir="$1"
dst_dir="$2"

function main()
{
    if  check_backup_existence;
    then
        echo -e "\033[31mA backup folder still doesn't exist in that directory.\033[0m"
    else
        echo -e "The backup folder exists in the \033[33m$dst_dir\033[0m directory."
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



main "$@"
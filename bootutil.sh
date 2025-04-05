#!/bin/bash

# Demo only
#boot_entries_dir="/boot/loader/entries"
boot_entries_dir="./entries"
option_set=""
kernel_value=""
title_value=""
initramfs_value=""
cmdline_add_value=""
cmdline_remove_value=""
destination_value=""
make_default_value=""
duplicate_value=""

function ListFileEntry() {
    title=$(grep -oP '^title \K.*' $1)
    version=$(grep -oP '^version \K.*' $1)
    linux=$(grep -oP '^linux \K.*' $1)
    echo "$title ($version, $linux)"
}

function FilterKernel() {
    grep -oP "^linux \K.*" $1 | grep -qE "$kernel_value"
}

function FilterTitle() {
    grep -oP "^title \K.*" $1 | grep -qE "$title_value"
}

function List() {
    filtered=$( # Filter
    echo $option_set | grep -qG "k"
    bykernel=$?
    echo $option_set | grep -qG "t" 
    bytitle=$?
    if [[ $bymernel == 0 ]] && [[ $bytitle == 0 ]]; then
        for file in $boot_entries_dir/*; do
            FilterKernel $file && FilterTitle $file && echo $file 
        done
    elif [[ $bykernel == 0 ]]; then
        for file in $boot_entries_dir/*; do
            FilterKernel $file && echo $file 
        done
    elif [[ $bytitle == 0 ]]; then
        for file in $boot_entries_dir/*; do
            FilterTitle $file && echo $file
        done
    else
        for file in $boot_entries_dir/*; do
            echo $file 
        done
    fi
    );

    (
    if echo $option_set | grep -qG "f"; then # Sort by filename
        for file in $filtered; do
            echo $file | grep -oP '[^/]*\.conf$'
        done | sort | while read -r line; do echo "$boot_entries_dir/$line"; done
    elif echo $option_set | grep -qG "s"; then # Sort by sortkey
        for file in $filtered; do
            sort_key=$(grep -oP '^sort-key \K.*' $file)
            echo "$([[ "$sort_key" != "" ]] && echo "." || echo "z") $sort_key $(echo $file | grep -oP '[^/]*\.conf$')"
        done | sort | cut -d ' ' -f3- | while read -r line; do echo "$boot_entries_dir/$line"; done
    else # Unsorted
        for file in $filtered; do
            echo $file
        done
    fi
    ) | while read file; do ListFileEntry $file; done 

    return 0
}

function Remove() {
    for file in $boot_entries_dir/*; do
        if $(grep -oP "^title \K.*" $file | grep -qE "$1"); then
            rm -f $file
        fi
    done

    return 0
}

function Duplicate() {
    source_file_path=$1
    if [[ $1 == "" || $1[0] == -* ]]; then
        source_file_path=$(
            for file in $boot_entries_dir/*; do
                grep -qP "^vutfit_default.*y" "$file" && echo "$file" && break
            done
        )
        if [[ $source_file_path == "" ]]; then
            echo "No default file to duplicate"
            return 1
        fi
    elif [ ! -f "$1" ]; then
        echo "File $1 not found"
        return 1;
    fi

    destination_file_path=""
    if echo $option_set | grep -qG "d"; then
        destination_file_path="$destination_value"
    else
        destination_file_path="$source_file_path"
        while [ -f "$destination_file_path" ]; do
            destination_file_path=$(echo "$destination_file_path" | sed -e 's/\(.*\)\.conf$/\1.copy.conf/')
        done
    fi
    echo "$destination_file_path"
    source_file=$(cat "$source_file_path")
    
    if echo $option_set | grep -qG "k"; then
        source_file=$(echo "$source_file" | sed -e "s#^linux.*#linux $kernel_value#")
    fi
    if echo $option_set | grep -qG "i"; then
        source_file=$(echo "$source_file" | sed -e "s#^initrd.*#initrd $initramfs_value#")
    fi
    if echo $option_set | grep -qG "t"; then
        source_file=$(echo "$source_file" | sed -e "s#^title.*#title $title_value#")
    fi

    arg_line=$(echo "$source_file" | grep -P "^options .*")
    if echo "$option_set" | grep -qG "a"; then
        for argument in "$cmdline_add_value"; do
            arg_name=$(echo "$argument" | cut -d '=' -f1)
            arg_value=$(echo "$argument" | cut -d '=' -f2)

            if echo "$argument" | grep -qG "="; then
                arg_line=$(echo "$arg_line" | sed -E "/$arg_name=/!{q1}; {s/$arg_name=[\"\'].*[\"\']|$arg_name=[^ ]*/$arg_name=$arg_value/}")
                if [[ $? -eq 1 ]]; then
                    arg_line+=" $argument"
                fi
            else
                arg_line=$(echo "$arg_line" | sed -E "/$arg_name=/!{q1}; {s/$arg_name=[\"\'].*[\"\']|$arg_name=[^ ]*/$arg_name/}")
                if [[ $? -eq 1 ]]; then
                    arg_line+=" $argument"
                fi
            fi
        done
    fi
    if echo $option_set | grep -qG "r"; then
        for argument in "$cmdline_remove_value"; do
            arg_name=$(echo "$argument" | cut -d '=' -f1)
            arg_value=$(echo "$argument" | cut -d '=' -f2)


            if echo "$argument" | grep -qG "="; then
                arg_line=$(echo "$arg_line" | sed -e "s#$argument##")
            else
                arg_line=$(echo "$arg_line" | sed -E "s# ?$arg_name=[\"\'].*[\"\']| ?$arg_name=?[^ ]*##")
            fi
        done
    fi

    source_file=$(echo "$source_file" | sed -e "s#^options .*#$arg_line#")
    
    source_file=$(echo "$source_file" | sed -e "s/^vutfit_default.*y/vutfit_default n/")

    echo "$source_file" > "$destination_file_path"

    if echo $option_set | grep -qG "-" && [[ $make_default_value == "make-default" ]]; then
        MakeDefault "$destination_file_path"
    fi

    return 0
}

function ShowDefault() {
    for file in $boot_entries_dir/*; do
        vutfit_default=$(grep -oP "^vutfit_default \K.*" "$file")
        if [[ $? == 0 && $vutfit_default == "y" ]]; then
            # decide what to print out
            if echo $option_set | grep -qG "f"; then
                echo "$file"
            else
                cat "$file"
            fi
            return 0
        fi
    done
    echo "no default file set" >&2
    return 1
}

function MakeDefault() {
    if [ ! -f "$1" ]; then
        echo "file '$1' not found" >&2
        return 1
    fi

    # remove any potential defaults
    for file in $boot_entries_dir/*; do
        sed -i "s/^vutfit_default.*y/vutfit_default n/" "$file"
    done

    sed -i '/^vutfit_default /{h;s/n/y/};${x;/^$/{s//vutfit_default y/;h};x}' "$1"
    return 0
}

function GetOptions() {
    while getopts "fsb:k:t:i:a:r:d:-:" option; do
        case $option in 
            f)
                option_set+="$option"
                ;;
            s)
                option_set+="$option"
                ;;
            b)
                option_set+="$option"
                boot_entries_dir="$OPTARG"
                ;;
            k)
                option_set+="$option"
                kernel_value="$OPTARG"
                ;;
            t)
                option_set+="$option"
                title_value="$OPTARG"
                ;;
            i)
                option_set+="$option"
                initramfs_value="$OPTARG"
                ;;
            a)
                option_set+="$option"
                cmdline_add_value+="$OPTARG "
                ;;
            r)
                option_set+="$option"
                cmdline_remove_value+="$OPTARG "
                ;;
            d)
                option_set+="$option"
                destination_value="$OPTARG"
                ;;
            -)
                option_set+="$option"
                make_default_value="$OPTARG"
                ;;
            \?)
                echo "Error invalid option" >&2
                exit 1
                ;;
        esac
    done
}

# read options and mode
GetOptions "$@"
shift $(($OPTIND - 1))
mode=$1
shift

if [[ $mode == "duplicate" && $1 != -* ]]; then
    duplicate_value="$1"
    shift
fi

OPTIND=1
GetOptions "$@"
shift $(($OPTIND - 1))

if [[ $mode == "duplicate" && $# == 1 && $1 != -* ]]; then
    duplicate_value="$1"
    shift
fi

return_code=0

# Mode
case $mode in 
    list)
        List
        ;;
    remove)
        if [[ "$#" == "1" && "$1" != "" ]]; then
            Remove $1
        fi
        ;;
    duplicate)
        Duplicate "$duplicate_value"
        ;;
    show-default)
        ShowDefault
        ;;
    make-default)
        if [[ "$#" == "1" && "$1" != "" ]]; then
            MakeDefault "$1"
        fi
        ;;
    *)
        echo "Error invalid mode '$1'" >&2
        exit 1
        ;;
esac

return_code=$?
exit $return_code

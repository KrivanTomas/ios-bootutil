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
            echo "$([[ "$sort_key" != "" ]] && echo "1" || echo "a") $sort_key $(echo $file | grep -oP '[^/]*\.conf$')"
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
            echo "Removing $file"
            rm -f $file
        fi
    done

    return 0
}

function Duplicate() {
    source_file=$1
    if [[ $1 == "" || $1[0] == -* ]]; then
        source_file=$(
            for file in $boot_entries_dir/*; do
                grep -qP "^vutfit_default.*y" $file && echo $file && break
            done
        )
        if [[ $source_file == "" ]]; then
            echo "No default file to duplicate"
            return 1
        fi
    elif [ ! -f $1 ]; then
        echo "File $1 not found"
        return 1;
    fi


    echo $source_file

    return 0
}

function ShowDefault() {
    for file in $boot_entries_dir/*; do
        vutfit_default=$(grep -oP "^vutfit_default \K.*" $file)
        if [[ $? == 0 && $vutfit_default == "y" ]]; then
            # decide what to print out
            if echo $option_set | grep -qg "f"; then
                echo $file
            else
                cat $file
            fi
            return 0
        fi
    done
    echo "no default file set"
    return 1
}

function MakeDefault() {
    if [ ! -f $1 ]; then
        echo "file '$1' not found"
        return 1
    fi

    # remove any potential defaults
    for file in $boot_entries_dir/*; do
        sed -i "s/^vutfit_default.*y/vutfit_default n/" $file
    done

    sed -i '/^vutfit_default /{h;s/n/y/};${x;/^$/{s//vutfit_default y/;h};x}' $1
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
                boot_entries_dir="$optarg"
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
                cmdline_add_value="$OPTARG"
                ;;
            r)
                option_set+="$option"
                cmdline_remove_value="$OPTARG"
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
                echo "Error invalid option"
                exit 1
                ;;
        esac
    done
}

# read options and mode
GetOptions $@
shift $(($OPTIND - 1))
mode=$1
shift
OPTIND=1
GetOptions $@

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
        Duplicate $1
        ;;
    show-default)
        ShowDefault
        ;;
    make-default)
        if [[ "$#" == "1" && "$1" != "" ]]; then
            MakeDefault $1
        fi
        ;;
    *)
        echo "Error invalid mode '$1'"
        exit 1
        ;;
esac

return_code=$?
exit $return_code

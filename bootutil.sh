#!/bin/bash

# Demo only
#boot_entries_dir="/boot/loader/entries"
boot_entries_dir="./entries"
sort_type=""
filter_type=""
filter_kernel_regex=""
filter_title_regex=""

function ListFileEntry() {
    title=$(grep -oP '^title \K.*' $1)
    version=$(grep -oP '^version \K.*' $1)
    linux=$(grep -oP '^linux \K.*' $1)
    echo "$title ($version, $linux)"
}

function FilterKernel() {
    grep -oP "^linux \K.*" $1 | grep -qE "$filter_kernel_regex"
}

function FilterTitle() {
    grep -oP "^title \K.*" $1 | grep -qE "$filter_title_regex"
}

function List() {

    echo $filter_type | grep -qG "kernel"
    bykernel=$?
    echo $filter_type | grep -qG "title" 
    bytitle=$?

    ( # Filter
    if [[ $bykernel == 0 ]] && [[ $bytitle == 0 ]]; then
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
    ) | while read file; do
        ListFileEntry $file
    done

    return

    if [[ "$sort_type" == "file" ]]; then
        for file in $boot_entries_dir/*; do
            echo $file | grep -oP '[^/]*\.conf$'
        done | sort | while read file; do
             ListFileEntry "$boot_entries_dir/$file"
        done
    fi

    if [[ $sort_type == "sortkey" ]]; then
        for file in $boot_entries_dir/*; do
            sort_key=$(grep -oP '^sort-key \K.*' $file)
            echo "$([[ "$sort_key" != "" ]] && echo "1" || echo "a") $sort_key $(echo $file | grep -oP '[^/]*\.conf$')"
        done | sort | cut -d ' ' -f3- | while read file; do
        ListFileEntry "$boot_entries_dir/$file"
    done
    fi

    if [[ $filter_type == "kernel" ]]; then
        for file in $boot_entries_dir/*; do
            FilterKernel $file && echo $file
        done | while read file; do
        ListFileEntry "$file"
    done
    fi

    if [[ $filter_type == "title" ]]; then
        for file in $boot_entries_dir/*; do
            FilterTitle $file && echo $file
        done | while read file; do
        ListFileEntry "$file"
    done
    fi
}

function Remove() {
    for file in $boot_entries_dir/*; do
        if $(grep -oP "^title \K.*" $file | grep -qE "$1"); then
            echo "Removing $file"
            rm -f $file
        fi
    done
}

mode=$1

shift 

while getopts "fsb:k:t:" option; do
    case $option in 
        b)
            boot_entries_dir="$OPTARG"
            ;;
        f)
            sort_type="file"
            ;;
        s)
            sort_type="sortkey"
            ;;
        k)
            filter_type+="kernel"
            filter_kernel_regex="$OPTARG"
            ;;
        t)
            filter_type+="title"
            filter_title_regex="$OPTARG"
            ;;
        \?)
            echo "Error invalid option"
            exit
            ;;
    esac
done

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
        echo "mode: duplicate"
        ;;
    show-default)
        echo "mode: duplicate"
        ;;
    make-default)
        echo "mode: duplicate"
        ;;
    *)
        echo "Error invalid mode '$1'"
        exit
        ;;
esac
#echo "entries path: '$boot_entries_dir'"

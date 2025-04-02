#!/bin/bash

# Demo only
#boot_entries_dir="/boot/loader/entries"
boot_entries_dir="./entries"
sort_type="none"
filter_type="none"
filter_regex=""

function ListFileEntry() {
    title=$(grep -oP '^title \K.*' $1)
    version=$(grep -oP '^version \K.*' $1)
    linux=$(grep -oP '^linux \K.*' $1)
    echo "$title ($version, $linux)"
}

function List() {
    if [ "$sort_type" == "none" ]; then
        for file in $boot_entries_dir/*; do
            ListFileEntry $file
        done
    fi

    if [ "$sort_type" == "file" ]; then
        for file in $boot_entries_dir/*; do
            echo $file | grep -oP '[^/]*\.conf$'
        done | sort | while read file; do
            ListFileEntry "$boot_entries_dir/$file"
        done
    fi

    if [ "$sort_type" == "sortkey" ]; then
        for file in $boot_entries_dir/*; do
            sort_key=$(grep -oP '^sort-key \K.*' $file)
            echo "$([[ "$sort_key" != "" ]] && echo "1" || echo "a") $sort_key $(echo $file | grep -oP '[^/]*\.conf$')"
        done | sort | cut -d ' ' -f3- | while read file; do
            ListFileEntry "$boot_entries_dir/$file"
        done
    fi

    if [ "$sort_type" == "kernel" ]; then
        for file in $boot_entries_dir/*; do
            grep -oP "^linux \K.*" $file | grep -qE "$filter_regex" && echo $file
        done | while read file; do
            ListFileEntry "$file"
        done
    fi

    if [ "$sort_type" == "title" ]; then
        for file in $boot_entries_dir/*; do
            grep -oP "^title \K.*" $file | grep -qE "$filter_regex" && echo $file
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


# Options
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
            filter_type="kernel"
            filter_regex="$OPTARG"
            ;;
        t)
            filter_type="title"
            filter_regex="$OPTARG"
            ;;
        \?)
            echo "Error invalid option"
            exit
            ;;
    esac
done

shift $((OPTIND-1))

# Mode
case $1 in 
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

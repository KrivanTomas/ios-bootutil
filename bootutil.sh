#!/bin/bash

# Demo only
#boot_entries_dir="/boot/loader/entries"
boot_entries_dir="./entries"
sort_type="none"

List() {
    if [ "$sort_type" == "none" ]; then
        for file in $boot_entries_dir/*; do
            title=$(awk -F '^title ' '{printf "%s", $2}' $file)
            version=$(awk -F '^version ' '{printf "%s", $2}' $file)
            linux=$(awk -F '^linux ' '{printf "%s", $2}' $file)
            echo "$title ($version, $linux)"
        done
    fi

    if [ "$sort_type" == "file" ]; then
        for file in $(sort($boot_entries_dir/*)); do
            title=$(awk -F '^title ' '{printf "%s", $2}' $file)
            version=$(awk -F '^version ' '{printf "%s", $2}' $file)
            linux=$(awk -F '^linux ' '{printf "%s", $2}' $file)
            echo "$title ($version, $linux)"
        done
    fi

    if [ "$sort_type" == "sortkey" ]; then
        echo "todo"
    fi
}

mode=$1
shift

while getopts "fsb:" option; do
    echo $option
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
        \?)
        echo "Error invalid option"
        exit
        ;;
    esac
done

case $mode in 
    list)
    List
    ;;
    remove)
    echo "mode: remove"
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
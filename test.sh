#!/bin/bash



GetOptions() {
    while getopts "abc:" option; do
        case $option in
            a)
                echo "a"
                ;;
            b)
                echo "b"
                ;;
            c)
                echo "c"
                ;;
        esac
    done
}




(
echo "test"
echo "3"
echo "2"
echo "1"

) | sort


while getopts "abc:" option; do
    case $option in
        a)
            echo "a"
            ;;
        b)
            echo "b"
            ;;
        c)
            echo "c"
            ;;
    esac
done

shift $(($OPTIND - 1))
echo $1

while getopts "abc:" option; do
    case $option in
        a)
            echo "a"
            ;;
        b)
            echo "b"
            ;;
        c)
            echo "c"
            ;;
    esac
done

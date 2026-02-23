#!/bin/bash

wait_for_user='true'
verbose='true'
while getopts 'h?yq' opt; do
    case "$opt" in 
    h|\?)
        echo "usage: $0 [-y] [-q]"
        exit 0
        ;;
    y) 
        wait_for_user='false'
                ;;
    q) 
        verbose='false'
                ;;
    esac
done

shift $((OPTIND-1))


script=$(mktemp)
errors_found=0
for stepfile in "${@}"
do
    echo $stepfile
    array_length=$( yq e ".steps | length - 1" "$stepfile" )

    if [ "$array_length" -lt 0 ] ; then
        echo "Warning: Empty step file $stepfile"
    else
        for element_index in $( seq 0 "$array_length" );do
            step="$( yq e ".steps[$element_index].match" "$stepfile" )"
            yq e ".steps[$element_index].inputs[] | \"INPUT_\(.name)=foo\"" "$stepfile" | grep -v "INPUT_=foo" > "$script"
            echo "$step" | grep -oP '\?P<(.+?)>' | sed -nE 's#\?P<(.+)>#MATCH_\1=bar#p' >> "$script"
            yq e ".steps[$element_index].run" "$stepfile" >> "$script"
            if $verbose
            then
                echo "###################################"
                echo "### FILE: $stepfile"
                echo "### INDEX: $element_index"
                echo "### STEP: $step"
                echo "###################################"
            fi
            shellcheck -s bash "$script" -e 2129
            ret=$?
            errors_found="$(( errors_found + ret ))"
            if (( ret != 0 )) && ! $verbose
            then
                echo
                echo " ^^^ Above errors found in $stepfile, step $element_index: '$step'"
            fi
            if $wait_for_user
            then
                read  -rn 1 -p "Press any key to continue ... "
            fi
            if $verbose || (( ret != 0 ))
            then
                echo
                echo
            fi

        done
    fi

done

rm "$script"
exit $errors_found

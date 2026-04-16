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
for spellbook in "${@}"
do
    echo $spellbook
    array_length=$( yq e ".spells | length - 1" "$spellbook" )

    if [ "$array_length" -lt 0 ] ; then
        echo "Warning: Empty spell file $spellbook"
    else
        for element_index in $( seq 0 "$array_length" );do
            spell="$( yq e ".spells[$element_index].match" "$spellbook" )"
	    echo '# shellcheck disable=2034' > "$script"
            echo "GANDALF_SPELLBOOK_DIR=baz" >> "$script"
            yq e ".spells[$element_index].inputs[] | \"INPUT_\(.name)=foo\"" "$spellbook" | grep -v "INPUT_=foo" >> "$script"
            echo "$spell" | grep -oP '\?P<(.+?)>' | sed -nE 's#\?P<(.+)>#MATCH_\1=bar#p' >> "$script"
            yq e ".spells[$element_index].run" "$spellbook" >> "$script"
            if $verbose
            then
                echo "###################################"
                echo "### FILE: $spellbook"
                echo "### INDEX: $element_index"
                echo "### SPELL: $spell"
                echo "###################################"
            fi
            shellcheck -s bash "$script" -e 2129 -e 2002
            ret=$?
            errors_found="$(( errors_found + ret ))"
            if (( ret != 0 )) && ! $verbose
            then
                echo
                echo " ^^^ Above errors found in $spellbook, spell $element_index: '$spell'"
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

#!/bin/bash


script=$(mktemp)
for stepfile in "${@}"
do
    array_length=$( yq e ".steps | length - 1" "$stepfile" )

    if [ "$array_length" -le 0 ] ; then
      exit
    fi

    for element_index in $( seq 0 "$array_length" );do
	      yq e ".steps[$element_index].inputs[] | \"INPUT_\(.name)=foo\"" "$stepfile" | grep -v "INPUT_=foo" > "$script"
        yq e ".steps[$element_index].run" "$stepfile" >> "$script"
        echo "###################################"
        echo "### FILE: $stepfile"
        echo "### INDEX: $element_index"
        echo "### STEP: $( yq e ".steps[$element_index].match" "$stepfile" )"
        echo "###################################"
        shellcheck -s bash "$script" -e 2129
        read  -rn 1 -p "Press any key to continue ... "
	echo
	echo

    done

done

rm "$script"

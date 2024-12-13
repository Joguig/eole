#!/bin/bash -x
# shellcheck disable=SC2148,SC2034
 
BASE=$(dirname "$0")
declare -a IGNORES
IGNORES=$(cat "$BASE/.shellcheckignore")
cd "$BASE"
FILES=$(find . -name "*.sh")
for FILE in $FILES
do
    if [[ ! -f "$FILE" ]]
    then
        continue
    fi
    
    RESULT="0"
    for ignore in $IGNORES
    do
        #echo "test $FILE $ignore"
        if [[ "$FILE" =~ .*$ignore.* ]]
        then
            RESULT="1"
            echo "$FILE IGNORE ****************"
            break
        fi
    done
    if [ "$RESULT" -eq 1 ]
    then
        continue
    fi
    
    echo "$FILE analyse"
	SCDISABLE=$(grep "# shellcheck disable=" "$FILE" | sed -e 's/.*disable=/--exclude=/' )
    # SC2148: Tips depend on target shell and yours is unknown. Add a shebang.
    # SC2034: var appears unused. Verify it or export it.
	if [[ -z "$SCDISABLE" || "$SCDISABLE" = "--exclude=" ]]
	then
	    shellcheck -e SC2148,SC2034 "$FILE" >/tmp/check.txt
	else
		echo "$FILE : $SCDISABLE"
	    shellcheck "$SCDISABLE" "$FILE" >/tmp/check.txt
	fi
	RESULT="$?"
	if [ $RESULT -ne 0 ]
	then
	    echo "************************************************************"
	    echo "SCDISABLE=$SCDISABLE"
	    echo "$FILE "
	    echo "shellcheck : $FILE ==> $RESULT"
	    cat /tmp/check.txt
	    echo "************************************************************"
	    echo -e "Aborting Shellcheck Error." >&2
	    #exit 1
	fi
done

find "$BASE" -name "*.py" | while read FILE; do
    if [[ -f $FILE ]]; then
        echo "$FILE"
        pylint --rcfile="$BASE/pylint.cfg" -E "$FILE"
        RESULT="$?"
        echo "pylint : $FILE ==> $RESULT"
        if [ $RESULT -ne 0 ]; then
            echo -e "\e[1;31m\tAborting Pylint Error.\e[0m" >&2
	            exit 1
	        fi
	    fi
done

exit $?
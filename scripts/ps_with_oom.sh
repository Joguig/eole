#!/bin/bash
#    Displays running processes in descending order of OOM score
#      (skipping those with both score and adjust of zero).
#    https://dev.to/rrampage/surviving-the-linux-oom-killer-2ki9

contents-or-0 () { if [ -r "$1" ] ; then cat "$1" ; else echo 0 ; fi ; }

{
    header='# %8s %7s %9s %5s %5s %5s  %s\n'
    format="$(echo "$header" | sed 's/^./ /')"
    declare -a lines output
    IFS=$'\r\n' command eval 'lines=($(ps -e -o user,pid,rss))'
    shown=0 ; omits=0
    for n in $(eval echo "{1..$(expr ${#lines[@]} - 1)}") ; do # 1..skip header
        line="${lines[$n]}"
        case "$line" in *[0-9]*)
            set $line ; user=$1 ; pid=$2 ; rss=$3 ; shift 3
            oom_score=$(    contents-or-0  /proc/$pid/oom_score)
            oom_adj=$(      contents-or-0  /proc/$pid/oom_adj)
            oom_score_adj=$(contents-or-0  /proc/$pid/oom_score_adj)
            if [ -f /proc/$pid/oom_score ] && \
               [ 0 -ne $oom_score -o 0 -ne $oom_score_adj -o 0 -ne $oom_adj ]
            then
                output[${#output[@]}]="$( \
                   printf "$format" \
                          "$user" \
                          "$pid" \
                          "$rss" \
                          "$oom_score" \
                          "$oom_score_adj" \
                          "$oom_adj" \
                          "$(cat /proc/$pid/cmdline | tr '\0' ' ' )" \
                )"
                (( ++shown ))
            else
                (( ++omits ))
            fi
            ;;
        esac
    done
    printf "$header"   ''   '' '' OOM   OOM   OOM ''
    printf "$header" User PID RSS Score ScAdj Adj \
        "Command (shown $shown, omits $omits)"
    for n in $(eval echo "{0..$(expr ${#output[@]} - 1)}") ; do
        echo "${output[$n]}"
    done | sort -k 4nr -k 5rn
}

#----eof


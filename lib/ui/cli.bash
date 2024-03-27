#!/usr/bin/bash
set -euo pipefail

# -- CLI Class ----------------------------------------------------------------

cli.__load__() {
    NO_FMT="\033[0m"
    F_BOLD="\033[1m"

    C_NONE="\033[0m"
    C_RED="\033[38;5;9m"
    C_BLUE="\033[38;5;12m"
    C_GREEN="\033[38;5;2m"
    C_ORANGE="\033[38;5;208m"
    C_GOLD="\033[38;5;220m"
    C_PURPLE="\033[38;5;5m"

    S_INFO="${C_BLUE}\u2691 [info] ${NO_FMT} "
    S_SUCCESS="${C_GREEN}\u2691 [success] ${NO_FMT}\u2713 "
    S_DEBUG="${C_PURPLE}\u2691 [debug]${NO_FMT} "
    S_WARN="${C_ORANGE}\u2691 [warning] ${NO_FMT} "
    S_ERROR="${C_RED}\u2691 [error] ${NO_FMT}\u2715 "

    U_ITEM="\u2192"
    U_SUBITEM="\u21E2"
    #U_SUBITEM="\u21B3"
}

cli.init() {
    function __write_header() {
        #clear && echo
        printf $"${@:1:1}" \
            $(echo -ne ${F_BOLD}${C_BLUE}${@:2:1}${NO_FMT}) \
            $(echo -ne ${C_ORANGE}${@:3}${NO_FMT}) && \
        for i in $(seq 1 ${cols}); do \
            printf "%s" $(echo -ne "\u2581"); \
            sleep .005; \
        done && \
        printf "%2s\n"
    }

    function _init() {
        __write_header "${@}"
    }

    cols=$(tput cols)
    _init "${@}"
}

cli.line() {
    [ -z "${1:-}" ] && printf "%s\n"
    for i in $(seq 1 ${cols}); do \
        printf "%s" $(echo -ne "\u2504${NO_FMT}"); \
    done && \
    [ -z "${1:-}" ] && printf "%2s\n"
    return 0
}

cli.move_to_col() {
    echo -ne "echo -en \\033[${1:-0}G"
}

cli.info() {
    cli.move_to_col 0
    echo -ne "${S_INFO}"
}

cli.warn() {
    cli.move_to_col 0
    echo -ne "${S_WARN}"
}

cli.error() {
    cli.move_to_col 0
    echo -ne "${S_ERROR}"
}

cli.print() {
    printf $"${@:1:1}" ${@:2}
}

cli.tab() {
    printf "%${1:-2}s" ' '
}

cli.item() {
    echo -ne "${U_ITEM} "
    cli.print "${@}"
}

cli.subitem() {
    echo -ne "${U_SUBITEM} "
    cli.print "${@}"
}

cli.emphasis() {
    echo -ne "${F_BOLD}${C_BLUE}"
    cli.print "${@}"
    echo -ne "${NO_FMT}"
}



cli.debug() {
    if [ "${debug:-,,}" == "true" ]; then
         [ ${#@} -lt 1 ] && \
            cli.move_to_col 0 && \
            echo -ne "${S_DEBUG}"

        [ "${1:-z}" == "text" ] && \
            cli.print "${@:2}"

        [ "${1:-z}" == "line" ] && \
            cli.move_to_col 0 && \
            cli.line "${@:2}"

        [ "${1:-z}" == "item" ] && \
            cli.item "${@:2}"

        [ "${1:-z}" == "subitem" ] && \
            cli.subitem "${@:2}"

        [ "${1:-z}" == "emphasis" ] && \
            cli.emphasis "${@:2}"
    fi
    set -e # why we need to set it again?
}

cli.dbg_item() {
    [ "${debug:-,,}" == "true" ] && \
        echo -ne "${U_ITEM} " && \
        cli.print "${@}"
}
cli.dbg_subitem() {
    [ "${debug:-,,}" == "true" ] && \
        echo -ne "${U_SUBITEM} " && \
        cli.print "${@}"
}



cli.color() {
    color=${1:-NONE}
    eval "echo -ne \${C_${color^^}}"
}

cli.arrow() {
    case ${1:-} in
        top) arrow='\u21E1';;
        left) arrow='\u21E0' ;;
        bottom) arrow='\u21E3' ;;
        right) arrow='\u21E2' ;;
    esac

    echo -ne "${arrow}"
}

cli.__load__

# vim: ts=4:sw=4:sts=4:et

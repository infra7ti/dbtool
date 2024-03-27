#!/usr/bin/bash
set -euo pipefail

# -- Host Class ---------------------------------------------------------------

host.__load__() {
    source ${libdir}/builtin/iniparse.bash
    unset -v host

    options+='h:'
    arguments['h']="host"
}

host.set() {
    function __in_array() {
        local a=${@:2}
        [[ " ${a[*]} " =~ " ${1} " ]] \
            && return 0 \
            || return 1
    }

    function _validate_host() {
        __in_array ${host:-} "${_HOSTS[@]}" || \
        (
            ${ui}.error
            ${ui}.print $"Invalid host: %s: " ${host:-'(empty)'}
            kill -TERM ${$} 2>&1 > /dev/null
        )
        return 0
    }

    function _get_config() {
        local _host=${host}
        set +eu

        cfg_parser "${cfgdir}/hosts/${_host}.ini"

        cfg_section_engines
        local _postgresql=${postgresql}
        local _mysql=${mysql}

        if [[ "${_postgresql,,}" == "true" ]]; then
            cfg_section_postgresql
            query_tool='psql'
            create_tool='createdb'
            drop_tool='dropdb'
            dump_tool='pg_dump'
            restore_tool='pg_restore'
        fi

        declare -Ag host=(
            [name]=${_host}
            [db_env]=${env}
            [db_host]=${db_host}
            [db_port]=${db_port}
            [db_user]=${db_user}
            [db_pass]=${db_password}
        )

        exec=
        eval cfg_section_${query_tool}
        host+=(
            [query_tool]=${exec:-$(which ${query_tool})}
            [query_extraopts]=${extraopts}
            [query_ext]=${extension}
        )

        exec=
        host+=(
            [create_tool]=${exec:-$(which ${create_tool})}
            [drop_tool]=${exec:-$(which ${drop_tool})}
        )

        exec=
        eval cfg_section_${dump_tool}
        host+=(
            [dump_tool]=${exec:-$(which ${dump_tool})}
            [dump_format]=${dump_format:-'custom'} # postgresql only
            [dump_extraopts]=${extraopts}
            [dump_ext]=${extension}
        )

        exec=
        eval cfg_section_${restore_tool}
        host+=(
            [restore_tool]=${exec:-$(which ${restore_tool})}
            [restore_format]=${dump_format:-'custom'} # postgresql only
            [restore_extraopts]=${extraopts}
            [restore_ext]=${extension}
        )

        set -eu
        return 0
    }

    declare -a _HOSTS=(
        $(find ${cfgdir}/hosts/ \
            -type f \
            -name \*.ini \
            -exec basename {} \; \
            | sed 's/.ini//g'
        )
    )

    _validate_host
    _get_config

    hostname=${host[name]}
    if [[ ! -z "${hostname}" ]]; then
        ${ui}.debug 'line' 'compact'
        ${ui}.info
        ${ui}.item $"Selecting current server [host %s %s]\n" \
            $(${ui}.color gold; ${ui}.arrow right; ${ui}.color) \
            ${hostname}
    fi
}

host.__load__

# vim: ts=4:sw=4:sts=4:et

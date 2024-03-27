#!/usr/bin/bash
set -euo pipefail

# -- CreateDb Class ------------------------------------------------------------

createdb.__load__() {
    return 0
}

createdb.run() {
    local _logdir=$(pwd)/logs
    local _pgpassfile=~/.pgpass
    declare -A pids=()

    function __write_pgpass() {
        if [[ ! -z "${host[name]}" ]]; then
            touch ${_pgpassfile} && \
            chmod 0600 ${_pgpassfile}
            printf "%s:%s:*:%s:%s" \
                ${host[db_host]} \
                ${host[db_port]} \
                ${host[db_user]} \
                ${host[db_pass]} \
            > ${_pgpassfile}
        fi
    }

    function __pre() {
        ${ui}.debug 'text' '\n'
        mkdir -p ${_logdir}
        __write_pgpass
        echo
    }

    function __post() {
        rm -rf ${_pgpassfile}
    }

    function __wait_processes() {
        ${ui}.info && \
        ${ui}.item $"Waiting for processes to complete\n"
        ${ui}.line 'compact'
        while true; do
            alive_pids=()
            for _pid in "${!pids[@]}"; do
                _db=${pids[${_pid}]}
                kill -0 "${_pid}" 2>/dev/null \
                    && _etime[${_pid}]=$(ps -o etimes= -p ${_pid} || :) \
                    && alive_pids+="${_pid} "
                ${ui}.info && \
                    ${ui}.print '%s ' $(${ui}.color green; echo "[createdb]")
                ${ui}.color && \
                    ${ui}.subitem $"process still running "
                ${ui}.print '%s ' \
                    $(${ui}.color gold; ${ui}.arrow right; ${ui}.color)
                ${ui}.print "[db=${_db}, pid=${_pid}, etime=%ss]\n" \
                    ${_etime[${_pid}]}
            done
            [ ${#alive_pids[@]} -eq 0 ] && break
            sleep 5
        done
        ${ui}.print '\n'
        ${ui}.info && \
        ${ui}.print '%s ' $(${ui}.color green; echo "[createdb]")
        ${ui}.color && ${ui}.subitem $"all processes terminated\n"
        ${ui}.line 'compact'
    }

    function __createdb()  {
        local _createdb=$(which createdb || exit -1)
        local _logfile=create-${db}-$(date +"%Y%m%d%H%M%S").log
        local _cmd="${_createdb} \
            -h ${host[db_host]} \
            -p ${host[db_port]} \
            -U ${host[db_user]} \
            ${host[create_extraopts]:-} \
            -O ${host[db_user]} ${db}"
        _cmd=$(echo -ne ${_cmd})
        ${ui}.debug 'line' 'compact'
        ${ui}.debug && ${ui}.tab 2
        ${ui}.debug 'subitem' $"Running command:\n"
        #${ui}.debug 'text' "$(${ui}.color gold)${_cmd//${_restoredir}\//} \
        ${ui}.debug 'text' "$(${ui}.color gold)${_cmd} \
            $(${ui}.color)" \
                | fold -sw 60 \
                | sed "s/^/$(printf '%14s' ' ')/g"
        ${ui}.debug 'text' '\n'
        ${ui}.debug && ${ui}.tab 2
        ${ui}.debug 'subitem' $"Process will run in backgroud [logfile=%s]\n" \
            ${_logfile}
        ${_cmd} > ${_logdir}/${_logfile} 2>&1 &
        pids+=([$!]=${db})
    }

    function __run() {
        ${ui}.debug 'text' '\n'
        dbs="${dblist}"
        test -f ${cfgdir}/databases/${dblist}.txt && \
            dbs=$(< ${cfgdir}/databases/${dblist}.txt);
        for db in ${dbs}; do
        ${ui}.info && \
            ${ui}.item $"Starting %s %s [host=%s, db=%s]\n" \
                "createdb" \
                $(${ui}.color gold; ${ui}.arrow right; ${ui}.color) \
                ${host[name]} \
                ${db}
            __createdb
            ${ui}.debug 'text' '\n'
        done
        __wait_processes
    }

    __pre
    __run
    __post
}

createdb.__load__

# vim: ts=4:sw=4:sts=4:et

###############################################################################
# Copyright (c) 2022 GOTUNIXCODE
# Copyright (c) 2022 Justin Ovens
# All rights reserved.
#
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
###############################################################################
#!/bin/bash

###############################################################################
# Paramaters
###############################################################################
#   -h                      -- Display help
#   --display_options       -- Display termination options before running
#   --dry                   -- Enable/disable dry-run mode
#   --debug                 -- Enable/disable debug mode
#   --purge                 -- Enable/disable docker purge
#   --env                   -- Specify one or more environment files to load
#   --container_name        -- Name of the container running
#   --compose_file          -- Specify compose file
#   --remote_host           -- Specify remote host
#   --platform              -- Specify platform (docker, swarm, kubernetes)
###############################################################################

# Variables
VERSION="1.0.1"
DATE=$(date '+%Y%m%d')
TIME=$(date '+%H-%M')
PAUSE=10
FUNCTION_FILES=(
    "functions/common_functions.sh"
    "functions/terminate_functions.sh"
)

function get_options {
    OPTSPEC=":h-:"

    while getopts "${OPTSPEC}" OPTCHAR; do
        case "${OPTCHAR}" in
            -)
                case "${OPTARG}" in
                    display_options)
                        if [[ -z "${DISPLAY_OPTIONS}" || "${DISPLAY_OPTIONS}" == false ]]; then
                            DISPLAY_OPTIONS=true
                        else
                            DISPLAY_OPTIONS=false
                        fi
                        ;;
                    dry)
                        if [[ -z "${DRY_RUN}" || "${DRY_RUN}" == false ]]; then
                            DRY_RUN=true
                        else
                            DRY_RUN=false
                        fi
                        ;;
                    debug)
                        if [[ -z "${DEBUG}" || "${DEBUG}" == false ]]; then
                            DEBUG=true
                        else
                            DEBUG=false
                        fi
                        ;;
                    purge)
                        if [[ -z "${PURGE}" || "${PURGE}" == false ]]; then
                            PURGE=true
                        else
                            PURGE=false
                        fi
                        ;;
                    env)
                        ENV_FILE="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${ENV_FILE}" || "${ENV_FILE}" == -* ]]; then
                            crit_message "env - ${ENV_FILE} is not valid"
                        else
                            ENV_FILES+=("${ENV_FILE}")
                        fi
                        ;;
                    remote_host)
                        RHOST="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${RHOST}" || "${RHOST}" == -* ]]; then
                            crit_message "remote_host - ${RHOST} is not valid"
                        else
                            REMOTE_HOST+=("${RHOST}")
                        fi
                        ;;
                    container_name)
                        CONTAINER_NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${CONTAINER_NAME}" || "${CONTAINER_NAME}" == -* ]]; then
                            crit_message "container_name - ${CONTAINER_NAME} is not valid"
                        fi
                        ;;
                    compose_file)
                        COMPOSE_FILE="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${COMPOSE_FILE}" || "${COMPOSE_FILE}" == -* ]]; then
                            crit_message "compose_file - ${COMPOSE_FILE} is not valid"
                        fi
                        ;;
                    platform)
                        PLATFORM="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${PLATFORM}" || "${PLATFORM}" == -* ]]; then
                            crit_message "platform - ${PLATFORM} is not valid"
                        fi
                        ;;
                esac;;
            h)
                display_help
                ;;
            \?)
                crit_message "Unknown option: ${OPTARG}"
                ;;
            :)
                crit_message "${OPTARG} requires an argument"
                ;;
        esac
    done
}

function display_options {
    if [[ -n "${DISPLAY_OPTIONS}" && "${DISPLAY_OPTIONS}" == true ]]; then
        info_message "###############################################################################"
        info_message "${0} - Termination options"
        info_message "###############################################################################"
        info_message "General options:"
        if [[ -z "${DRY_RUN}" || "${DRY_RUN}" == false ]]; then
            info_message "  -> Dry run              :   FALSE"
        else
            info_message "  -> Dry run              :   TRUE"
        fi
        if [[ -z "${DEBUG}" || "${DEBUG}" == false ]]; then
            info_message "  -> Debugging            :   FALSE"
        else
            info_message "  -> Debugging            :   TRUE"
        fi
        if [[ -z "${PURGE}" || "${PURGE}" == false ]]; then
            info_message "  -> Purge                :   FALSE"
        else
            info_message "  -> Purge                :   TRUE"
        fi
        info_message "  -> Container name       :   ${CONTAINER_NAME}"
        info_message "  -> Compose file         :   ${COMPOSE_FILE}"
        if [[ ! -z "${REMOTE_HOST}" ]]; then
            info_message "Remote hosts:"            
            if [[ "$(declare -p FUNCTION_FILES)" =~ "declare -a" ]]; then
                for remote_host in "${REMOTE_HOST[@]}"; do
                    info_message "  -> Remote host    :   ${remote_host}"
                done
            else
                info_message "  -> Remote host    :   ${REMOTE_HOST}"
            fi
        fi
        if [[ ! -z "${ENV_FILES}" ]]; then
            info_message "Environmental files:"
            for env_file in "${ENV_FILES[@]}"; do
                info_message "  -> Environmental file   :   ${env_file}"
            done
        fi
        info_message "###############################################################################"
    fi
}

function display_help {
    echo "Help file"
    exit 1
}

###############################################################################
# MAIN - THis is where all the magic happens
###############################################################################
START=$(date '+%Y-%m-%d at %H:%M:%S')
echo "[ INFO ] - Script     : $0"
echo "[ INFO ] - Paramaters : $*"
echo "[ INFO ] - Version    : ${VERSION}"

if [[ -n "${FUNCTION_FILES}" ]]; then
    if [[ "$(declare -p FUNCTION_FILES)" =~ "declare -a" ]]; then
        for file in "${FUNCTION_FILES[@]}"; do
            if [[ -f "${file}" ]]; then
                echo "[ INFO ] - Loading ${file}"
                source ${file}
            else
                echo "[ CRIT ] - Function file missing: ${file}"
                exit 1
            fi
        done
    else
        echo "[ CRIT ] - FUNCTION_FILES is not defined as an array"
        exit 1
    fi
else
    echo "[ CRIT ] - FUNCTION_FILES variable is not defined"
    exit 1
fi

get_options "$@"
load_environment_files
display_options
info_message "Termination started at: ${START}"
terminate
END=$(date '+%Y-%m-%d at %H:%M:%S')
info_message "Termination completed at: ${END}"

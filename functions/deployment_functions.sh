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

                    compose_file)
                        COMPOSE_FILE="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${COMPOSE_FILE}" || "${COMPOSE_FILE}" == -* ]]; then
                            crit_message "compose_file - ${COMPOSE_FILE} is not valid"
                        fi
                        ;;

                    tag)
                        TAG="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${TAG}" || "${TAG}" == -* ]]; then
                            crit_message "tag - ${TAG} is not valid"
                        fi
                        ;;

                    platform)
                        PLATFORM="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${PLATFORM}" || "${PLATFORM}" == -* ]]; then
                            crit_message "platform - ${PLATFORM} is not valid"
                        fi
                        ;;

                    replicas)
                        REPLICAS="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${REPLICAS}" || "${REPLICAS}" == -* ]]; then
                            crit_message "replicas - ${REPLICAS} is not valid"
                        fi
                        ;;

                    *)
                        if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                            crit_message "Unknown option --${OPTARG}"
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

function display_help {
    echo "Display help"
    exit 1
}

function display_options {
    if [[ -n "${DISPLAY_OPTIONS}" && "${DISPLAY_OPTIONS}" == true ]]; then
        info_message "###############################################################################"
        info_message "${0} - Deployment Options"
        info_message "###############################################################################"
        info_message "General options:"
        info_message "  -> Platform             :   ${PLATFORM}"
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
        if [[ ! -z "${REMOTE_HOST}" ]]; then
            info_message "Remote host(s):"
            if [[ "$(declare -p REMOTE_HOST)" =~ "declare -a" ]]; then
                for remote_host in "${REMOTE_HOST[@]}"; do
                    info_message "  -> Remote host          :   ${remote_host}"
                done
            else
                info_message "  -> Remote host          :   ${REMOTE_HOST}"
            fi
        fi
        info_message "Container:"
        info_message "  -> Image name           :   ${IMAGE_NAME}"
        info_message "  -> Image tag            :   ${TAG}"
        info_message "  -> Container name       :   ${CONTAINER_NAME}"
        info_message "Source registry:"
        info_message "  Registry address        :   ${REGISTRY_ADDR}"
        info_message "  Registry organization   :   ${REGISTRY_ORG}"
        if [[ ! -z "${ENV_FILES}" ]]; then
            info_message "Environmental file(s):"
            if [[ "$(declare -p REMOTE_HOST)" =~ "declare -a" ]]; then
                for env_file in "${ENV_FILES[@]}"; do
                    info_message "  -> Environmental file:  :   ${env_file}"
                done
            else
                info_message "  -> Environmental file:  :   ${ENV_FILES}"
            fi
        fi
        info_message "###############################################################################"
    fi
}

function deployment {
    # Add any ENVIRONMENTAL variables required here
    if [[ -z "${IMAGE_NAME}" || -z "${CONTAINER_NAME}" || -z "${TAG}" || \
          -z "${PLATFORM}" || -z "${REGISTRY_ADDR}" || -z "${REGISTRY_ORG}" ]]; then
        crit_message "Required environemntal variables missing"
    fi
    if [[ "${PLATFORM}" == "docker" ]]; then
        if [[ -z "${REMOTE_HOST}" ]]; then
            docker_rm "localhost" "${CONTAINER_NAME}"
            run_deployment "localhost"
        else
            if [[ "$(declare -p REMOTE_HOST)" =~ "declare -a" ]]; then
                for remote_host in "${REMOTE_HOST[@]}"; do
                    docker_rm "${remote_host}" "${CONTAINER_NAME}"
                    run_deployment "${remote_host}"
                done
            else
                docker_rm "${REMOTE_HOST}" "${CONTAINER_NAME}"
                run_deployment "${REMOTE_HOST}"
            fi
        fi
    else
        crit_message "Only docker supported currently"
    fi
}

function run_deployment {
    DOCKER_HOST="${1}"

    echo "Deployment"
}

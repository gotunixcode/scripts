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

function info_message {
    echo "[ INFO ] - ${1}"
}

function warn_message {
    echo "[ WARN ] - ${1}"
}

function crit_message {
    echo "[ CRIT ] - ${1}"
    exit 1
}

function run_command {
    echo "[ INFO ] - Running command: [${1}]"
    if [[ -z "${DRY_RUN}" || "${DRY_RUN}" == false ]]; then
        if [[ -z "${DEBUG}" || "${DEBUG}" == false ]]; then
            eval "${1} > /dev/null 2>&1"
            if [ $? -eq 0 ]; then
                info_message "Command completed successfully"
            else
                crit_message "Command failure"
            fi
        else
            eval "${1}"
            if [ $? -eq 0 ]; then
                info_message "Command completed successfully"
            else
                crit_message "Command failure"
            fi
        fi
    fi
}

function load_environment_files {
    if [[ -n "${ENV_FILES}" ]]; then
        if [[ "$(declare -p ENV_FILES)" =~ "declare -a" ]]; then
            for env_file in "${ENV_FILES[@]}"; do
                if [[ -f "${env_file}" ]]; then
                    info_message "Loading environmental file: ${env_file}"
                    source ${env_file}
                else
                    warn_message "Environmental file missing: ${env_file}"
                fi
            done
        else
            crit_message "ENV_FILES was not defined as an array"
        fi
    else
        warn_message "ENV_FILES variable is not defined"
    fi
}

function generate_tags {
    if [[ ! -z "${TAG_OVERRIDE}" ]]; then
        PRIMARY_TAG=${TAG_OVERRIDE}
    else
        PRIMARY_TAG=${DATE}.${TIME}
    fi

    if [[ "${BRANCH}" == "main" || "${BRANCH}" == "master" ]]; then
        SECONDARY_TAG="latest"
    elif [[ "${BRANCH}" == "development" || "${BRANCH}" == "devel" || "${BRANCH}" == "dev" ]]; then
        SECONDARY_TAG="snapshot"
    else
        SECONDARY_TAG=${BRANCH}
    fi
}

function docker_purge {
    if [[ "${PLATFORM}" == "docker" ]]; then
        if [[ "${PURGE}" == true ]]; then
            if [[ -z "${REMOTE_HOST}" ]]; then
                run_command "echo y | docker system prune -a"
            else
                if [[ "$(declare -p REMOTE_HOST)" =~ "declare -a" ]]; then
                    for remote_host in "${REMOTE_HOST[@]}"; do
                        run_command "echo y | docker -H ${remote_host} system prune -a"
                    done
                else
                    run_command "echo y | docker -H ${REMOTE_HOST} system prune -a"
                fi
            fi
        fi
    fi
}

function docker_push {
    if [[ -n "${PUSH}" && "${PUSH}" == true ]]; then
        if [[ -z "${REGISTRY_USERNAME}" || -z "${REGISTRY_PASSWORD}" ]]; then
            info_message "Registry username or password not supplied (AUTHENTICATION DISABLED)"
        else
            run_command "docker login --username ${REGISTRY_USERNAME} --password ${REGISTRY_PASSWORD}"
        fi
    else
        info_message "Skipping push to registry"
    fi
}

function docker_run {
    PREFIX=${2}
    COMMAND=${1}

    if [[ -z "${REMOTE_HOST}" ]]; then
        run_command "${PREFIX} docker ${COMMAND}"
    else
        if [[ "$(declare -p REMOTE_HOST)" =~ "declare -a" ]]; then
            for remote_host in "${REMOTE_HOST[@]}"; do
                run_command "${PREFIX} doker -H ${remote_host} ${COMMAND}"
            done
        else
            run_command "${PREFIX} docker -H ${REMOTE_HOST} ${COMMAND}"
        fi
    fi
}

function docker_stop {
    DOCKER_HOST=${1}
    if [ "$(docker -H ${DOCKER_HOST} ps -qa -f name=${CONTAINER_NAME})" ]; then
        info_message "Container [${CONTAINER_NAME}] found on ${DOCKER_HOST}"
        if [ "$(docker -H ${DOCKER_HOST} ps -q -f name=${CONTAINER_NAME})" ]; then
            info_message "Stopping container [${CONTAINER_NAME}] on ${DOCKER_HOST}"
            run_command "docker -H ${DOCKER_HOST} stop ${CONTAINER_NAME}"
        fi
    fi
}

function docker_rm {
    DOCKER_HOST=${1}
    if [ "$(docker -H ${DOCKER_HOST} ps -qa -f name=${CONTAINER_NAME})" ]; then
        info_message "Container [${CONTAINER_NAME}] found on ${DOCKER_HOST}"
        if [ "$(docker -H ${DOCKER_HOST} ps -q -f name=${CONTAINER_NAME})" ]; then
            info_message "Stopping container [${CONTAINER_NAME}] on ${DOCKER_HOST}"
            run_command "docker -H ${DOCKER_HOST} stop ${CONTAINER_NAME}"
        fi
        info_message "Removing container [${CONTAINER_NAME}] on ${DOCKER_HOST}"
        run_command "docker -H ${DOCKER_HOST} rm ${CONTAINER_NAME}"
    fi
}

function docker_volume_rm {
    DOCKER_HOST=${1}
    VOLUME=${2}
    docker -H ${DOCKER_HOST} volume inspect ${VOLUME} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        run_command "docker -H ${DOCKER_HOST} volume rm ${VOLUME}"
    fi
}

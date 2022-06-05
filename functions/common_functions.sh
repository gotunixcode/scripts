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


function run_command {
    echo "[ INFO ] - Running command: [${1}]"
    if [[ -z "${DRY_RUN}" || "${DRY_RUN}" == false ]]; then
        if [[ -z "${DEBUG}" || "${DEBUG}" == false ]]; then
            eval "${1} > /dev/null 2>&1"
            if [ $? -eq 0 ]; then
                echo "[ INFO ] - Command completed successfully"
            else
                echo "[ CRIT ] - Command failure"
                exit 1
            fi
        else
            eval "${1}"
            if [ $? -eq 0 ]; then
                echo "[ INFO ] - Command completed successfully"
            else
                echo "[ CRIT ] - Command failure"
                exit 1
            fi
        fi
    fi
}

function load_environmental_files {
    if [[ -n "${ENV_FILES}" ]]; then
        if [[ "$(declare -p ENV_FILES)" =~ "declare -a" ]]; then
            for env_file in "${ENV_FILES[@]}"; do
                if [[ -f "${env_file}" ]]; then
                    echo "[ INFO ] - Loading environmental file: ${env_file}"
                    source ${env_file}
                else
                    echo "[ WARN ] - Environmental file missing: ${env_file}"
                fi
            done
        else
            echo "[ CRIT ] - ENV_FILES was not defined as an array"
            exit 1
        fi
    else
        info "[ WARN ] - ENV_FILES variable is not defined"
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

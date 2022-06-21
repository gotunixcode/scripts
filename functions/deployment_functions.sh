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

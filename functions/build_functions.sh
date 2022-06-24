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

function build {
    # Add checks for environmental variables that are required.
    if [[ -z "${IMAGE_NAME}" || -z "${REGISTRY_ADDR}" || -z "${REGISTRY_ORG}" || \
          -z "${PRIMARY_TAG}" || -z "${SECONDARY_TAG}" || -z "${PLATFORM}" ]]; then
        crit_message "Required environmental variables missing"
    fi
    if [[ "${PLATFORM}" == "docker" ]]; then
        if [[ -z "${REMOTE_HOST}" ]]; then
            run_build "localhost"
        else
            if [[ "$(declare -p REMOTE_HOST)" =~ "declare -a" ]]; then
                for remote_host in "${REMOTE_HOST[@]}"; do
                    run_build "${remote_host}"
                done
            else
                run_build "${REMOTE_HOST}"
            fi
        fi
    fi
}

function run_build {
    DOCKER_HOST="${1}"
    echo "Run build"
}

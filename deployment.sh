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
#   --display_options       -- Display deployment options before running
#   --dry                   -- Enable/disable dry-run mode
#   --debug                 -- Enable/disable debug mode
#   --purge                 -- Purge old images after deployment
#   --env                   -- Specify environmental file to load (you can 
#                              load multiple)
#   --tag                   -- The image tag we are going to use
#   --source_target         -- The source target we are using
#   --container_name        -- The name of the container
#   --compose_file          -- Specify docker-compose.yml file to use
#   --image_name            -- The name of the image
#   --registry_addr         -- Address to docker registry
#   --registry_org          -- Organization on the docker registry
#   --remote_host           -- Specify one or more remote hosts to deploy on
#   --platform              -- Specify platform (docker, swarm, kubernetes)
#   --replicas              -- Specify replica count (swarm only)
###############################################################################

# Variables
VERSION="1.0.0"
DATE=$(date '+%Y%m%d')
TIME=$(date '+%H-%M')
PAUSE=10
FUNCTION_FILES=(
    "functions/common_functions.sh"
    "functions/deployment_functions.sh"
)

###############################################################################
# MAIN - This is where all the magic happens
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
info_message "Deployment started at: ${START}"
deployment
END=$(date '+%Y-%m-%d at %H:%M:%S')
info_message "Deployment completed at: ${END}"


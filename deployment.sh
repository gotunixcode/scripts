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
                    source_target)
                        SOURCE_TARGET="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${SOURCE_TARGET}" || "${SOURCE_TARGET}" == -* ]]; then
                            crit_message "source_target - ${SOURCE_TARGET} is not valid"
                        fi
                        ;;
                    container_name)
                        CONTAINER_NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${CONTAINER_NAME}" || "${CONTAINER_NAME}" == -* ]]; then
                            crit_message "container_name - ${CONTAINER_NAME} is not valid"
                        fi
                        ;;
                    image_name)
                        IMAGE_NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${IMAGE_NAME}" || "${IMAGE_NAME}" == -* ]]; then
                            crit_message "image_name - ${IMAGE_NAME} is not valid"
                        fi
                        ;;
                    registry_addr)
                        REGISTRY_ADDR="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${REGISTRY_ADDR}" || "${REGISTRY_ADDR}" == -* ]]; then
                            crit_message "registry_addr - ${REGISTRY_ADDR} is not valid"
                        fi
                        ;;
                    registry_org)
                        REGISTRY_ORG="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${REGISTRY_ORG}" || "${REGISTRY_ORG}" == -* ]]; then
                            crit_message "registry_org - ${REGISTRY_ORG} is not valid"
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

function display_options {
    if [[ -n "${DISPLAY_OPTIONS}" && "${DISPLAY_OPTIONS}" == true ]]; then
        info_message "###############################################################################"
        info_message "${0} - Deployment options"
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
        if [[ -z "${PLATFORM}" ]]; then
            info_message "  -> Platform             :   NONE"
        else
            info_message "  -> Platform             :   ${PLATFORM}"
        fi
        if [[ -z "${PURGE}" || "${PURGE}" == false ]]; then
            info_message "  -> Purge                :   FALSE"
        else
            info_message "  -> Purge                :   TRUE"
        fi
        info_message "  -> Container name       :   ${CONTAINER_NAME}"
        info_message "  -> Docker compose       :   ${COMPOSE_FILE}"
        if [[ ! -z "${REMOTE_HOST}" ]]; then
            info_message "  -> Remote build host    :   ${REMOTE_HOST}"
        fi
        info_message "Registry:"
        info_message "  -> Registry address     :   ${REGISTRY_ADDR}"
        info_message "  -> Registry organization:   ${REGISTRY_ORG}"
        info_message "  -> Image name           :   ${IMAGE_NAME}"
        info_message "  -> Image tag            :   ${TAG}"
        if [[ ! -z "${ENV_FILES}" ]]; then
            info_message "Environmental files:"
            for env_file in "${ENV_FILES[@]}"; do
                info_message "  -> Environmental file   :   ${env_file}"
            done
        fi
        info_message "###############################################################################"
        info_message "Pausing for ${PAUSE} seconds"
        sleep ${PAUSE}
    fi
}

function display_help {
    info_message "###############################################################################"
    info_message "${0} Display Help"
    info_message "###############################################################################"
    info_message "We will use a combination of enviromental variables to run the build process."
    info_message "These variables can be loaded from an environmental file or set using"
    info_message "command line paramaters."
    info_message ""
    info_message "Environmental Variables are as follows"
    info_message "  DISPLAY_OPTIONS             -- When this is set to true all build options will"
    info_message "                                 be displayed prior to building."
    info_message "  DRY_RUN                     -- When this is set to true we will echo any command"
    info_message "                                 we run without actually running it."
    info_message "  DEBUG                       -- When this is set to true we will not only display"
    info_message "                                 the command we are running but we will also display"
    info_message "                                 the output of said command."
    info_message "  PURGE_IMAGES                -- When this is set to true we will purge all stale images,"
    info_message "                                 containers, and volumes."
    info_message "  ENV_FILES                   -- This should be an array consiting of environmental files"
    info_message "                                 to load."
    info_message "  REMOTE_HOSTS                -- This should be an array of hosts to remotely run deployment"
    info_message "                                 on. By default this will be for docker but if kuberenetes"
    info_message "                                 is specified we will attempt to run on remote kubernetes."
    info_message "  TAG                         -- Use this to specify the image tag to deploy."
    info_message "  SOURCE_TARGET               -- Specify the source target to deploy (based on build target)"
    info_message "  CONTAINER_NAME              -- Specify the deployment (container) name"
    info_message "  REGISTRY_ADDR               -- The registry address to push the docker images to."
    info_message "  REGISTRY_ORG                -- The docker orginzation used to push images."
    info_message "  IMAGE_NAME                  -- The name of the image we are deploying."
    info_message "  PLATFORM                    -- Specify platform (docker, swarm, kubernetes"
    info_message "  REPLICAS                    -- Specify replicas (only for swarm)"
    info_message "  COMPOSE_FILE                -- Specify docker-compose file to use for deployment"
    info_message ""
    info_message "Command line paramaters [No arguments]"
    info_message ""
    info_message "  -h                          -- Display this screen"
    info_message "  --display_options           -- Used to set DISPLAY_OPTIONS variable"
    info_message "  --dry                       -- Used to set DRY_RUN variable"
    info_message "  --debug                     -- Used to set DEBUG variable"
    info_message "  --purge                     -- Used to set PURGE_IMAGES variable"
    info_message ""
    info_message "Command line paramaters [Additional arguments required]"
    info_message ""
    info_message "  --env                       -- Used to set ENV_FILES array [requires env file path/name]"
    info_message "                                 You can load multiple by passing multiple --env [path/file]."
    info_message "  --tag                       -- Used to set TAG variable [requires tag name]."
    info_message "  --registry_addr             -- Used to set REGISTRY_ADDR varible [requires address]."
    info_message "  --registry_org              -- Used to set REGISTRY_ORG variable [requires org name]."
    info_message "  --container_name            -- Used to set CONTAINER_NAME variable [requires container name]."
    info_message "  --image_name                -- Used to set IMAGE_NAME variable [requires image name]."
    info_message "  --source_target             -- Used to set the SOURCE_TARGET variable [requires target name]."
    info_message "  --remote_host               -- Used to set the REMOTE_HOSTS variable [requires remote hostname]."
    info_message "  --platform                  -- Set PLATFORM     [requires platform type]"
    info_message "  --replicas                  -- Set REPLICAS     [requires replica count]"
    info_message "  --compose_file              -- Set COMPOSE_FILE [requires path to compose file]"
    info_message "###############################################################################"
    exit 1
}

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

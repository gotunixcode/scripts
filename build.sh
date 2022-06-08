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
#   --display_options       -- Display build options before running the build
#   --dry                   -- Enable/Disable dry-run mode
#   --debug                 -- Enable/Disable debugging
#   --push                  -- Enable/Disable push to docker registry
#   --purge                 -- Enable/Disable purging old containers, volumes,
#                              and images
#   --env                   -- Specify environmental file to load (you can
#                              specify multiple files to load
#   --tag                   -- Override the primary tag used
#   --branch                -- Specify the branch we are building from,
#                              this happens automatically on local builds,
#                              but is needed for azure devops/github
#   --build_target          -- Specify build_target (used to add custom
#                              configuration to a container during builds)
#   --image_name            -- Specify the name to use for the image
#   --registry_addr         -- Specify docker registry to use
#   --registry_org          -- Specify docker organization to use
#   --registry_username     -- Specify username used to auth with registry
#   --registry_password     -- Specify password used to auth with registry
#
# If we are building a container based on another container image we can
# specify the registry address, orginzation, imagename, and tag to use.
#
#   --from_registry_addr    -- Specify source docker registry
#   --from_registry_org     -- Specify source docker organization
#   --from_image_name       -- Specify source container image
#   --from_tag              -- Specify source container tag
#
# If we are using a remote docker system to build the image it can be
# specified here
#
#   --remote_host           -- Specify a remote host to run the build on
###############################################################################

# Variables
VERSION="1.0.1"
DATE=$(date '+%Y%m%d')
TIME=$(date '+%H-%M')
PAUSE=10
BRANCH=$(git symbolic-ref -q --short HEAD || git describe --tags --exact-match)
FUNCTION_FILES=(
    "functions/common_functions.sh"
    "functions/build_functions.sh"
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
                    push)
                        if [[ -z "${PUSH}" || "${PUSH}" == false ]]; then
                            PUSH=true
                        else
                            PUSH=false
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
                        if [[ -z "${REMOTE_HOST}" ]]; then
                            REMOTE_HOST="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                            if [[ -z "${REMOTE_HOST}" || "${REMOTE_HOST}" == -* ]]; then
                                crit_message "remote_host - ${REMOTE_HOST} is not valid"
                            fi
                        else
                            crit_message "Only specify a single remote host for builds"
                        fi
                        ;;
                    branch)
                        BRANCH="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${BRANCH}" || "${BRANCH}" == -* ]]; then
                            crit_message "branch - ${BRANCH} is not valid"
                        fi
                        ;;
                    build_target)
                        BUILD_TARGET="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${BUILD_TARGET}" || "${BUILD_TARGET}" == -* ]]; then
                            crit_message "build_target - ${BUILD_TARGET} is not valid"
                        else
                            BUILD_TARGETS+=("${BUILD_TARGET}")
                        fi
                        ;;
                    tag)
                        TAG_OVERRIDE="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${TAG_OVERRIDE}" || "${TAG_OVERRIDE}" == -* ]]; then
                            crit_message "tag - ${TAG_OVERRIDE} is not valid"
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
                    registry_username)
                        REGISTRY_USERNAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${REGISTRY_USERNAME}" || "${REGISTRY_USERNAME}" == -* ]]; then
                            crit_message "registry_username - ${REGISTRY_USERNAME} is not valid"
                        fi
                        ;;
                    registry_password)
                        REGISTRY_PASSWORD="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${REGISTRY_PASSWORD}" || "${REGISTRY_PASSWORD}" == -* ]]; then
                            crit_message "registry_password - ${REGISTRY_PASSWORD} is not valid"
                        fi
                        ;;
                    from_registry_addr)
                        FROM_REGISTRY_ADDR="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${FROM_REGISTRY_ADDR}" || "${FROM_REGISTRY_ADDR}" == -* ]]; then
                            crit_message "from_registry_addr - ${FROM_REGISTRY_ADDR} is not valid"
                        fi
                        SOURCE_REGISTRY=true
                        ;;
                    from_registry_org)
                        FROM_REGISTRY_ORG="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${FROM_REGISTRY_ORG}" || "${FROM_REGISTRY_ORG}" == -* ]]; then
                            crit_message "from_registry_org - ${FROM_REGISTRY_ORG} is not valid"
                        fi
                        SOURCE_REGISTRY=true
                        ;;
                    from_image_name)
                        FROM_IMAGE_NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${FROM_IMAGE_NAME}" || "${FROM_IMAGE_NAME}" == -* ]]; then
                            crit_message "from_image_name - ${FROM_IMAGE_NAME} is not valid"
                        fi
                        SOURCE_REGISTRY=true
                        ;;
                    from_tag)
                        FROM_TAG="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${FROM_TAG}" || "${FROM_TAG}" == -* ]]; then
                            crit_message "from_tag - ${FROM_TAG} is not valid"
                        fi
                        SOURCE_REGISTRY=true
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
                exit 1
                ;;
        esac
    done
}

function display_options {
    if [[ -n "${DISPLAY_OPTIONS}" && "${DISPLAY_OPTIONS}" == true ]]; then
        info_message "###############################################################################"
        info_message "${0} - Build options"
        info_message "###############################################################################"
        info_message "General options:"
        if [[ -z "${BRANCH}" ]]; then
            info_message "  -> Branch               :   NONE"
        else
            info_message "  -> Branch               :   ${BRANCH}"
        fi
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
        if [[ -z "${PUSH}" || "${PUSH}" == false ]]; then
            info_message "  -> Push                 :   FALSE"
        else
            info_message "  -> Push                 :   TRUE"
        fi
        if [[ ! -z "${REMOTE_HOST}" ]]; then
            info_message "  -> Remote build host    :   ${REMOTE_HOST}"
        fi
        if [[ ! -z "${SOURCE_REGISTRY}" ]]; then
            info_message "Source Registry (If any):"
            info_message "  -> Image name           :   ${FROM_IMAGE_NAME}"
            info_message "  -> Image tag            :   ${FROM_TAG}"
            info_message "  -> Registry address     :   ${FROM_REGISTRY_ADDR}"
            info_message "  -> Registry organization:   ${FROM_REGISTRY_ORG}"
        fi
        info_message "Destination registry:"
        info_message "  -> Image name           :   ${IMAGE_NAME}"
        info_message "  -> Tags:"
        info_message "      -> Primary tag      :   ${PRIMARY_TAG}"
        info_message "      -> Secondary tag    :   ${SECONDARY_TAG}"
        info_message "  -> Registry address     :   ${REGISTRY_ADDR}"
        info_message "  -> Registry organization:   ${REGISTRY_ORG}"
        info_message "  -> Registry username    :   ${REGISTRY_USERNAME}"
        info_message "  -> Registry password    :   ${REGISTRY_PASSWORD}"
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
    info_message "###############################################################################"
    info_message "${0} - Help"
    info_message "###############################################################################"
    info_message "We use a combination of environmental variables to run the build process"
    info_message "These variables can be set using environmental files or using command line"
    info_message "paramaters."
    info_message ""
    info_message "The environmental variables are as follows"
    info_message ""
    info_message "  DISPLAY_OPTIONS         -- Display build options before running build"
    info_message "  DRY_RUN                 -- Output commands we will run without running them"
    info_message "  DEBUG                   -- Display the output of commands we run"
    info_message "  PUSH                    -- Push the built image to the defined docker registry"
    info_message "  PURGE                   -- Purge old images, containers, and volumes"
    info_message "  BRANCH                  -- Specify the branch container is being built from"
    info_message "                             This happens automatically on local builds, but"
    info_message "                             might need to be specified on cicd workflows"
    info_message "  ENV_FILES               -- Array of environmental files to load (if any)"
    info_message "  TAG_OVERRIDE            -- Override the generated primary tag"
    info_message "  BUILD_TARGET            -- Specify which container to build, this is passed"
    info_message "                             as build arguments to the build process"
    info_message "  REGISTRY_ADDR           -- Specify the address of the docker registry"
    info_message "  REGISTRY_ORG            -- Specify the orginzation of the docker registry"
    info_message "  REGISTRY_USERNAME       -- Specify the username to use for the docker registry"
    info_message "  REGISTRY_PASSWORD       -- Specify the password to use for the docker registry"
    info_message "  IMAGE_NAME              -- Specify the name of the image we are building"
    info_message "  FROM_REGISTRY_ARRR      -- If building from a base image this is used to"
    info_message "                             specify the registry address to pull the image from"
    info_message "  FROM_REGISTRY_ORG       -- Same as above but the orginzation to use"
    info_message "  FROM_IMAGE_NAME         -- Same as above but the image_name to pull"
    info_message "  FROM_TAG                -- Same as above but that image tag to pull"
    info_message ""
    info_message "Command line paramaters [No additional arguments]"
    info_message ""
    info_message "  -h                      -- Display this screen"
	info_message "  --display_options       -- Used to set the DISPLAY_OPTIONS variable"
	info_message "  --dry                   -- Used to set the DRY_RUN variable"
	info_message "  --debug                 -- Used to set the DEBUG varible"
	info_message "  --push                  -- Used to set the PUSH variable"
	info_message "  --purge                 -- Used to set the PURGE variable"
	info_message ""
	info_message "Command line paramaters [Additional arguments required]"
	info_message ""
	info_message "  --branch                -- Set BRANCH             [requires branch name]"
	info_message "  --env                   -- Set ENV_FILES          [requires path/file"
    info_message "                                                     (can be multiple)]"
	info_message "  --build_target          -- Set BUILD_TARGET       [requires target name]"
	info_message "  --registry_addr         -- Set REGISTRY_ADDR      [requires registry address]"
	info_message "  --registry_org          -- Set REGISTRY_ORG       [requires registry org]"
	info_message "  --registry_username     -- Set REGISTRY_USERNAME  [requires username]"
	info_message "  --registry_password     -- Set REGISTRY_PASSWORD  [requires password"
	info_message "  --image_name            -- Set IMAGE_NAME         [requires name]"
	info_message ""
	info_message "If we are building a container bassed on another container image we can"
	info_message "specify the registry address, orginzation, image_name, and tag to use"
	info_message ""
	info_message "  --from_registry_addr    -- Set FROM_REGISTRY_ADDR [requires registry address]"
	info_message "  --from_registry_org     -- Set FROM_REGISTRY_ORG  [requires registry org]"
	info_message "  --from_image_name       -- Set FROM_IMAGE_NAME    [requires name]"
	info_message "  --from_tag              -- Set FROM_TAG           [requires tag]"
	info_message ""
	info_message "IF we are using a remote docker system to build the image it can be"
	info_message "specified here"
	info_message ""
	info_message "  --remote_host           -- Set REMOTE_HOST        [requires hostname/ip]"
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
                echo "[ INFO ] - Loading function file ${file}"
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
    echo "[ CRIT ] - FUNCTION_FILES variable not defined"
    exit 1
fi

run_command "docker --version"
PLATFORM="docker"
get_options "$@"
generate_tags
load_environment_files
info_message "Build started at ${START}"
display_options
docker_run "system prune -a" "echo y |"
build

END=$(date '+%Y-%m-%d at %H:%M:%S')
info_message "Build completed at: ${END}"
info_message "[TAGS: ${PRIMARY_TAG}, ${SECONDARY_TAG}]"

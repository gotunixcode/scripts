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

                    tag)
                        TAG_OVERRIDE="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                        if [[ -z "${TAG_OVERRIDE}" || "${TAG_OVERRIDE}" == -* ]]; then
                            crit_message "tag - ${TAG_OVERRIDE} is not valid"
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
        info_message "${0} - Build options"
        info_message "###############################################################################"
        info_message "General:"
        info_message "  -> Platform             :   ${PLATFORM}"
        info_message "  -> Branch               :   ${BRANCH}"
        if [[ -z "${DRY_RUN}" || "${DRY_RUN}" == false ]]; then
            info_message "  -> Dry Run              :   FALSE"
        else
            info_message "  -> Dry Run              :   TRUE"
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
        info_message "Remote Host:"
        info_message "  -> Remote host          :   ${REMOTE_HOST}"
        info_message "Build:"
        if [[ ! -z "${DOCKERFILE}" ]]; then
            info_message "  -> Dockerfile           :   ${DOCKERFILE}}"
        else
            info_message "  -> Dockerfile           :   NONE"
        fi
        info_message "  -> Image name           :   ${IMAGE_NAME}"
        info_message "  -> Tags:"
        info_message "      -> Primary tag      :   ${PRIMARY_TAG}"
        info_message "      -> Secondary tag    :   ${SECONDARY_TAG}"
        if [[ ! -z "${BUILD_TARGETS}" ]]; then
            info_message "  -> Build target(s):"
            for build_target in "${BUILD_TARGETS[@]}"; do
                info_message "      -> Target           :   ${build_target}"
            done
        fi
        info_message "Destination Registry:"
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

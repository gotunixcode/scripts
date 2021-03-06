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
build

END=$(date '+%Y-%m-%d at %H:%M:%S')
info_message "Build completed at: ${END}"
info_message "[TAGS: ${PRIMARY_TAG}, ${SECONDARY_TAG}]"

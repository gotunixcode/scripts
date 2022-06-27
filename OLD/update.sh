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

UPDATE_URL="https://raw.githubusercontent.com/gotunixcode/scripts/main"
SCRIPTS=("build")

function run_command {
    echo "[ INFO ] - Running command: [${1}]"
    eval "${1} > /dev/null 2>&1"
    if [ $? -eq 0 ]; then
        echo "[ INFO ] - Command completed successfully"
    else
        echo "[ CRIT ] - Command failure"
        exit 1
    fi
}

for script in "${SCRIPTS[@]}"; do
    run_command "wget ${UPDATE_URL}/${script}.sh -O ${script}.sh"
    run_command "chmod 0700 ${script}.sh"
done

if [[ ! -d "./functions" ]]; then
    run_command "mkdir functions"
fi

run_command "wget ${UPDATE_URL}/functions/common_functions.sh -O functions/common_functions.sh"
for script in "${SCRIPTS[@]}"; do
    if [[ ! -f "functions/${script}_functions.sh" ]]; then
        run_command "wget ${UPDATE_URL}/functions/${script}_functions.sh -O functions/${script}_functions.sh"
    fi
done
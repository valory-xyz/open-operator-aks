#!/bin/bash

# ------------------------------------------------------------------------------
#
#   Copyright 2023 Valory AG
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# ------------------------------------------------------------------------------

# Requires the following environment variables:
#   - PRIVATE_KEY: SSH Private key.

mkdir -p ~/.ssh
PUBLIC_KEY=$(ssh-keygen -y -f <(echo "$PRIVATE_KEY"))

# Amazon EC2 supports ED25519 and 2048-bit SSH-2 RSA keys for Linux instances.
if [[ $PUBLIC_KEY == ssh-rsa* ]]; then
    KEY_TYPE="rsa"
elif [[ $PUBLIC_KEY == ssh-ed25519* ]]; then
    KEY_TYPE="ed25519"
#elif [[ $PUBLIC_KEY == ssh-ecdsa* ]]; then
#    KEY_TYPE="ecdsa"
#elif [[ $PUBLIC_KEY == ssh-dss* ]]; then
#    KEY_TYPE="dsa"
else
    echo "Error: Unsupported SSH key type."
    exit 1
fi

PRIVATE_KEY_FILE="$HOME/.ssh/id_$KEY_TYPE"
PUBLIC_KEY_FILE="$HOME/.ssh/id_$KEY_TYPE.pub"

echo "$PRIVATE_KEY" > "$PRIVATE_KEY_FILE"
chmod 600 "$PRIVATE_KEY_FILE"

echo "$PUBLIC_KEY" > "$PUBLIC_KEY_FILE"
chmod 644 "$PUBLIC_KEY_FILE"

echo "PRIVATE_KEY_FILE=$PRIVATE_KEY_FILE" >> "$GITHUB_ENV"
echo "PUBLIC_KEY_FILE=$PUBLIC_KEY_FILE" >> "$GITHUB_ENV"
echo "TF_VAR_operator_ssh_pub_key_path=$PUBLIC_KEY_FILE" >> "$GITHUB_ENV"

echo "Private and public keys have been stored in \"$PRIVATE_KEY_FILE\" and \"$PUBLIC_KEY_FILE\" respectively."
echo "Public key file path has been stored in Terraform variable \"TF_VAR_operator_ssh_pub_key_path\"."
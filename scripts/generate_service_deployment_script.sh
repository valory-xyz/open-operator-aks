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


# This script generates the deploy_service.sh script to be executed on the host
# machine running an agent service.
# 
# Requires the following environment variables:
#   - SERVICE_REPO_URL: Service repository URL.
#   - SERVICE_ID: Public ID of the service found in SERVICE_REPO_URL.
#   - (Optional) SERVICE_REPO_TAG: Tag of the service release to be deployed.
#     If not defined, the script will automatically collect the latest tag.
#   - (Optional) GH_TOKEN: Github personal access token, required to access
#     private repositories.
#   - (Optional) VARS_CONTEXT: JSON context with Github variables.
#   - (Optional) SECRETS_CONTEXT: JSON context with Github secrets.
#
# Notes:
#   - Service variables are read from the file "./config/service_vars.env" and
#     overriden if the identifier is found in any context.
#   - keys.json context is read from the file "./config/keys.json" and
#     overriden if the identifier KEYS_JSON is found in any context.


parse_env_file() {
    # Overrides an .env file containing variables.
    #
    # For each variable VAR in the .env file, it outputs to $3
    # "export VAR=val", where "val" is either the value found in the
    # .env file, or overrien if found on the JSON object passed as
    # second argument.

    ENV_FILE="$1"
    JSON="$2"
    #DEPLOY_SERVICE_SCRIPT="$3"

    echo "   - Parsing .env file \"$ENV_FILE\""

    # Sanitize inputs
    if [[ ! -f "$ENV_FILE" ]]; then
        echo "   - .env file '$ENV_FILE' does not exist. Ignoring."
        return
    fi

    if [[ -z "${JSON// }" ]]; then
        JSON="{}"
    fi

    # Read variables
    VARS="$(grep -vE "^(#.*|\s*)$" $ENV_FILE | awk -F '=' '{ print "export", $0 }')"
    
    # Parse the JSON object and loop through its keys
    for VAR_NAME in $(echo "$JSON" | jq -r 'keys[]'); do
        VAR_VALUE=$(echo "$JSON" | jq -r ".$VAR_NAME")

        # Override variables in $VARS if existing in JSON
        if [[ -n "${VAR_VALUE// }" ]] && grep -q "export $VAR_NAME=" <<< "export $VARS="; then
            echo "     - Overriding variable $VAR_NAME"
            VARS=$(echo "$VARS" | sed "s#export $VAR_NAME=.*#export $VAR_NAME=\"$VAR_VALUE\"#")
        fi
    done

    echo "$VARS" >> $3
}



# ==================
# Script starts here
# ==================
echo "----------------------------"
echo "Generating deployment script"
echo "----------------------------"
echo
echo "Environment variables:"
echo " - SERVICE_REPO_URL=$SERVICE_REPO_URL"
echo " - SERVICE_REPO_TAG=$SERVICE_REPO_TAG"
echo " - SERVICE_ID=$SERVICE_ID"
echo " - GH_TOKEN=$GH_TOKEN"
echo 
echo "Steps:"

# ------------------------------------------------------------------------------
OWNER=$(echo "$SERVICE_REPO_URL" | cut -d'/' -f4)
REPO=$(echo "$SERVICE_REPO_URL" | cut -d'/' -f5)
API_URL="https://api.github.com/repos/$OWNER/$REPO"
DEPLOY_SERVICE_SCRIPT="deploy_service.sh"
SERVICE_VARIABLES_FILE="./config/service_vars.env"
SERVICE_KEYS_JSON_FILE="./config/keys.json"

# ------------------------------------------------------------------------------
echo " - Testing repository access"

if [[ -z "${GH_TOKEN// }" ]]; then
  HEADERS=(-H "Accept: application/vnd.github+json")
else
  HEADERS=(-H "Accept: application/vnd.github+json" -H "Authorization: token $GH_TOKEN")
fi

response=$(curl -s -o /dev/null -w "%{http_code}" "${HEADERS[@]}" "$API_URL")

if [ "$response" -ne 200 ]; then
  echo "Error: Access to repository \"$SERVICE_REPO_URL\" failed (response $response). Please check the access token (GH_TOKEN) and repository URL (SERVICE_REPO_URL)."
  exit 1
fi

# ------------------------------------------------------------------------------
echo " - Retrieving repository tag"

if [ -z "${SERVICE_REPO_TAG// }" ]; then
  echo "   - Repository tag undefined. Retrieving latest release tag."
  SERVICE_REPO_TAG=$(curl -sL "${HEADERS[@]}" "$API_URL/releases/latest" | jq -r ".tag_name")
fi

echo "   - Repository tag: $SERVICE_REPO_TAG"

response=$(curl -s "${HEADERS[@]}" "$API_URL/tags")

if ! echo "$response" | grep -q "\"name\": \"$SERVICE_REPO_TAG\""; then
  echo "Error: Tag \"$SERVICE_REPO_TAG\" does not exist in repository \"$SERVICE_REPO_URL\"."
  exit 1
fi

# ------------------------------------------------------------------------------
echo " - Retrieving \"packages/packages.json\""
PACKAGES_JSON=$(curl -s "${HEADERS[@]}" "https://raw.githubusercontent.com/$OWNER/$REPO/$SERVICE_REPO_TAG/packages/packages.json")

if ! echo "$PACKAGES_JSON" | jq -e . >/dev/null 2>&1; then
  echo "Error: Ivalid \"packages/packages.json\". Exiting script."
  echo "Verify that the tag \"$SERVICE_REPO_TAG\" exists in repository \"$SERVICE_REPO_URL\"."
  exit 1
fi

# ------------------------------------------------------------------------------
echo " - Retrieving service hash"
SERVICE_JSON_KEY="service/${SERVICE_ID/:/\/}"
SERVICE_HASH=$(echo "$PACKAGES_JSON" | jq -r ".dev.\"$SERVICE_JSON_KEY\"")
echo "   - Service hash: $SERVICE_HASH"

if [[ ! $SERVICE_HASH =~ ^ba[a-zA-Z0-9]{57}$ ]]; then
  echo "Error: Service hash does not match the expected pattern. Exiting script."
  echo "Verify that the key \"$SERVICE_JSON_KEY\" exists in \"packges/packages.json\" in the repository \"$SERVICE_REPO_URL\" ($SERVICE_REPO_TAG)."
  exit 1
fi

# ------------------------------------------------------------------------------
echo " - Writing contents to \"$DEPLOY_SERVICE_SCRIPT\""

if [[ -z "${VARS_CONTEXT// }" ]]; then
    echo "   - Empty VARS_CONTEXT"
    VARS_CONTEXT="{}"
fi

if [[ -z "${SECRETS_CONTEXT// }" ]]; then
    echo "   - Empty SECRETS_CONTEXT"    
    SECRETS_CONTEXT="{}"
fi

echo "   - Joining context variables into a single JSON"
SERVICE_VARIABLES_OVERRIDES=$(echo "$VARS_CONTEXT $SECRETS_CONTEXT" | jq -s add)

echo "   - Setting the contents of keys file (\"keys.json\")"
KEYS_JSON=""
if [[ $(echo "$SERVICE_VARIABLES_OVERRIDES" | jq '.KEYS_JSON') != "null" ]]; then
  echo "     - Set \"keys.json\" to context variable KEYS_JSON"
  KEYS_JSON=$(echo "$SERVICE_VARIABLES_OVERRIDES" | jq -r '.KEYS_JSON')
elif [ -f $SERVICE_KEYS_JSON_FILE ]; then
  echo "     - Set \"keys.json\" to file contents \"$SERVICE_KEYS_JSON_FILE\""
  KEYS_JSON=$(<$SERVICE_KEYS_JSON_FILE)
else
  echo "Error: \"keys.json\" not defined in context variable KEYS_JSON nor in file \"$SERVICE_KEYS_JSON_FILE\"."
  exit 1
fi

echo "echo \"Current user: \$(whoami)\"
export PATH=\"\$PATH:/home/ubuntu/.local/bin\"
echo "Environment variables:"
env
pip install requests==2.28.1
autonomy init --remote --author open_operator_aks --reset
autonomy fetch $SERVICE_HASH --service
cd \$(ls -td -- */ | head -n 1)
autonomy build-image
cat > keys.json << EOF
$KEYS_JSON
EOF" > $DEPLOY_SERVICE_SCRIPT

echo "
# Service variables" >> $DEPLOY_SERVICE_SCRIPT
parse_env_file "$SERVICE_VARIABLES_FILE" "$SERVICE_VARIABLES_OVERRIDES" "$DEPLOY_SERVICE_SCRIPT"

echo " - Writing contents to \"$DEPLOY_SERVICE_SCRIPT\""
echo "
autonomy deploy build
cd abci_build && screen -dmS service_screen_session bash -c \"autonomy deploy run\"
echo \"Service deployment finished. Use 'screen -r service_screen_session' to attach to the session running the agent.\"" >> $DEPLOY_SERVICE_SCRIPT

echo " - Changing \"$DEPLOY_SERVICE_SCRIPT\" permissions"
chmod 764 $DEPLOY_SERVICE_SCRIPT

echo 
echo "Finished generating \"$DEPLOY_SERVICE_SCRIPT\""

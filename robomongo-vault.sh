#!/usr/bin/env bash

set -o nounset
set -o errexit
set -o pipefail

export VAULT_ADDR="https://localhost:443"

readonly ZENITY='/usr/bin/zenity'
readonly VAULT_CLIENT='/usr/bin/vault'
readonly JSON_PROCESSOR='/usr/bin/jq'
readonly ROBOMONGO='/usr/bin/robo3t'
readonly ROBOMONGO_HOME="$HOME/.3T/robo-3t"
readonly ROBOMONGO_LATEST_VERSION=$(ls -v $ROBOMONGO_HOME | tail -n 1)
readonly ROBOMONGO_CONFIG_PATH="${ROBOMONGO_HOME}/${ROBOMONGO_LATEST_VERSION}"
readonly ROBOMONGO_CONFIG="${ROBOMONGO_CONFIG_PATH}/robo3t.json"
readonly ROBOMONGO_CONFIG_BACKUP="${ROBOMONGO_CONFIG_PATH}/robo3t.json.backup"

function is_empty() {
    [[ -z "${1/ //}" ]]
}

function show_error() {
    local title="${1}"
    local message="${2}"
    [[ -f "${ZENITY}" ]] && ${ZENITY} --error --title="${title}" --text "${message}" || echo -e "\e[1m${title}:\e[0m \e[91m${message}\e[0m"
}

function show_info() {
    local title="${1}";shift
    local message="${@}"
    echo -e "\e[1m${title}:\e[0m ${message}\e[0m"
}

function sanityChecks() {
    if [[ ! -f ${VAULT_CLIENT} ]]; then
        show_error "Vault" "Can't find Vault client under ${VAULT_CLIENT}"
        return 1
    fi
    if [[ ! -f ${ROBOMONGO_CONFIG} ]]; then
        show_error "Config" "Can't find Robomongo Config under ${ROBOMONGO_CONFIG}"
        return 2
    fi
    if is_empty "${VAULT_ADDR:-}"; then
        show_error "Vault" "Variable VAULT_ADDR is not set."
        return 3
    fi
    show_info "-" "\e[32mUsing ROBOMONGO_CONFIG: ${ROBOMONGO_CONFIG}"
    show_info "-" "\e[32mUsing VAULT_ADDR: ${VAULT_ADDR}"
    return 0
}

function registerCleanUpRoutine() {
    show_info "CleanUp" "Register cleanup routine"
    local original_file="${1}"
    local backup_file="${2}"
    # EXECUTE ON EXIT
    trap "[[ -f '${original_file}' ]] && [[ -f '${backup_file}' ]] && rm ${original_file}; mv ${backup_file} ${original_file}" 0
}

function ask_credentials() {
    local message='Type in your vault username and password.'
    if [[ -f "${ZENITY}" ]]; then
        echo $($ZENITY --password --username --text $message)
    else
        read -p "Username: " username;printf "\n"
        read -s -p "Password: " password;printf "\n"
        echo "${username}|${password}"
    fi
}

function vaultLoginWithLDAP() {
    show_info "-" "\e[32mLogin with LDAP"
    local user="${1}"
    local pass="${2}"
    ${VAULT_CLIENT} auth -method=ldap username=${user} password=${pass}
}

function setCredentialsInJson() {
    local json="${1}"
    local connection_name="${2}"
    local user="${3}"
    local pass="${4}"
    echo ${json} | ${JSON_PROCESSOR} -r --arg connection_name "$connection_name" --arg user "$user" \
    '(.connections[] | select(.connectionName == $connection_name) | .credentials[].userName) |= $user' | \
    ${JSON_PROCESSOR} -r --arg connection_name "$connection_name" --arg pass "$pass" \
    '(.connections[] | select(.connectionName == $connection_name) | .credentials[].userPassword) |= $pass'
}

function findEnabledConnectionNames() {
    local templateFileContent="${1}"
    echo "${templateFileContent}" | ${JSON_PROCESSOR} -r '(.connections[] | select(.credentials[].enabled == true)) | .connectionName'
}

function prepareWrapperConfig() {
    show_info "Prepare" "Check Config"
    sanityChecks
    if [[ $? != 0 ]]; then
        exit $?
    fi
}

function prepareVaultConfig() {
    show_info "Prepare" "Check Vault Credentials"
    if is_empty "${VAULT_TOKEN:-}"; then
        local user_and_pass=$(ask_credentials)
        local username=$(echo $user_and_pass | cut -f1 -d'|')
        local password=$(echo $user_and_pass | cut -f2 -d'|')
        if is_empty "${username}"  || is_empty "${password}"; then
            show_error "Credentials" "Username or password empty"
        fi
        vaultLoginWithLDAP "${username}" "${password}"
    else
        show_info "-" "\e[32mUsing VAULT_TOKEN: ${VAULT_TOKEN}"
    fi
}

function prepareRoboConfig() {
    show_info "Prepare" "Backup current Robomongo/Robo3T Config"
    local backup_name=${ROBOMONGO_CONFIG_BACKUP}
    if [[ -e "${backup_name}" ]] ; then
        echo "${backup_name} already exists."
        i=1
        while [[ -e "${backup_name}" ]] ; do
            let i++
            backup_name="${ROBOMONGO_CONFIG_BACKUP}.${i}"
            if [[ ${i} > 5 ]];then
                show_error "Backup Config" "Too many Backups found in ${ROBOMONGO_CONFIG_PATH}"
                exit 1
            fi
        done
    fi
    cp "${ROBOMONGO_CONFIG}" "${backup_name}" && \
    rm "${ROBOMONGO_CONFIG}" && \
    registerCleanUpRoutine "${ROBOMONGO_CONFIG}" "${backup_name}"
}

function retrieveCredentials() {
    local templateFilepath="$(ls -d -1 -v ${ROBOMONGO_CONFIG_PATH}/*.* | tail -n 1)"
    local templateFileContent="$(cat ${templateFilepath})"
    local configWithCredentials="${templateFileContent}"
    show_info "Vault" "Retrieve credentials for all enabled Connection Names (${templateFilepath})"

    findEnabledConnectionNames "${templateFileContent}" | while read connectionName ; do
        show_info "-" "Retrieve credentials for ${connectionName}"
        echo "todo: retrieve credentials here"
        configWithCredentials=$(setCredentialsInJson "${configWithCredentials}" "${connectionName}" "ed" "schleck")
    done
    echo "todo: save configWithCredentials as new config"
}

function startRobo() {
    echo "todo: start robo3t here"
    echo "todo: remove config with passwords in background after some sleep time"
}

function main() {
    prepareWrapperConfig
    prepareVaultConfig
    prepareRoboConfig
    retrieveCredentials
    startRobo
};main
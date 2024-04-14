#!/bin/bash

# The arguments
HOST_NAME=$1
HOST_IP=$2
SSH_USER=$3
IDENTITY_FILE_PATH=$4
CONFIG_FILE_PATH=$5
IS_BASTION=$6

# Function to add or update a host configuration in the SSH config file
add_or_update_host() {
    local name=$1
    local ip=$2
    local user=$3
    local key_path=$4
    local cfg_path=$5
    local is_bastion=$6

    # Detect the operating system
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SED_I_OPTION=(-i '')
    else
        SED_I_OPTION=(-i)
    fi

    # Remove existing entry if it exists
    sed "${SED_I_OPTION[@]}" "/^Host ${name}\$/,/^$/d" "${cfg_path}"

    # Add new entry for Bastion
    if [[ "${is_bastion}" == "true" ]]; then
        cat >> "${cfg_path}" <<EOL
Host *
    ServerAliveInterval 60
    ServerAliveCountMax 120

Host ${name}
  HostName ${ip}
  User ${user}
  IdentityFile ${key_path}

EOL
    # Add new entry with port forwarding for gophish
    elif [[ "${name}" == "gophish" ]]; then
        cat >> "${cfg_path}" <<EOL
Host ${name}
  HostName ${ip}
  User ${user}
  IdentityFile ${key_path}
  ProxyJump bastion
  LocalForward 3333 ${ip}:3333

EOL

    # Add new entry with port forwarding for redelk
    elif [[ "${name}" == "redelk" ]]; then
        cat >> "${cfg_path}" <<EOL
Host ${name}
  HostName ${ip}
  User ${user}
  IdentityFile ${key_path}
  ProxyJump bastion
  LocalForward 4430 ${ip}:443

EOL

    # Add new entry for other hosts
    else
        cat >> "${cfg_path}" <<EOL
Host ${name}
  HostName ${ip}
  User ${user}
  IdentityFile ${key_path}
  ProxyJump bastion

EOL
    fi
}

# Call the function with the provided arguments
add_or_update_host "${HOST_NAME}" "${HOST_IP}" "${SSH_USER}" "${IDENTITY_FILE_PATH}" "${CONFIG_FILE_PATH}" "${IS_BASTION}"

#!/bin/bash

# Configuration
SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/id_rsa"
NODES=("node-01" "node-02" "node-03" "node-04")
DEFAULT_USER="rancher"
DEFAULT_PASS="rancher"
NEW_USER="evertonagilar"

# Create SSH directory if it doesn't exist
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate SSH key if it doesn't exist
if [ ! -f "$KEY_FILE" ]; then
    echo "Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f "$KEY_FILE" -N ""
fi

# Function to setup nodes
for node in "${NODES[@]}"; do
    echo "----------------------------------------"
    echo "Processing $node..."
    
    # 1. Clean and scan host keys
    ssh-keygen -f "$SSH_DIR/known_hosts" -R "$node" &> /dev/null
    ssh-keyscan -H "$node" >> "$SSH_DIR/known_hosts" 2>/dev/null
    
    # 2. Distribute key to rancher user
    echo "Distributing SSH key to $DEFAULT_USER@$node..."
    SSHPASS="$DEFAULT_PASS" sshpass -e ssh-copy-id -o StrictHostKeyChecking=no "$DEFAULT_USER@$node"
    
    # 3. Distribute key to evertonagilar user
    echo "Distributing SSH key to $NEW_USER@$node..."
    SSHPASS="$DEFAULT_PASS" sshpass -e ssh-copy-id -o StrictHostKeyChecking=no "$NEW_USER@$node"
    
    echo "Finished $node."
done


echo "----------------------------------------"
echo "SSH Setup and user creation completed."
echo "You can now login with: ssh $NEW_USER@node-01 (or any other node)"


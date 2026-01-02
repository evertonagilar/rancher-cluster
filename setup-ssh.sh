#!/bin/bash

# Configuration
SSH_DIR="$HOME/.ssh"
KEY_FILE="$SSH_DIR/id_rsa"
NODES=("node-01" "node-02" "node-03" "node-04")
USER="rancher"
PASS="rancher"

# Create SSH directory if it doesn't exist
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate SSH key if it doesn't exist
if [ ! -f "$KEY_FILE" ]; then
    echo "Generating SSH key..."
    ssh-keygen -t rsa -b 4096 -f "$KEY_FILE" -N ""
fi

# Function to copy ID using sshpass (likely needed if not using keys yet)
# Note: sshpass might need to be installed in the control container
for node in "${NODES[@]}"; do
    echo "Distributing key to $node..."
    # We use -o StrictHostKeyChecking=no to avoid prompts
    ssh-keyscan -H "$node" >> "$SSH_DIR/known_hosts"
    
    # Try to copy ID. This assumes sshpass is available or manual password entry if not.
    # For a smoother experience, we can suggest the user runs this inside the control container.
    ssh-keygen -f "$SSH_DIR/known_hosts" -R "$node" &> /dev/null
    ssh-keyscan -H "$node" >> "$SSH_DIR/known_hosts"
    
    echo "Tip: Run 'ssh-copy-id $USER@$node' and use password '$PASS'"
done

echo "SSH Setup script completed."

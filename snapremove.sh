#!/bin/bash

# Check if pvesh is available
if ! command -v pvesh &>/dev/null; then
  echo "Error: 'pvesh' command is not available. Please ensure this script is run on a Proxmox server."
  exit 1
fi

# Get the current time in seconds since the Unix epoch
CURRENT_TIME=$(date +%s)

# Set the age limit for snapshots in seconds (3 days = 3 * 24 * 3600)
AGE_LIMIT=$((3 * 24 * 3600))

echo "Fetching all VMs from the Proxmox cluster..."

# Get all VM information from the cluster resources
VM_LIST=$(pvesh get /cluster/resources --type vm --output-format json)

if [[ -z "$VM_LIST" ]]; then
  echo "No VMs found in the cluster."
  exit 0
fi

# Parse the VM list
VM_DATA=$(echo "$VM_LIST" | jq -r '.[] | "\(.vmid)\t\(.node)"')

echo -e "VMID\tNode"
echo "--------------------"
echo "$VM_DATA"

# Iterate through each VM
while IFS=$'\t' read -r VMID NODE; do
  echo "Processing VMID $VMID on node $NODE..."

  # Get snapshots for the VM
  SNAPSHOTS=$(pvesh get /nodes/$NODE/qemu/$VMID/snapshot --output-format json)

  if [[ -z "$SNAPSHOTS" ]]; then
    echo "No snapshots found for VMID $VMID on node $NODE."
    continue
  fi

  # Iterate through each snapshot
  echo "$SNAPSHOTS" | jq -c '.[] | select(.snaptime != null)' | while read -r SNAP; do
    SNAP_NAME=$(echo "$SNAP" | jq -r '.name')
    SNAP_TIME=$(echo "$SNAP" | jq -r '.snaptime')

    # Calculate the snapshot's age
    SNAP_AGE=$((CURRENT_TIME - SNAP_TIME))

    if ((SNAP_AGE > AGE_LIMIT)); then
      echo "Deleting snapshot '$SNAP_NAME' (age: $((SNAP_AGE / 86400)) days) for VMID $VMID on node $NODE..."
      pvesh delete /nodes/$NODE/qemu/$VMID/snapshot/$SNAP_NAME
      if [[ $? -eq 0 ]]; then
        echo "Snapshot '$SNAP_NAME' deleted successfully."
      else
        echo "Failed to delete snapshot '$SNAP_NAME'."
      fi
    else
      echo "Skipping snapshot '$SNAP_NAME' (age: $((SNAP_AGE / 86400)) days)."
    fi
  done

done <<< "$VM_DATA"

echo "Snapshot cleanup completed."

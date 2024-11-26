Snapshot Cleanup Script (snapremove.sh)
=======================================

This script removes snapshots older than 3 days for all virtual machines (VMs) across all nodes in a Proxmox cluster. It automates snapshot management to save storage space and keep your Proxmox environment tidy.

Requirements
------------
- Proxmox Cluster: Ensure the script is run on a Proxmox node.
- Tools:
  - `pvesh` (Proxmox API CLI) must be available.
  - `jq` (JSON parser) must be installed. Install it using:
    apt update && apt install -y jq

Installation
------------
1. Download the Script:
   Save the script as `snapremove.sh` on a Proxmox node.

   Example:
   nano /usr/local/bin/snapremove.sh
   # Paste the script content and save
   chmod +x /usr/local/bin/snapremove.sh

2. Verify Functionality:
   Run the script manually to verify:
   /usr/local/bin/snapremove.sh

3. Automate with Crontab:
   Add the script to the `cron` scheduler for automatic daily execution.

   Edit the crontab file:
   crontab -e

   Add the following line to run the script daily at 2 AM:
   0 2 * * * /usr/local/bin/snapremove.sh >> /var/log/snapremove.log 2>&1

   - This will log output to `/var/log/snapremove.log`.

Notes
-----
- Only snapshots older than 3 days are removed.
- Ensure the script is tested in your environment before adding it to `cron`.
- You can adjust the age threshold by modifying the `AGE_LIMIT` variable in the script:
  AGE_LIMIT=$((N * 24 * 3600)) # Replace N with the desired number of days

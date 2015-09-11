# serverdensitysynology
Install script for the Server Density agent on Synologys.

This script will install the Server Density agent on to a Synology, including asking for some basic variables to get it running and putting an entry into /etc/crontab to keep it running.
If you are doing deployments onto multiple Synologys and are using your own customised config.cfg file and/or checks.py file, this script has entries near the top to allow you to pre-define these to help speed up these deployments.

Installation instructions:

1. SSH into the Synology as root. You'll need to enable SSH access via the DSM Control Panel first. You'll need root access for this - the password will be the same as with your primary/original administrator user (usually "admin").
2. Copy the script to a location on the Synology via DSM, or if you have a URL to download it from you can use curl.
3. Navigate to the same folder as the script and make the script executable with chmod +x serverdensitysynoinstall.sh
4. Run the script with ./serverdensitysynoinstall.sh and follow the instructions.

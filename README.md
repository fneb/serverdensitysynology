# serverdensitysynology
Install script for the Server Density agent on Synologys.

This script will install the Server Density agent on to a Synology, including asking for some basic variables to get it running and putting an entry into /etc/crontab to keep it running.
If you are doing deployments onto multiple Synologys and are using your own customised config.cfg file and/or checks.py file, this script has entries near the top to allow you to pre-define these to help speed up these deployments.

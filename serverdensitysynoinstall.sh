#!/bin/ash

# Installer for Server Density on Synologys, by Bethany Corcoran. 
# This script will prompt for a path to install to, download the latest Server Density agent for Linux, extract it, and perform some basic setup (potentially from pre-made files that it will download).
# Released under the GNU General Public License, 2015. This script is provided with NO warranty whatsoever.

# You'll notice that applications in this all have their absolute path. This is to work around issues with applications no longer being usable once the script is in progress.

# If you want to pre-define your URLs for your pre-made checks.py and config.cfg, uncomment these lines and put the full URL here. Handy for large-scale roll-outs for many devices.

# CHECKSURL=""
# CONFIGURL=""

# If you are using a pre-defined config.cfg from a URL, then you probably want to skip asking for a sd_url value in config.cfg. If so, uncomment the below line to skip this prompt.

# SKIPSDURL="true"

# Now we start asking the user for variables. Firstly, where to install to with /etc as the default.

/bin/echo "Synology-specific installer for Server Density."
/bin/echo "Where should Server Density be installed to? Use the absolute path with no trailing slash. [/etc]"
read PATH
if [ -z "$PATH" ]
then
  PATH="/etc"
  /bin/echo "Using $PATH as install location."
else
  /bin/echo "Using $PATH as install location. Please ensure this is valid - this script doesn't include any checks for this!"
fi

# Asks for a URL to grab a pre-customised config.cfg from, unless it has been defined above.

if [ -z "$CONFIGURL" ]
then
  /bin/echo "Enter URL for your pre-customised config.cfg file. Leave blank to work from the default config file."
  read CONFIGURL
fi
if [ -z "$CONFIGURL" ]
then
  /bin/echo "Using default config file."
else
  /bin/echo "Using config from $CONFIGURL. You'll find the default file in $PATH/sd-agent/replaced-files after the installation."
fi

# Asks for a URL to grab a pre-customised checks.py from, unless it has been defined above.

if [ -z "$CHECKSURL" ]
then
  /bin/echo "Enter URL for your pre-customised checks.py. Leave blank to work from the default checks.py file."
  read CHECKSURL
fi
if [ -z "$CHECKSURL" ]
then
  /bin/echo "Using default checks.py file."
else
  /bin/echo "Using checks.py from $CHECKSURL. You'll find the default file in $PATH/sd-agent/replaced-files after the installation."
fi


# Asks for the Server Density URL to use, unless this has been set to skip earlier.

if [ -z "$SKIPSDURL" ]
then
  /bin/echo "Please enter the account-specific section of the Server Density URL you use to log in. So, for the default URL https://example.serverdensity.io this would be 'example'"
  read SDURL
  if [ -z "$SDURL" ]
  then
    /bin/echo "Server Density URL cannot be blank. Please edit $PATH/sd-agent/config.cfg after the installation is complete."
  else
    /bin/echo "Using $SDURL, so the full URL will be https://$SDURL.serverdensity.io - if this is incorrect, please edit $PATH/sd-agent/config.cfg after the installation is complete."
  fi
else
  /bin/echo "You've said you want to skip entering the Server Density URL in this script itself. You can change this after installation if needed by editing the $PATH/sd-agent/config.cfg file."
fi

# Asks for the Server Density agent key.

/bin/echo "Please enter the agent key for this device - you can get this from the overview screen when you're looking at the device in Server Density, in the top-left of the screen."
/bin/echo "Note that if you're using a pre-customised config.cfg which includes a set agent_key then leave this blank."
read AGENTKEY
if [ -z "$AGENTKEY" ]
then
  /bin/echo "Agent key cannot be blank. Please edit $PATH/sd-agent/config.cfg after the installation is complete if this isn't pre-defined."
else
  /bin/echo "Using $AGENTKEY - if this is incorrect, please edit $PATH/sd-agent/config.cfg after the installation is complete."
fi
# Now that we have our variables, it's time to download and extract Server Density's agent. We download to /tmp then extract the contents to the directory we want it to be installed to.

/usr/bin/curl -L "https://www.serverdensity.com/downloads/sd-agent.tar.gz" -o "/tmp/sd-agent.tar.gz"
/bin/gzip -dc "/tmp/sd-agent.tar.gz" | /bin/tar xf - -C "$PATH"

# Check if we have a URL set for either the checks.py or config.cfg files. If either is set, then makes a folder for the originals to be put into.

if [[ -z "$CHECKSURL" && -z "$CONFIGURL" ]]
then
/bin/sleep 0
else
  /bin/mkdir "$PATH/sd-agent/replaced-files"
fi

# If there's a URL for the checks.py then moves the original out of the default location and downloads the pre-customised version in its place.

if [ -n "$CHECKSURL" ]
then
  /bin/mv "$PATH/sd-agent/checks.py" "$PATH/sd-agent/replaced-files/checks.py"
  /usr/bin/curl -L "$CHECKSURL" -o "$PATH/sd-agent/checks.py"
fi

# If there's a URL for the config.cfg then moves the original out of the default location and downloads the pre-customised version in its place.

if [ -n "$CONFIGURL" ]
then
  /bin/mv "$PATH/sd-agent/config.cfg" "$PATH/sd-agent/replaced-files/config.cfg"
  /usr/bin/curl -L "$CONFIGURL" -o "$PATH/sd-agent/config.cfg"
fi

# Edits the config file with our agent key, but only if the AGENTKEY variable has been set.

if [ -n "$AGENTKEY" ]
then
  /bin/sed -i "s/agent_key:/agent_key: $AGENTKEY/g" "$PATH/sd-agent/config.cfg"
fi

# Edits the config file with our SD URL, but only if the SDURL variable has been set.

if [ -n "$SDURL" ]
then
  /bin/sed -i "s/sd_url: https:\/\/example.serverdensity.io/sd_url: https:\/\/$SDURL.serverdensity.io/g" "$PATH/sd-agent/config.cfg"
fi

# Now we want to write the script agent-pid.sh. This is what we're going to use for launching Server Density.
/bin/echo "Writing agent-pid.sh file."
/bin/sleep 1
/bin/echo "#!/bin/ash" >> $PATH/sd-agent/agent-pid.sh
/bin/echo 'PIDFILE="/tmp/sd-agent.pid"' >> $PATH/sd-agent/agent-pid.sh
/bin/echo 'if [ -e "$PIDFILE" ]' >> $PATH/sd-agent/agent-pid.sh
/bin/echo "then" >> $PATH/sd-agent/agent-pid.sh
/bin/echo "exit" >> $PATH/sd-agent/agent-pid.sh
/bin/echo "else" >> $PATH/sd-agent/agent-pid.sh
/bin/echo 'python $PATH/sd-agent/agent.py start' >> $PATH/sd-agent/agent-pid.sh
/bin/echo "fi" >> $PATH/sd-agent/agent-pid.sh
/bin/sleep 1
/bin/chmod +x "$PATH/sd-agent/agent-pid.sh"
/bin/echo "Adding Server Density to /etc/crontab. It'll check if it needs to be re-launched every hour."
/bin/echo "0       *       *       *       *       root    $PATH/sd-agent/agent-pid.sh" >> /etc/crontab
/bin/echo "Would you like to run Server Density now? y/n [y]"
read LAUNCH
if [ -z "$LAUNCH" ]
then
  LAUNCH="y"
fi
if [ "$LAUNCH" == "y" ]
then
  $PATH/sd-agent/agent-pid.sh
fi
if [ "$LAUNCH" == "n" ]
then
  /bin/echo "Run $PATH/sd-agent/agent-pid.sh when ready."
fi
if [[ "$LAUNCH" != "y" && "$LAUNCH" != "n" ]]
then
  /bin/echo "Oops, you've entered something other than y or n, so we won't run it now. Run $PATH/sd-agent/agent-pid.sh when ready."
fi
/bin/echo "Server Density should now be installed!"
exit

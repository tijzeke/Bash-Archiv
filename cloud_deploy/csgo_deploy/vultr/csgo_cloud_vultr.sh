#!/bin/bash

## Vultr Cloud CSGO Server Deploy INST
## 2018-01-24


############################################## Start of Script ##############################################
function check_root ()
{
 if [ ! $(whoami) == "root" ]; then
        echo "Start as root an try again"
        exit 1
fi
}

function check_distro ()
{
    if [ -x /usr/bin/lsb_release ]; then
        if [ !$LSB == "Ubuntu" ] || [ !$LSB == "Debian" ]; then
          echo "Your distro isn´t supported"
         exit 1
        fi
    else
        echo "Your distro isn´t supported."
        exit 1
    fi
}

function inst_req ()
{
    # System Update
apt update && apt upgrade -y
    # Install Req via APT
apt install -y curl debconf libc6 lib32gcc1
    # Create User
    if [ ! -d $server_inst_dir ]; then
        mkdir $server_inst_dir
    fi
    if [[ ! $(getent passwd $install_user_name) = *"$install_user_name"* ]]; then
        useradd $install_user_name -d $server_inst_dir --shell /usr/sbin/nologin
    fi
    # Download SteamCMD
 if [ -d $steamCMD ]; then
         curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C $steamCMD >/dev/null 2>&1
    else
        mkdir $steamCMD
        curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf - -C $steamCMD >/dev/null 2>&1
 fi
    # Set User rights
    chown -cR $install_user_name $steamCMD && chmod -cR 770 $install_user_name $steamCMD
    # Clean up
apt-get autoclean

}

function inst_vanilla_cs_srv ()
{
    tmp_dir="$(su $install_user_name --shell /bin/sh -c "mktemp -d")"
    # Download CSGO Server
    echo "### DOWNLOADING CSGO Server ###"
    su $install_user_name --shell /bin/sh -c "$steamCMD/steamcmd.sh +@sSteamCmdForcePlatformType linux +login anonymous +force_install_dir $tmp_dir/ +app_update 740 validate +quit" > $tmp_dir/log
    # Check install status
    if [[ $(cat $tmp_dir/log) = *"Success! App '740' fully installed."* ]] ; then
        echo "CSGO Download success"
    else
        rm -rf $tmp_dir
        echo "CSGO Download failed retry..."
         COUNTER=$((COUNTER +1))
             if [ $retry == $COUNTER ]; then
               echo "CSGO Download failed after $retry attempts exiting..."
            exit 1
             fi 
       inst_vanilla_cs_srv
    fi
    # Move Folder
    mv $tmp_dir/* $server_inst_dir
    # Clean up
    rm -rf $tmp_dir
}

function csgo_srv_init ()
{
# Inst Metamod & Sourcemod
# Metamod
echo "### INST Metamod ###"
curl -sqL $metamod | tar zxvf - -C $server_inst_dir/csgo/
# Sourcemod
echo "### INST Sourcemod ###"
curl -sqL $sourcemod | tar zxvf - -C $server_inst_dir/csgo/
# Update Config
# Create Server CFG
echo "### UPDATE Server CFG ###"
if [ -a $server_inst_dir/csgo/cfg/server.cfg ]; then
    rm $server_inst_dir/csgo/cfg/server.cfg
fi
echo // Base Configuration >> $server_inst_dir/csgo/cfg/server.cfg
echo hostname $hostname >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_password $sv_password >> $server_inst_dir/csgo/cfg/server.cfg
echo rcon_password "$rcon_password" >> $server_inst_dir/csgo/cfg/server.cfg
echo  >> $server_inst_dir/csgo/cfg/server.cfg
echo // Network Configuration >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_loadingurl "https://aimb0t.husos.wtf" >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_downloadurl '"http://fastdl.omg-network.de/csgo/csgo/"' >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_allowdownload 0 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_allowupload 0 >> $server_inst_dir/csgo/cfg/server.cfg
echo net_maxfilesize 64 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_setsteamaccount $sv_setsteamaccount >> $server_inst_dir/csgo/cfg/server.cfg
echo  >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_maxrate 0 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_minrate 196608 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_maxcmdrate 128 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_mincmdrate 128 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_maxupdaterate 128 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_minupdaterate 128 >> $server_inst_dir/csgo/cfg/server.cfg
echo  >> $server_inst_dir/csgo/cfg/server.cfg
echo // Logging Configuration >> $server_inst_dir/csgo/cfg/server.cfg
echo log on >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_logbans 0 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_logecho 0 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_logfile 1 >> $server_inst_dir/csgo/cfg/server.cfg
echo sv_log_onefile 0 >> $server_inst_dir/csgo/cfg/server.cfg
echo  >> $server_inst_dir/csgo/cfg/server.cfg
echo mp_match_end_restart 1 >> $server_inst_dir/csgo/cfg/server.cfg

# Add ESL Config files
echo "### ADD ESL Config ###"
curl -sqL $esl_cfg | tar xf - -C $server_inst_dir/csgo/cfg/
}

function csgo_1vs1 ()
{
# Download Maps
echo "### DOWNLOADING CSGO Maps ###"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_redline.bsp"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_dust2.bsp"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_map_classic.bsp"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_dust_go.bsp"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_map.bsp"
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_prac_ak47.bsp"
# Set permissions
echo "### SET Permissions for $install_user_name"
chown -cR $install_user_name $server_inst_dir && chmod -cR 770 $server_inst_dir
chmod +x $server_inst_dir/srcds_run
# Starting CSGO Server
echo "### STARTING CSGO Server ###"
screen -dmS CS_1vs1 su $install_user_name --shell /bin/sh -c "$server_inst_dir/srcds_run -game csgo -console -autoupdate -usercon -tickrate 128 -maxplayers 10 -nobots -pingboost 3 +game_type 0 +game_mode 0 +map aim_redline +exec server.cfg"
}

function csgo_diegel ()
{
# Downloading aim_deagle7k
wget -P $server_inst_dir/csgo/maps "http://fastdl.omg-network.de/csgo/csgo/maps/aim_deagle7k.bsp"
# Downloading only HS Plugin
wget -P $server_inst_dir/csgo/addons/sourcemod/plugins "https://raw.githubusercontent.com/Bara/OnlyHS/master/addons/sourcemod/plugins/onlyhs.smx"
# Set permissions
echo "### SET Permissions for $install_user_name"
chown -cR $install_user_name $server_inst_dir && chmod -cR 770 $server_inst_dir
chmod +x $server_inst_dir/srcds_run
# Starting CSGO Server
echo "### STARTING CSGO Server ###"
screen -dmS CS_Diegle su $install_user_name --shell /bin/sh -c "$server_inst_dir/srcds_run -game csgo -console -autoupdate -usercon -tickrate 128 -maxplayers 10 -nobots -pingboost 3 +game_type 0 +game_mode 1 +map aim_deagle7k +exec server.cfg"

}

function csgo_mm ()
{
# Set permissions
echo "### SET Permissions for $install_user_name"
chown -cR $install_user_name $server_inst_dir && chmod -cR 770 $server_inst_dir
chmod +x $server_inst_dir/srcds_run
# Starting CSGO Server
echo "### STARTING CSGO Server ###"
screen -dmS CS_MM su $install_user_name --shell /bin/sh -c "$server_inst_dir/srcds_run -game csgo -console -autoupdate -usercon -tickrate 128 -maxplayers 10 -nobots -pingboost 3 +game_type 0 +game_mode 1 +map de_cbble +exec server.cfg"
}
############################################## End of Functions ##############################################

# Main Starts here....
# Call Functions
check_root
check_distro
inst_req
inst_vanilla_cs_srv
csgo_srv_init

case "$GAME_TYPE" in
    1vs1)
     csgo_1vs1
    ;;

    Diegel)
     csgo_diegel
    ;;

    MM)
     csgo_mm
    ;;

    *)
     echo "ERROR: Wrong GAME_TYPE exiting..."
    exit 1
esac


exit 0
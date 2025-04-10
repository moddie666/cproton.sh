#!/usr/bin/env bash
#
# https://github.com/moddie666/cproton.sh
#
baseuri="https://github.com/GloriousEggroll/proton-ge-custom/releases/download"
latesturi="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases/latest"
releaseuri="https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"
parameter="${1}"
installComplete=false;
restartSteam=2
autoInstall=false

#### Set restartSteam=0 to not restart steam after installing Proton (Keep process untouched)
#### Set restartSteam=1 to autorestart steam after installing Proton
#### Set restartSteam=2 to to get a y/n prompt asking if you want to restart Steam after each installation.

#### Set autoInstall=true to skip the installation prompt and install the latest not-installed, or any forced Proton GE builds
#### Set autoInstall=false to display a installation-confirmation prompt when installing a Proton GE build

# ########################################## CProton - Custom Proton Installscript 0.2.1 ##########################################
# Disclaimer: Subversions like the MCC versions of Proton 4.21-GE-1, will install as it's main version and not install separately.
# For now, this may result in false "not installed"-detections or errors while force installing a specific subversion.
PrintUsage(){
  echo "----------------USAGE---------------"
  echo "Run './cproton.sh [VersionName]'    "
  echo "to download specific versions.      "
  echo " -c ... install most current release"
  echo " -l ... list releases @github       "
  echo " -i ... list installed releases     "
  echo " -h ... print this help text        "
  echo "------------------------------------"
}
FindCompatDir(){
dstpath=~/.steam/debian-installation/compatibilitytools.d #### Destinationforlder of the Proton installations
while [ ! -d "$dstpath" ]
do echo "[$dstpath is not a directory]"
   read -p "Enter path to steams compatibilitytools.d:" dstpath
done
}
GetReleases(){
releaseurls=$(curl -s $releaseuri | grep -E "browser_download_url.*Proton.*tar.gz")
  if [ "x$releaseurls" = "x" ]
  then echo "failed to fetch releases: [$releaseurls]"
       exit 1
  fi
}
PrintReleases() {
  echo "------------Releases------------ "
  echo "$releaseuri" #https://api.github.com/repos/GloriousEggroll/proton-ge-custom/releases"
  releases=$(sed -r 's#^.*/download/([^/]+)/.*$#\1#g' <<< "$releaseurls")
  for r in $releases
  do echo "$r [$(grep "/$r/" <<< "$releaseurls" | awk -F '"' '{print $4}')]"
  done
#  curl -s "$releaseuri" | grep -H "tag_name" | cut -d \" -f4
  echo "-------------------------------- "
}

InstallProtonGE() {
  echo "$url"
  rsp="$(curl -sI "$url" | head -1)"
  echo "$rsp" | grep -q 302 || {
    echo "$rsp"
    exit 1
  }

  [ -d "$dstpath" ] || {
    mkdir "$dstpath"
    echo [Info] Created "$dstpath"
  }
  echo "$url"
  curl -L "$url" | tar xfzv - -C "$dstpath"
  installComplete=true
}

RestartSteam() {
  if [ "$( pgrep steam )" != "" ]; then
    echo "Restarting Steam"
    pkill -TERM steam #restarting Steam
    sleep 5s
    nohup steam </dev/null &>/dev/null &
  fi
}

RestartSteamCheck() {
  if [ "$( pgrep steam )" != "" ] && [ "$installComplete" = true ]; then
    if [ $restartSteam == 2 ]; then
      read -r -p "Do you want to restart Steam? <y/N> " prompt
      if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
        RestartSteam
      else
        exit 2
      fi
    elif [ $restartSteam == 0 ]; then
      exit 0
    fi
    RestartSteam
  fi
}

PrintInstalled() {
echo "$dstpath"
ls -la "$dstpath"/
}

InstallationPrompt() {
  if [ "$autoInstall" = true ]; then
    if [ ! -d "$dstpath"/Proton-"$version" ]; then
      InstallProtonGE
    fi
  else
    read -r -p "Do you want to try to download and (re)install this release? <y/N> " prompt
    if [[ $prompt == "y" || $prompt == "Y" || $prompt == "yes" || $prompt == "Yes" ]]; then
      InstallProtonGE
    else
      echo "Operation canceled"
      exit 0
    fi
  fi
}

if [ -z "$parameter" ]; then
  PrintUsage
  exit 0
elif [ "$parameter" == "-l" ]; then
  GetReleases
  PrintReleases
elif [ "$parameter" == "-i" ]; then
  FindCompatDir
  PrintInstalled
  exit 0
elif [ "$parameter" == "-h" ]; then
  PrintUsage
  exit 0
elif [ "$parameter" == "-c" ]; then
  FindCompatDir
  version="$(curl -s $latesturi | grep -E -m1 "tag_name" | cut -d \" -f4)"
  url=$(curl -s $latesturi | grep -E -m1 "browser_download_url.*Proton.*tar.gz" | cut -d \" -f4)
  if [ -d "$dstpath"/"$version" ]; then
    echo "Proton $version is the latest version and is already installed."
  else
    echo "Proton $version is the latest version and is not installed yet."
  fi
  echo "GET: [$url]"
  InstallationPrompt
  RestartSteamCheck
  exit 0
else
  GetReleases
  FindCompatDir
  url=$(grep "/$parameter/" <<< "$releaseurls" | awk -F '"' '{print $4}')
  if [ -z $url ]
  then echo "no Proton release matches '$parameter'"
       PrintReleases
       exit 1
  fi
  #$baseuri/"$parameter"/Proton-"$parameter".tar.gz
  if [ -d "$dstpath"/"$parameter" ]; then
    echo "Proton $parameter is already installed."
  else
    echo "Proton $parameter is not installed yet."
    echo "GET: [$url]"
    InstallationPrompt
    RestartSteamCheck

  fi
fi

#releaseurls=$(curl -s $releaseuri | grep -E "browser_download_url.*Proton.*tar.gz")
#echo "$releaseurls" | sed -r 's#^.*/download/([^/]+)/.*$#\1#g'

#if [ ! "$parameter" == "-l" ] && [ ! "$parameter" == "-i" ]; then
#  echo "GET: [$url]"
#  InstallationPrompt
#  RestartSteamCheck
#fi


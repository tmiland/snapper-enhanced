#!/usr/bin/env bash


## Author: Tommy Miland (@tmiland) - Copyright (c) 2025


######################################################################
####                   Snapper Enchanced.sh                       ####
####    Enhancement that will add last package manager command    ####
####         as the description of the pre/post snapshot.         ####
####                   Maintained by @tmiland                     ####
######################################################################

VERSION='1.0.2'

#------------------------------------------------------------------------------#
#
# MIT License
#
# Copyright (c) 2025 Tommy Miland
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#------------------------------------------------------------------------------#
# Set default snapshot description if above command fails
SNAPPER_DESCRIPTION=${SNAPPER_DESCRIPTION:-"{SNAPPER_DESCRIPTION:-{snapper-enhanced} {created $1 apt command}"}
snapper_apt_enhanced_tmp=/var/tmp/snapper-enhanced

# ANSI Colors
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
RESET='\033[0m'    # Reset color

# Print an error message and exit (Red)
error() {
  printf "${RED}ERROR: %s${RESET}\n" "$*" >&2
  exit 1
}

# Print a log message (Green)
ok() {
  printf "${GREEN}%s${RESET}\n" "$*"
}

warn() {
  printf "${YELLOW}%s${RESET}\n" "$*"
}

# Borrowed from https://github.com/wmutschl/timeshift-autosnap-apt
[ "$(findmnt / -no fstype)" == "overlay" ] && { ok "==> skipping snapper-enhanced because system is booted in Live CD mode..."; exit 0; }

[[ -v DISABLE_APT_SNAPSHOT ]] && { ok "==> skipping snapper-enhanced due DISABLE_APT_SNAPSHOT environment variable being set."; exit 0; }

readonly CONF_FILE=/etc/snapper-enhanced.conf

get_property() {
  if [ ! -f $CONF_FILE ]; then
    warn "$CONF_FILE not found! Using $1=$3" >&2;
    param_value=$3
  else
    param_value=$(sed '/^\#/d' $CONF_FILE | grep "\b$1\b" |\
      cut -d "=" -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ "$2" == "boolean" ]] && [[ "$param_value" != true ]] && [[ "$param_value" != false ]] || \
      [[ "$2" == "integer" ]] && [[ ! "$param_value" =~ ^[-+]?([1-9][[:digit:]]*|1)$ ]] || \
      [[ "$2" == "string" ]] && [[ "$param_value" == "" ]]; then
      echo -e "Paramater empty in $CONF_FILE.\nUsing $1=$3" >&2
      param_value=$3
    fi
  fi
  echo $param_value
}

# updateGrub defines if grub entries should be auto-generated.
# If grub-btrfs package is not installed grub won't be generated.
# Default value is true.
update_grub() {
if eval "$(get_property "updateGrub" "boolean" "false")" && [[ -d /etc/default/grub-btrfs ]]; then
  grub-mkconfig -o /boot/grub/grub.cfg || error "Something went wrong updating grub."
fi
}

if eval "$(get_property "skipSnapper" "boolean" "false")"
then
  warn "==> skipping snapper-enhanced due to skipSnapper in $CONF_FILE set to TRUE." >&2; exit 0;
fi

# https://gist.github.com/imthenachoman/f722f6d08dfb404fed2a3b2d83263118
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=770938
# this script is an enhancement of https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=770938
# we need to work up the process tree to find the apt command that triggered the call to this script
# get the initial PID
PID=$$
# find the apt command by working up the process tree
# loop until
# - PID is empty
# - PID is 1
# - or PID command is apt
while [[ -n "$PID" && "$PID" != "1" && "$(ps -ho comm "${PID}")" != "apt" ]] ; do
  # the current PID is not the apt command so go up one by getting the parent PID of hte current PID
  PID=$(ps -ho ppid "$PID" | xargs)
done
# assuming we found the apt command, get the full args
if [[ "$(ps -ho comm "${PID}")" = "apt" ]] ; then
  LAST_CMD="$(ps -ho args "${PID}")"
fi
# If command is empty
if [ -z "$LAST_CMD" ]; then
  LAST_CMD="apt"
fi
# Limit output length
LAST_CMD="${LAST_CMD:0:35}"

# Set snapshot description
SNAPPER_DESCRIPTION="{snapper-enhanced} {created $1 command: $LAST_CMD}"
# main event
# source /etc/default/snapper if it exists
if [ -e /etc/default/snapper ] ; then
  . /etc/default/snapper
fi

# Disable snapper snapshots
if grep "DISABLE_APT_SNAPSHOT=\"no\"" /etc/default/snapper
then
  warn "DISABLE_APT_SNAPSHOT is set to no, disabling apt snapshot for snapper."
  sed -i "s|DISABLE_APT_SNAPSHOT=.*|DISABLE_APT_SNAPSHOT=\"yes\"|g" /etc/default/snapper ||
  error "Unable to disable snapper snapshots for apt."
fi

# what action are we taking
# pre, so take a pre snapshot
# if snapper snapshots are not being disabled using the skipSnapperPre config option
if eval "$(get_property "skipSnapperPre" "boolean" "false")"
then
  warn "==> skipping snapper pre due to skipSnapperPre in $CONF_FILE set to TRUE."
  exit 0
else
  if [[ "$1" == "pre" ]] ; then
    # and if snapper is installed
    # and if /etc/snapper/configs/root exists
    if [[ $(command -v '/usr/bin/snapper') ]] && [[ -e /etc/snapper/configs/root ]] ; then
      # delete any lingering temp files
      rm -f $snapper_apt_enhanced_tmp || error "Unable to delete $snapper_apt_enhanced_tmp."
      # create a snapshot
      # and save the snapshot number for reference later
      snapper create -d "${SNAPPER_DESCRIPTION}" -c number -t pre -p > $snapper_apt_enhanced_tmp ||
      error "Unable to create snapper snapshot."
      # clean up snapper
      snapper cleanup number ||
      error "Unable to run snapper cleanup."
    else
      error "Either snapper is not installed, or not configured."
    fi
    update_grub
  fi
fi
# post, so take a post snapshot
# if snapper snapshots are not being disabled using the skipSnapperPost config option
if eval "$(get_property "skipSnapperPost" "boolean" "false")"
then
  warn "==> skipping snapper post due to skipSnapperPost in $CONF_FILE set to TRUE."
  exit 0;
else
  if [[ "$1" == "post" ]] ; then
    # and if snapper is installed
    # and if the temp file with the snapshot number from the pre snapshot exists
    if [[ $(command -v '/usr/bin/snapper') ]] && [[ -e $snapper_apt_enhanced_tmp ]]
    then
      # take a post snapshot and link it to the # of the pre snapshot
      snapper create -d "${SNAPPER_DESCRIPTION}" -c number -t post --pre-number="$(cat $snapper_apt_enhanced_tmp)" ||
      error "Unable to create snapper snapshot."
      # clean up snapper
      snapper cleanup number ||
      error "Unable to run snapper cleanup."
    else
      error "Either snapper is not installed, or not configured."
    fi
    update_grub
  fi
fi

exit 0

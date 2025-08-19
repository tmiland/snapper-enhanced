#!/usr/bin/env bash

# Distro support
ARCH_CHK=$(uname -m)
if [ ! ${ARCH_CHK} == 'x86_64' ]; then
  error "Sorry, your OS ($ARCH_CHK) is not supported."
  exit 1;
fi
shopt -s nocasematch
if lsb_release -si >/dev/null 2>&1; then
  DISTRO=$(lsb_release -si)
else
  if [[ -f /etc/debian_version ]]; then
    DISTRO=$(cat /etc/issue.net)
  elif [[ -f /etc/redhat-release ]]; then
    DISTRO=$(cat /etc/redhat-release)
  elif [[ -f /etc/os-release ]]; then
    DISTRO=$(cat /etc/os-release | grep "PRETTY_NAME" | sed 's/PRETTY_NAME=//g' | sed 's/["]//g' | awk '{print $1}')
  fi
fi
case "$DISTRO" in
  Debian*|Ubuntu*|LinuxMint*|PureOS*|Pop*|Devuan*)
    export DEBIAN_FRONTEND=noninteractive
    # shellcheck disable=SC2140
    UPDATE="apt-get -o Dpkg::Progress-Fancy="1" update -qq"
    # shellcheck disable=SC2140
    INSTALL="apt-get -o Dpkg::Progress-Fancy="1" install -qq"
    ;;
  CentOS*)
    UPDATE="yum update -q"
    INSTALL="yum install -y -q"
    ;;
  Fedora*)
    UPDATE="dnf update -q"
    INSTALL="dnf install -y -q"
    ;;
  Arch*|Manjaro*)
    UPDATE="pacman -Syu"
    INSTALL="pacman -S --noconfirm --needed"
    ;;
  *) error "unknown distro: '$DISTRO'" ; exit 1 ;;
esac

# Install snapper?
SNAPPER=${SNAPPER:-n}
# Snapper rollback?
SNAPPER_ROLLBACK=${SNAPPER_ROLLBACK:-n}
# Install grub-btrfs?
GRUB_BTRFS=${GRUB_BTRFS:-n}
# Btrfs Assistant?
BTRFS_ASSISTANT=${BTRFS_ASSISTANT:-n}

install_grub_btrfs() {
  if [[ $GRUB_BTRFS == "y" ]]; then
    $INSTALL git make
    git clone https://github.com/Antynea/grub-btrfs.git
    cd grub-btrfs
    make install
    sudo systemctl enable grub-btrfsd
    sudo systemctl start grub-btrfsd
    cd ..
  fi
}

install_snapper() {
  if [[ "$SNAPPER" == "y" ]]; then
    $INSTALL snapper
  fi
}

install_snapper_rollback() {
  if [[ "$SNAPPER_ROLLBACK" == "y" ]]; then
    $INSTALL git
    git clone https://github.com/jrabinow/snapper-rollback.git
    cd snapper-rollback
    sudo cp snapper-rollback.py /usr/local/bin/snapper-rollback
    sudo cp snapper-rollback.conf /etc/
    sudo nano /etc/snapper-rollback.conf
    cd ..
  fi
}

install_btrfs_assistant() {
  if [[ "$BTRFS_ASSISTANT" == "y" ]]; then
    $INSTALL git cmake fonts-noto qt6-base-dev qt6-base-dev-tools g++ libbtrfs-dev libbtrfsutil-dev pkexec qt6-svg-dev qt6-tools-dev
    btrfs_assistant_version=$(curl -sSL https://gitlab.com/btrfs-assistant/btrfs-assistant/-/tags | grep -oP 'href=\"/btrfs-assistant/btrfs-assistant/-/tags/.*>\K.*(?=</a)' | head -n 1)

    wget -q "https://gitlab.com/btrfs-assistant/btrfs-assistant/-/archive/$btrfs_assistant_version/btrfs-assistant-$btrfs_assistant_version.tar.gz"
    cd btrfs-assistant-"$btrfs_assistant_version"
    cmake -B build -S . -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE='Release'
    make -C build
    make -C build install
    cd ..
  fi
}

install() {
	echo "Installing snapper-enhanced"
  cp -rp ./80-snapper-enhanced /etc/apt/apt.conf.d/80-snapper-enhanced
  chmod 644 /etc/apt/apt.conf.d/80-snapper-enhanced
  cp -rp ./snapper-enhanced.sh /usr/bin/snapper-enhanced.sh
  chmod 755 /usr/bin/snapper-enhanced.sh
  cp -rp ./snapper-enhanced.conf /etc/snapper-enhanced.conf
  chmod 644 /etc/snapper-enhanced.conf
	echo "Done."
}

uninstall() {
echo "Uunstalling snapper-enhanced"
rm -rf /etc/apt/apt.conf.d/80-snapper-enhanced
rm -rf /usr/bin/snapper-enhanced.sh
rm -rf /etc/snapper-enhanced.conf
echo "Done."
}

reinstall() {
  uninstall
  install
}

usage() {
  cat <<'EOF'
                                                           __                              __
     _________  ____ _____  ____  ___  _____   ___  ____  / /_  ____ _____  ________  ____/ /
    / ___/ __ \/ __ `/ __ \/ __ \/ _ \/ ___/  / _ \/ __ \/ __ \/ __ `/ __ \/ ___/ _ \/ __  / 
   (__  ) / / / /_/ / /_/ / /_/ /  __/ /     /  __/ / / / / / / /_/ / / / / /__/  __/ /_/ /  
  /____/_/ /_/\__,_/ .___/ .___/\___/_/      \___/_/ /_/_/ /_/\__,_/_/ /_/\___/\___/\__,_/   
                  /_/   /_/                                                                     

  Options are:

    --install                      | -i
    --uninstall                    | -u
    --reinstall                    | -r
		--install-snapper              | -s
		--install-snapper-rollback     | -isr
		--install-grub-btrfs           | -igb
		--install-btrfs-assistant      | -iba
EOF
}

ARGS=()
while [[ $# -gt 0 ]]
do
  case $1 in
    --help | -h)
      usage
      exit 0
      ;;
    --install | -i)
      install
      exit 0
      ;;
    --uninstall | -u)
      uninstall
      exit 0
      ;;
    --reinstall | -r)
      reinstall
      exit 0
      ;;
		--install-snapper|-s)
      shift
      SNAPPER=y
      ;;
    --install-snapper-rollback|-isr)
      shift
      SNAPPER_ROLLBACK=y
      ;;
    --install-grub-btrfs|-igb)
      shift
      GRUB_BTRFS=y
      ;;
    --install-btrfs-assistant|-iba)
      shift
      BTRFS_ASSISTANT=y
      ;;
    --*|-*)
      printf '..%s..' "$1\\n\\n"
      usage
      exit 1
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

set -- "${ARGS[@]}"

install_grub_btrfs
install_snapper
install_snapper_rollback
install_btrfs_assistant

exit 0

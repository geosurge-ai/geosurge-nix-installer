function splash() {
  cat <<'splash'

 _   _ _        _____           _        _ _
| \ | (_)      |_   _|         | |      | | |
|  \| |___  __   | |  _ __  ___| |_ __ _| | | ___ _ __
| . ` | \ \/ /   | | | '_ \/ __| __/ _` | | |/ _ \ '__|
| |\  | |>  <   _| |_| | | \__ \ || (_| | | |  __/ |
|_| \_|_/_/\_\ |_____|_| |_|___/\__\__,_|_|_|\___|_|

splash
}

function green() {
  GREEN='\033[0;32m'
  NC='\033[0m'
  echo -e "${GREEN}$1${NC}"
}

function yellow() {
  IYellow='\033[0;93m'
  NC='\033[0m'
  echo -e -n "${IYellow}$1${NC}"
}


function direnv_installed() {
  direnv_installed=$(nix eval $HOME/.config/home-manager#homeConfigurations.$USER.config.programs.direnv.enable)
}

function hm_installed() {	
  hm_installed=$(which home-manager)
}


function doInstallNix() {
  green "Downloading Nix installer..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install $confirm
  echo $installed
  if [ "$?" = 1 ]; then
    green "Nix is already installed... Continuing..."
    nix_installed=true
  else
    if [ -d "/nix" ]; then
      nix_installed=true
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
  fi	
}


function askUser() {
  while true; do
    yellow "$1 (y/n) " 
    read -r yn
    if [[ $yn =~ ^[YyNn]$ ]]; then
      break
    fi
  done
}


function doInstallHM() {
  hm_installed
  if [ -z "$hm_installed" ]; then
    askUser "Do you wish to install home-manager ?"
    if [[ $yn =~ ^[Yy]$ ]]; then
      green "Installing home-manager..."
      installing_hm=true
      nix profile install nixpkgs#hello
      # nix run github:nix-community/home-manager/master -- init
      nix run home-manager/master -- init --switch
    fi
  else
    green "Home-manager is already installed... Continuing..."
  fi
}

function doAppendDirenvToHomeConfig(){
  sed -i '$ d' $HOME/.config/home-manager/home.nix
  tee -a $HOME/.config/home-manager/home.nix <<EOF
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
EOF
}

function doInstallDirenv() {
  direnv_installed
  hm_installed
  if [ -n "$hm_installed" ] || [ "$installing_hm" = true ]
  then
    if [[ "$direnv_installed" = false ]]; then
      askUser "Direnv is not installed, do you wish to install it ?"
      if [[ $yn =~ ^[Yy]$ ]]; then
        doAppendDirenvToHomeConfig
	installing_direnv=true
      elif [[ $yn =~ ^[Nn]$ ]]; then
        green "Skipping direnv installation..."
      fi
    else
      green "Direnv is already installed... Skipping..."
    fi
  fi
}

function doHelp() {
    echo "Usage: $0 COMMAND"
    echo
    echo "Commands"
    echo
    echo "  help         Print this help"
    echo
    echo "  install      Install nix and home-manager"
    echo
    echo "  uninstall    Remove nix and home-manager"
    echo
}

function doInstall() {
  splash
  doInstallNix
  if [[ $nix_installed = true ]]; then
    doInstallHM
    if [ "$installing_hm" = true ] || [ -n "$hm_installed" ]
    then
      doInstallDirenv
    fi
    if [[ "$installing_hm" = true ]] || [[ "$installing_direnv" = true ]]; then
      # nix run github:nix-community/home-manager/master -- switch
      nix run home-manager/master -- init --switch
      if [[ "$installing_hm" = true ]]; then
        green "Home-manager has been installed, your home-manager config file is located at $HOME/.config/home-manager/home.nix"
      fi
      if [[ "$installing_direnv" = true ]]; then
        green "Direnv has been installed"
      fi
    fi
  fi
}

function doUninstall() {
  askUser "This will uninstall home-manager and Nix, do you wish to continue ?"
  if [[ $yn =~ ^[Yy]$ ]]; then
     home-manager uninstall
    /nix/nix-installer uninstall
  fi
}

function doDeploy() {
  confirm="--no-confirm"
  doInstall
}

COMMAND=$1
if [[ -z $COMMAND ]]; then
    doHelp >&2
    exit 1
fi

case $COMMAND in
    install)
        doInstall
        ;;
    deploy)
        doDeploy
	;;
    uninstall)
        doUninstall
        ;;
    help)
        doHelp
        ;;
    *)
        _iError 'Unknown command: %s' "$COMMAND" >&2
        doHelp >&2
        exit 1
        ;;
esac

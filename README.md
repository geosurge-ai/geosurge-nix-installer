# WSL-Ubuntu Provisioning on macOS

This document is a guide to creating a WSL-like experience on macOS using QEMU, libvirt, and a provisioning script.

# 👐 Open Source Development

Work on this script was performed by Julien Malka and proudly funded by [ZeroHR](https://app.zerohr.io). You can access the original repository using the following [Link](https://github.com/doma-engineering/zerohr-nix-installer).

- **Geosurge** is _forever_ grateful for this contribution, which is greatly accelerating our development.


- **Geosurge** commits to continuing contributions to Open Source, ensuring powerful software is accessible to everyone.


- **Geosurge** Engineering will maintain and support this fork, actively keeping it awesome.


- **Geosurge** enthusiastically encourages all team members to use, write, contribute, donate, and actively engage in Open Source Projects.


- **Geosurge** firmly advocates for Open Source AI. While the market leader OPEN-AI might be better called **"ClosedAI"**, we pledge ongoing support for truly open artificial intelligence projects to boost global productivity, increase GDP, reduce poverty, and cultivate happiness worldwide.


## 🚧 Requirements

Before proceeding, ensure you have the following:

- **Internet** connection to the internet will be helpful
- **macOS** (preferably on Apple Silicon)
- **Homebrew** (see installation below)
- `qemu`, `cdrtools`, and `libvirt` (via Homebrew)
- The `provision-vm.sh` script (included in this repo)

## 🧰 Step 0: Install Homebrew (if not already installed)

Open your terminal and run the following command to install Homebrew:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installation, configure your shell environment.If you are using Zsh (default on macOS):

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
eval "$(/opt/homebrew/bin/brew shellenv)"
```
This ensures that brew is available in all terminal sessions.

You also need to create a new SSH key for your VM. Run:

`ssh-keygen -t ed25519 -C "vm-setup-key"`

Then you should copy the path to that SSH key, which should be something like:

`/Users/figo/.ssh/vm-setup.pub`


After that, make sure you add your SSH key to the agent by running:

`ssh-add ~/.ssh/vm-setup`

Test that it has been correctly added by running:

`eval "$(ssh-agent -s)"`

To verify the installation:

```sh
which brew         # Should return: /opt/homebrew/bin/brew
brew --version     # Should return the Homebrew version
brew doctor        # Should return: Your system is ready to brew.
```


## 🛠️ Step 1: Install required packages
Run the following:

```
brew install qemu cdrtools libvirt
brew tap homebrew/services
```

If brew services wasn't recognized earlier, tapping homebrew/services should fix it.

## ⚙️ Step 2: Start the libvirt service


`brew services start libvirt`


This launches the background service needed to run virtual machines.


## 📜 Step 3: Run the provisioning script

First, make sure the script is executable:

`chmod +x provision-vm.sh`
Then, execute it:

`./provision-vm.sh`

What it does:

- Downloads the latest Ubuntu Server image.
- Generates a cloud-init configuration.

It will ask your via the prompts for:

- Your SSH public key (add path copied on Step Nr. 0!)
- VM disk size
- Number of virtual CPUs
- RAM allocation


The VM will boot and automatically install:
- Nix
- Home Manager
- Direnv


⚠️ Do not interact with the VM during the installation process — it may take several minutes and will shut down automatically upon completion.


## 🔌 Step 4: Access the VM

Once the VM has powered down and rebooted in headless mode, wait about 30 seconds and then connect via SSH:

```
ssh -p 5555 localhost
```

Step 5: Launch VM with user session (Optional)

1. Open System Preferences → Users & Groups
2. Select your user → go to Login Items
3. Click + and select launch-vm-with-session.app
4. Check "Hide" to avoid cluttering the screen


You should now be ready to be blessed with the incredible productivity increase of Nix :)

If you don't want to launch the VM with session, you can still boot it with:

- Boot VM: `virsh start wsl-ubuntu`
- Stop VM: `virsh destroy wsl-ubuntu`
- See Status: `virsh list --all`

## Debugging and Logs

This is supposed to be a `one-click-installation`. If you want to laugh at how long did it take @figo-geosurge to get this working, you're more than welcome to check my logs. [FIGO-LOGS](https://gist.github.com/figo-geosurge/7ef755f470ed4e8f3866705cf0b11e0a)


```
8156  4/21/2025 11:01  cd geosurge
 8157  4/21/2025 11:01  ls
[[[  8158  4/21/2025 11:01  git clone git@github.com:figo-geosurge/zerohr-nix-installer.git ]]] START
 8159  4/21/2025 11:01  code .
 8160* 4/21/2025 11:02  brew services start libvirt
 8161* 4/21/2025 11:02  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
 8162* 4/21/2025 11:04  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile\necho 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc\neval "$(/opt/homebrew/bin/brew shellenv)"\n
 8163* 4/21/2025 11:04  eval "$(/opt/homebrew/bin/brew shellenv)"\n
 8164* 4/21/2025 11:05  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
 8165* 4/21/2025 11:05  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
 8166* 4/21/2025 11:05  eval "$(/opt/homebrew/bin/brew shellenv)"
 8167* 4/21/2025 11:05  which brew
 8168* 4/21/2025 11:05  brew --version\n
 8169* 4/21/2025 11:12  brew install qemu cdrtools libvirt
 8170* 4/21/2025 11:13  brew tap homebrew/services\n
 8171* 4/21/2025 11:14  brew services start libvirt
 8172* 4/21/2025 11:14  chmod +x provision-vm.sh
 8173* 4/21/2025 11:14  ls
 8174* 4/21/2025 11:14  cd zerohr-nix-installer
 8175* 4/21/2025 11:14  ls
 8176* 4/21/2025 11:14  chmod +x provision-vm.sh\n
 8177* 4/21/2025 11:15  ./provision-vm.sh
 8178* 4/21/2025 11:18  ssh-keygen -t ed25519 -C "vm-setup-key"
 8179* 4/21/2025 11:19  ls ~/.ssh
 8180* 4/21/2025 11:19  /Users/figo/.ssh/vm-setup.pub\n
 8181* 4/21/2025 11:19  cat ~/.ssh/vm-setup.pub\n
 8182* 4/21/2025 11:20  ./provision-vm.sh
 8183* 4/21/2025 11:26  ssh -p 5555 localhost
 8184* 4/21/2025 11:28  ssh-add ~/.ssh/vm-setup
 8185* 4/21/2025 11:28  eval "$(ssh-agent -s)"\nssh-add ~/.ssh/vm-setup\n
 8186* 4/21/2025 11:29  ssh -p 5555 localhost
 8187  4/21/2025 11:42  ls
 8188  4/21/2025 11:42  rm -r zerohr-nix-installer
 8189  4/21/2025 11:42  y
 8190  4/21/2025 11:42  ls
 8191* 4/21/2025 11:43  pwd
 8192* 4/21/2025 11:43  cd ..
 8193* 4/21/2025 11:43  ls
 8194* 4/21/2025 11:43  pwd
 8195* 4/21/2025 11:43  git clone git@github.com:geosurge-ai/geosurge-nix-installer.git
 8196* 4/21/2025 11:44  cd geosurge-nix-installer
 8197* 4/21/2025 11:44  ls
[[[ 8198* 4/21/2025 11:51  history]]] -- END
 8199  4/21/2025 11:55  nano ~/.zshrc
 8200  4/21/2025 11:57  print("hello")
 8201  4/21/2025 11:57  print 'hello'
 8202  4/21/2025 11:57  history
 8203  4/21/2025 11:57  vim ~/.zsh_history
 8204  4/21/2025 11:58  % history -f
 ```

`11:51 - 11:01 = 50 minutes`, meaning anyone executing this code should aim to have it readi in `30'` as I'm the less technical person in this entire company.



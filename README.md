# WSL-Ubuntu provisioning

This document is a guide to the creation of a WSL-like experience on MacOS.

Work on this script was performed by Julien Malka and proudly funded by [ZeroHR](https://app.zerohr.io).

### Requirements:

To run this procedure you'll need installed on your machine:

- qemu, cdrtools and libvirt which you can install via [homebrew](https://brew.sh/) ;
- The `provision-vm.sh` script.

### Step 1: Activation of the libvirt service

Run this command:

```
brew services start libvirt
```

### Step 2: Running the script

First, make sure that the script is executable

```
chmod +x provision-vm.sh
```

Then, run it

```
./provision-vm.sh
```

The script is going to download an `ubuntu server` image, then generate the `cloud-init` config to provision it automatically.

The script is going to ask for the path of the public ssh key that you will use to connect to the VM (*you may want to generate a new key at this point*), and the size of the VM disk you want to have.

The script will then ask you to  fill in the number of virtual CPUs that you wish to use and the amount of RAM you want to give to the VM.

Once you've entered all the necessary information, the VM is going to perform its first boot, install Nix, home-manager and direnv. Once the installation is completed, it is going to shut down by itself.
**Do not interact with the virtual machine during this installation. The installation can take a while, it is normal.**

### Step 3

Once the VM powers down, it will reboot in "headless" mode. After about 30s, you should be able to access it with

```
ssh -p 5555 localhost
```

### (Optional) Step 4: Launch with session

Launch "System Preferences" and select "Users & Groups" then your own user, the tab "Login Items". Click "+" and select `launch-vm-with-session.app`, check "Hide".

You should now be ready to be blessed with the incredible productivity increase of Nix :)

If you don't want to launch the VM with session, you can still boot it with:

```
virsh start wsl-ubuntu
```

You can stop it with:

```
virsh destroy wsl-ubuntu
```

And you can see its status with:

```
virsh list --all
```

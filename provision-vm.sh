function green() {
  GREEN='\033[0;32m'
  NC='\033[0m'
  echo "${GREEN}$1${NC}"
}

function yellow() {
  IYellow='\033[0;93m'
  NC='\033[0m'
  printf "${IYellow}$1${NC}"
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

os=$(uname -s)
if [[ "$os" != "Darwin" ]]; then
  echo "This script has to be run on MacOS"
  exit
fi

platform=$(uname -m)

mkdir -p wsl-ubuntu

green "Downloading ubuntu 22.04..."

curl https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img --output wsl-ubuntu/ubuntu.img

green "Creating cloud-init metadata..."
while true
do
  read -e -p "Please enter the path to your SSH public key: "  ssh_key_path
  echo "The content of this file is: $(cat $ssh_key_path)"
  askUser "Are you happy with this ssh key?"
  if [[ $yn =~ ^[Yy]$ ]]; then
    break
  fi
done

  

cat << EOF > wsl-ubuntu/user-data
#cloud-config
debug: true
disable_root: false
users:
  - name: $USER
    gecos: $USER
    shell: /bin/bash
    groups: sudo
    home: /home/$USER
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock-passwd: true
    ssh-authorized-keys:
      - $(cat $ssh_key_path)


power_state:
    delay: now
    mode: poweroff
    message: Instllation done, rebooting...
    timeout: 60
    condition: true

runcmd:
    - su - $USER -c 'wget https://nuage.malka.family/s/bED7AaoCbdNqQjz/download/installer.sh -P /home/$USER'
    - su - $USER -c 'chmod +x /home/$USER/installer.sh'
    - su - $USER -c 'yes | /home/$USER/installer.sh deploy'
EOF

cat << EOF > wsl-ubuntu/meta-data
instance-id: wsl-ubuntu
local-hostname: wsl-ubuntu
EOF

mkisofs -output wsl-ubuntu/cidata.iso -volid cidata -joliet -rock wsl-ubuntu/user-data wsl-ubuntu/meta-data 

size=""
while ! [[ "$size" =~ ^[0-9]+$ ]]
do
  read -p "Enter the wanted size (Gib) of the VM disk: " size
done

qemu-img resize wsl-ubuntu/ubuntu.img "${size}G"

max_cpus=$(sysctl -n hw.ncpu)
cpus=-1
while true
do
	read -p "Enter the wanted number of virtual CPUs (max: ${max_cpus}, suggested: 6): " cpus
	if [[ "$cpus" =~ ^[0-9]+$ ]]; then
		if [[ "$cpus" -ge 0 ]] && [[ "$cpus" -le "$max_cpus" ]]; then
			break
		fi
	fi
done


max_ram=$(sysctl -n hw.memsize)
max_ram=$(expr $max_ram / 1073741824)
ram=""
while true
do
	read -p "Enter the wanted amount (in Gib) of virtual RAM (max: ${max_ram}, suggested: 8): " ram
	if [[ "$ram" =~ ^[0-9]+$ ]]; then
		if [[ "$ram" -ge 0 ]] && [[ "$ram" -le "$max_ram" ]]; then
			break
		fi
	fi

done

ram=$(expr $ram '*' 1024)
 

rm wsl-ubuntu/user-data wsl-ubuntu/meta-data

green "The VM is now going to be provisionned..."
yellow "Do not touch anything during the installation, and wait for the machine to poweroff on its own!"

sleep 3

qemu-system-x86_64 -m "${ram}" -smp "${cpus}" -hda wsl-ubuntu/ubuntu.img -cdrom wsl-ubuntu/cidata.iso -device e1000,netdev=net0 -netdev user,id=net0,hostfwd=tcp::5555-:22 -nographic -accel tcg,tb-size=1024








cat << EOF > wsl-ubuntu/ubuntu.xml
<domain xmlns:qemu="http://libvirt.org/schemas/domain/qemu/1.0" type="qemu">
  <name>wsl-ubuntu</name>
  <uuid>e7dea98a-d0e5-47b3-b3f0-a3db6b4eccf2</uuid>
  <metadata>
    <libosinfo:libosinfo xmlns:libosinfo="http://libosinfo.org/xmlns/libvirt/domain/1.0">
      <libosinfo:os id="http://ubuntu.com/ubuntu/22.04"/>
    </libosinfo:libosinfo>
  </metadata>
  <memory unit="Mib">${ram}</memory>
  <currentMemory unit="Mib">${ram}</currentMemory>
  <vcpu placement="static">${cpus}</vcpu>
  <os>
    <type arch="x86_64" machine="pc-q35-8.0">hvm</type>
    <boot dev="hd"/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode="custom" match="exact" check="none">
    <model fallback="forbid">qemu64</model>
  </cpu>
  <clock offset="utc">
    <timer name="rtc" tickpolicy="catchup"/>
    <timer name="pit" tickpolicy="delay"/>
    <timer name="hpet" present="no"/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <pm>
    <suspend-to-mem enabled="no"/>
    <suspend-to-disk enabled="no"/>
  </pm>
  <devices>
    <emulator>/opt/homebrew/bin/qemu-system-x86_64</emulator>
    <disk type="file" device="disk">
      <driver name="qemu" type="qcow2"/>
      <source file="$(pwd)/wsl-ubuntu/ubuntu.img"/>
      <target dev="vda" bus="virtio"/>
      <address type="pci" domain="0x0000" bus="0x04" slot="0x00" function="0x0"/>
    </disk>
    <disk type="file" device="cdrom">
      <driver name="qemu" type="raw"/>
      <source file="$(pwd)/wsl-ubuntu/cidata.iso"/>
      <target dev="sda" bus="sata"/>
      <readonly/>
      <address type="drive" controller="0" bus="0" target="0" unit="0"/>
    </disk>
    <controller type="usb" index="0" model="qemu-xhci" ports="15">
      <address type="pci" domain="0x0000" bus="0x02" slot="0x00" function="0x0"/>
    </controller>
    <controller type="pci" index="0" model="pcie-root"/>
    <controller type="pci" index="1" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="1" port="0x10"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="2" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="2" port="0x11"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x1"/>
    </controller>
    <controller type="pci" index="3" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="3" port="0x12"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x2"/>
    </controller>
    <controller type="pci" index="4" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="4" port="0x13"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x3"/>
    </controller>
    <controller type="pci" index="5" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="5" port="0x14"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x4"/>
    </controller>
    <controller type="pci" index="6" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="6" port="0x15"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x5"/>
    </controller>
    <controller type="pci" index="7" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="7" port="0x16"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x6"/>
    </controller>
    <controller type="pci" index="8" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="8" port="0x17"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x02" function="0x7"/>
    </controller>
    <controller type="pci" index="9" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="9" port="0x18"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x0" multifunction="on"/>
    </controller>
    <controller type="pci" index="10" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="10" port="0x19"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x1"/>
    </controller>
    <controller type="pci" index="11" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="11" port="0x1a"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x2"/>
    </controller>
    <controller type="pci" index="12" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="12" port="0x1b"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x3"/>
    </controller>
    <controller type="pci" index="13" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="13" port="0x1c"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x4"/>
    </controller>
    <controller type="pci" index="14" model="pcie-root-port">
      <model name="pcie-root-port"/>
      <target chassis="14" port="0x1d"/>
      <address type="pci" domain="0x0000" bus="0x00" slot="0x03" function="0x5"/>
    </controller>
    <controller type="sata" index="0">
      <address type="pci" domain="0x0000" bus="0x00" slot="0x1f" function="0x2"/>
    </controller>
    <controller type="virtio-serial" index="0">
      <address type="pci" domain="0x0000" bus="0x03" slot="0x00" function="0x0"/>
    </controller>
    <interface type="user">
      <mac address="52:54:00:f6:ad:00"/>
      <model type="e1000e"/>
      <address type="pci" domain="0x0000" bus="0x01" slot="0x00" function="0x0"/>
    </interface>
    <channel type="unix">
      <target type="virtio" name="org.qemu.guest_agent.0"/>
      <address type="virtio-serial" controller="0" bus="0" port="1"/>
    </channel>
    <input type="mouse" bus="ps2"/>
    <input type="keyboard" bus="ps2"/>
    <audio id="1" type="none"/>
    <watchdog model="itco" action="reset"/>
    <memballoon model="virtio">
      <address type="pci" domain="0x0000" bus="0x05" slot="0x00" function="0x0"/>
    </memballoon>
    <rng model="virtio">
      <backend model="random">/dev/urandom</backend>
      <address type="pci" domain="0x0000" bus="0x06" slot="0x00" function="0x0"/>
    </rng>
  </devices>
  <qemu:commandline>
    <qemu:arg value="-netdev"/>
    <qemu:arg value="user,id=n1,hostfwd=tcp::5555-:22"/>
    <qemu:arg value="-device"/>
    <qemu:arg value="virtio-net-pci,netdev=n1,bus=pcie.0,addr=0x19"/>
  </qemu:commandline>
</domain>
EOF

virsh define wsl-ubuntu/ubuntu.xml
virsh start wsl-ubuntu



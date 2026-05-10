# Venom Arcade Stick Linux Fix
Fixes the button binding errors of the Venom Arcade Stick (PS4) on Linux/Steam Deck

>[!IMPORTANT]
>As of now, this only fixes the binding on the PS4 mode. NOT the PS3 mode.

>[!IMPORTANT]
>Whilst this fix should work across the entire operating system, using **Steam Input** is very recommended.

>[!CAUTION]
>This is currently **experimental** and should not be used for any tournament setups just yet as it has not been properly tested.

## Requirements
- A distro running systemd (if you don't know what that is then you're probably good)
- Root permissions (sudo/doas)
- Venom Arcade Stick (PS3/PS4)

## Installation
```
git clone https://github.com/Loomeh/venom-arcadestick-linux-fix
cd venom-arcadestick-linux-fix
chmod +x install.sh
sudo ./install.sh
```
Make sure to restart your user session or reboot afterwards.

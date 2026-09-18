# Fedora ricing

```sh
gh auth login
gh repo clone shawal-mbalire/root_home_shawal
cp -r root_home_shawal/.git/ .git/
git pull
rm -rf root_home_shawal
```

```sh
sudo dnf install lua lua-devel luarocks go lua5.1
sudo dnf install hyprland hyprland-devel hyprlock hypridle hyprpolkitagent hyprpaper
sudo dnf install fish kitty fuzzel swaync blueman pavucontrol waybar gh google-chrome nm-applet faltpak
sudo dnf install exa gammastep
```

## remove

```sh
sudo dnf install hyprland sddm
sudo dnf remove gnome-shell --setopt protected_packages=
```

```sh
echo /usr/local/bin/fish | sudo tee -a /etc/shells
chsh -s /usr/bin/fish
```

```sh
sudo dnf remove gnome-** plasma-** kde-**
sudo dnf install nautilus
```

## Rawhide

changing to raw hide gives you a more rolling release distro giving you the latest fixes and patches

```sh
sudo dnf config-manager setopt rpmfusion-free.enabled=0
sudo dnf config-manager setopt rpmfusion-free-updates.enabled=0
sudo dnf config-manager setopt rpmfusion-free-updates-debuginfo.enabled=0
sudo dnf config-manager setopt rpmfusion-free-updates-source.enabled=0
sudo dnf config-manager setopt rpmfusion-free-updates-testing.enabled=0
sudo dnf config-manager setopt rpmfusion-nonfree-updates-testing.enabled=0
```

```sh
sudo dnf autoremove
sudo dnf clean all
```

```sh
sudo dnf system-upgrade download --releasever=rawhide
```

## Copr

```sh
sudo dnf enable alxhr0/Obsidian
```

## Repo

```sh
sudo dnf repo list
```

```sh
sudo dnf config-manager setopt repository.enabled=0
```

## Groups

```sh
dnf repo list
```

```sh
sudo dnf group rmove libreoffice
```

## Google chrome

```sh
echo " [google-chrome]
    1 name=google-chrome
    2 baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
    3 enabled=1
    4 gpgcheck=1
    5 gpgkey=https://dl.google.com/linux/linux_signing_key.pub  " >> /etc/yum.repos.d/google-chrome.repo
sudo dnf install google-chrome
sudo dnf remove firefox**
```

```sh
sudo rpmkeys --import https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg
printf "[gitlab.com_paulcarroty_vscodium_repo]\nname=download.vscodium.com\nbaseurl=https://download.vscodium.com/rpms/\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg\nmetadata_expire=1h" | sudo tee -a /etc/yum.repos.d/vscodium.repo
```

  Enabling the Hyprland Polkit Authentication Agent on Fedora (systemd Method)

  This guide explains how to install and configure the hyprpolkitagent for Hyprland on Fedora using its
  systemd service. This agent provides a graphical password prompt for applications that require
  administrative privileges.

  1. Enable the COPR Repository

  This project is available in the solopasha/hypr COPR repository. Enable it with the following command:

   1 sudo dnf copr enable solopasha/hypr

  2. Install the Package

  Install the hyprpolkitagent package using dnf:

   1 sudo dnf install hyprpolkitagent

  3. Enable the systemd Service

  To start the agent and ensure it launches automatically every time you log in, enable the systemd user
  service:

   1 systemctl --user enable --now hyprpolkitagent.service

  This command both enables the service to start on future logins and starts it immediately for your current
  session.

  Important Note on sudo

  You may have noticed that the systemctl command above does not use sudo. This is intentional and very
  important.

* User vs. System Services: The --user flag tells systemd to manage services for your specific user
     account, not for the entire system. These services run with your user's permissions and are stored in
     your user's home directory.
* Why `sudo` Breaks Things: When you run sudo systemctl --user ..., you are telling the system to run the
     command as the root user. As a result, it looks for services belonging to root, not your user. You will
     fail to see or interact with your own user services and may get a "service not found" error or other
     unexpected behavior.

  Always run systemctl with the --user flag as your regular user, without sudo.

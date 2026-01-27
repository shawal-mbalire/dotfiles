# My Linux Configuration  

## Application Installations  

### Snaps  
- `obsidian`  
- `codeinsiders`  

### Flatpaks  
- `zen`  
- `quran companion`  

---

## Checking File Usage  

### Linux  
```sh
du --all --human-readable --threshold 1G
```  

### macOS  
```sh
du -h -d 4 | sort -hr | head -30
```  

---

## Accepting This Configuration on a New Install  

### Quick Install (Single Command)
```sh
curl -fsSL https://raw.githubusercontent.com/shawal-mbalire/root_home_shawal/main/install.sh | bash
```

### Manual Install
```sh
git clone https://github.com/shawal-mbalire/root_home_shawal
rsync -avhu --progress root_home_shawal/ ~/
```  

---

## Installing Auth Agent (lxpolkit)  
```sh
sudo dnf install lxpolkit
```  

---

## Twingate  

### Installation  
Run the following command to install the Twingate Linux Client:  
```sh
curl -s https://binaries.twingate.com/client/linux/install.sh | sudo bash
```  
Headless Mode is available for servers, services, or container instances.  

### Setup  
After installation, configure the client with:  
```sh
sudo twingate setup
```  

---

## Installing Nerd Fonts  

### Arch  
```sh
yay -S ttf-hack-nerd
```  

### Fedora  
```sh
sudo dnf copr enable zawertun/hack-fonts
sudo dnf install hack-fonts
```  

### Installing JetBrainsMono Nerd Font  
```sh
curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
```  

---

## Hyprland Installation  
```sh
yay -Syyu hyprland-git wofi drun
```  

---

## Neovim Configuration  

### Installing Packer  
```sh
git clone --depth 1 https://github.com/wbthomason/packer.nvim\
 ~/.local/share/nvim/site/pack/packer/start/packer.nvim
```  

### Fedora Dependencies  
```sh
sudo dnf install lua lua-devel luarocks go lua5.1
```  

### Installing Luarocks on Fedora  
```fish
wget https://luarocks.org/releases/luarocks-3.11.1.tar.gz
tar zxpf luarocks-3.11.1.tar.gz
cd luarocks-3.11.1
./configure && make && sudo make install
sudo luarocks install luasocket
lua
```  

---

## Vim Plug  

### Vim  
```sh
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```  

### Neovim  
```sh
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs   https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
```  

---

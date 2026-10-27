## 👀 hyprshade Overview  

**hyprshade** is a Bash utility for controlling a Hyprshade shader with
three modes: automatic scheduling, disabled, and always enabled. In
automatic mode, it enables the shader at night and disables it during
the day.
<br><br>

![hyprshade Demo GIF](https://github.com/FURK4NGG/hyprshade/blob/main/%7B%7D/hyprshade.gif)


![hyprshade_install Demo Image](https://github.com/FURK4NGG/hyprshade/blob/main/%7B%7D/hyprshade_install.webp)

<br><br>

✅ Works On  
- Linux distributions: Arch Linux, Debian, Fedora  
- Wayland compositors: Hyprland, Sway, and other wlroots-based compositors  

⚠️ Compatibility  
Other Wayland compositors and desktop environments have not been verified yet.
<br><br>

## 🚀 Features

- [x] Three-state toggle: automatic, disabled, and always enabled  
- [x] Automatically enables the shader from 19:00 to 06:59  
- [x] Disables the shader during daytime in automatic mode  
- [x] Uses a user-level systemd timer for scheduled updates  
- [x] Sends desktop notifications when the mode changes  
- [x] Stores the current mode in a state file  
- [x] Supports command-line usage and a help message  
- [x] Provides a time argument for refreshing the automatic mode  

## 📦 Setup


<br>

<details>
<summary>Arch</summary>
   
Directory Structure  
~/.config/scripts/  
└── hyprshade-toggle-state (This file is auto-generated)  

~/.local/bin/  
├── hyprshade-auto.sh  
└── night-screen-overlay.py  
<br>
   
`Go to the`[`Hyprshade 4.0.1`](https://github.com/loqusion/hyprshade/releases?utm_source=chatgpt.com)`and download exact version`

```
cd ~/Downloads
unzip hyprshade-4.0.1.zip
cd hyprshade-4.0.1
pipx install .
```

hyprshade --version
>hyprshade, version 4.0.1

```
cd ~
git clone https://github.com/FURK4NGG/hyprshade.git
cd hyprshade
mkdir -p ~/.local/bin
sudo mkdir -p ~/.config/scripts/
sudo chmod +x ~/.config/scripts/*.sh
sudo cp -f ./hyprshade-auto.sh ~/.local/bin/hyprshade-auto.sh
sudo cp -f ./night-screen-overlay.py ~/.local/bin/night-screen-overlay.py
sudo chmod +x ~/.local/bin/hyprshade-auto.sh
sudo chmod 600 ~/.config/scripts/hyprshade-toggle-state
sudo chown $USER:$USER ~/.config/scripts/hyprshade-toggle-state
systemctl --user daemon-reload
systemctl --user enable --now hyprshade-auto.timer
```

```
sudo pacman -S --needed python python-pip python-pipx
```
</details>
<br>

<details>
<summary>Debian / Ubuntu</summary>

Directory Structure  
~/.config/scripts/  
└── hyprshade-toggle-state (This file is auto-generated)  

~/.config/systemd/user/  
├── hyprshade-auto.service  
└── hyprshade-auto.timer  

~/.local/bin/  
├── hyprshade-auto.sh  
└── night-screen-overlay.py  
<br>

```
sudo apt update
sudo apt install -y python3-gi gir1.2-gtk-3.0 python3-cairo libnotify-bin xcompmgr

cd ~
git clone https://github.com/FURK4NGG/hyprshade.git
cd hyprshade

mkdir -p ~/.local/bin ~/.config/scripts ~/.config/systemd/user

cp -f ./night-screen-overlay.py ~/.local/bin/
cp -f ./hyprshade-auto.sh ~/.local/bin/

cp -f ./hyprshade-auto.service ~/.config/systemd/user/
cp -f ./hyprshade-auto.timer ~/.config/systemd/user/

chmod +x ~/.local/bin/night-screen-overlay.py
chmod +x ~/.local/bin/hyprshade-auto.sh

```

## 🎉 Run
```
~/.local/bin/hyprshade-auto.sh
```
or  

Start filter

```
python3 ~/.local/bin/night-screen-overlay.py start
```
<br>
Stop filter  

```
python3 ~/.local/bin/night-screen-overlay.py stop
```
<br><br>
</details>
<br>

Fedora
```
sudo dnf install python3 python3-pip python3-pipx unzip
```
<br><br>

## 🎉 Run

## Rendering Backend

Hyprshade Night Screen supports two rendering backends. Choose the one that best fits your needs.

### 1. Native Hyprshade (Recommended)

Uses Hyprshade to apply the shader directly through the compositor. This method does not require the Python overlay.

```bash
~/.local/bin/hyprshade-auto.sh backend native
```

**Recommended for:** Arch Linux and Hyprland users who want to apply the night screen filter natively.

### 2. Screen Overlay

Uses `night-screen-overlay.py` to display a separate overlay layer on the screen.

```bash
~/.local/bin/hyprshade-auto.sh backend overlay
```

**Requirements:** The `night-screen-overlay.py` script must be installed at `~/.local/bin/night-screen-overlay.py`, along with its required dependencies.

**Recommended for:** Systems where the separate overlay implementation is preferred or required.

### Switching Backends

You can switch between backends at any time by running the corresponding command. The selected backend is saved and reused by automatic mode.

After selecting a backend, use the regular toggle command to cycle through the operating modes:

```bash
~/.local/bin/hyprshade-auto.sh
```

The operating modes are:

- **Automatic:** Applies the filter between 19:00 and 07:00.
- **Disabled:** Turns the filter off.
- **Always On:** Keeps the filter enabled regardless of the time.

<br><br>
   

## ❓ HOW IT WORKS ❓  
```
Run hyprshade-auto.sh  
          │  
          ▼  
 Read the saved mode  
          │  
          ▼  
 ┌────────┼───────────┐  
 ▼        ▼           ▼  
Automatic Disabled    Always On  
 ▼        ▼           ▼  
19:00–06:59  Shader    Shader  
Shader ON    OFF       ON  
Daytime OFF  
```

## [`hyprshade-auto.sh`]  

- Toggles between automatic, disabled, and always-on shader modes.  
  Otomatik, kapalı ve sürekli açık shader modları arasında geçiş yapar.  

- Automatically enables the shader at night and disables it during the day.  
  Shader efektini gece otomatik olarak etkinleştirir, gündüz devre dışı bırakır.  

- Saves the current mode in a state file.  
  Mevcut modu bir durum dosyasına kaydeder.  

- Sends desktop notifications when the shader mode changes.  
  Shader modu değiştiğinde masaüstü bildirimleri gönderir.  

- Supports the `time` argument to apply the current mode without changing it.  
  Mevcut modu değiştirmeden uygulamak için `time` argümanını destekler.  

- Uses `night_screen.frag` as the shader file.  
  Shader dosyası olarak `night_screen.frag` dosyasını kullanır.  


## [`night_screen.frag`]  

- Defines the visual shader effect applied to the screen.  
  Ekrana uygulanan görsel shader efektini tanımlar.  

- Applies a color filter to give the screen a warmer appearance.  
  Ekrana daha sıcak bir görünüm kazandırmak için renk filtresi uygular.  

- Determines how screen colors are modified by the shader.  
  Ekran renklerinin shader tarafından nasıl değiştirileceğini belirler.  


## [`hyprshade-auto.service`]  

- Defines the systemd user service for checking the current shader mode.  
  Mevcut shader modunu kontrol eden systemd kullanıcı servisini tanımlar.  

- Runs `hyprshade-auto.sh` with the `time` argument.  
  `hyprshade-auto.sh` dosyasını `time` argümanıyla çalıştırır.  

- Applies the current mode without manually switching between modes.  
  Modlar arasında manuel geçiş yapmadan mevcut modu uygular.  


## [`hyprshade-auto.timer`]  

- Runs the shader mode check periodically.  
  Shader modu kontrolünü belirli aralıklarla çalıştırır.  

- Checks the current mode every minute.  
  Mevcut modu her dakika kontrol eder.  

- Starts the timer automatically when enabled.  
  Etkinleştirildiğinde zamanlayıcıyı otomatik olarak başlatır.  


## [`hyprshade-toggle-state`]  

- Stores the currently selected shader mode.  
  Seçili shader modunu kaydeder.  

- Keeps track of whether automatic, disabled, or always-on mode is selected.  
  Otomatik, kapalı veya sürekli açık modlardan hangisinin seçili olduğunu takip eder.  

- Allows the script to preserve the selected mode between executions.    
  Betiğin seçili modu sonraki çalıştırmalarda da korumasını sağlar.  


# Fast Installation  

sudo pacman -Syu git  
git clone https://github.com/FURK4NGG/hyprshade.git  
cd hyprshade  
chmod +x install.sh  
./install.sh  

## 🔒 License  
<h1 align="center">📜 GPL-3.0 License</h1>

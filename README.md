## 👀 hyprshade Overview  

**hyprshade** is a Bash utility for controlling a Hyprshade shader with
three modes: automatic scheduling, disabled, and always enabled. In
automatic mode, it enables the shader at night and disables it during
the day.
<br><br>

![hyprshade Demo GIF](https://github.com/FURK4NGG/hyprshade/blob/main/%7B%7D/hyprshade.gif)

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


`Go to the`[`Hyprshade 4.0.1`](https://github.com/loqusion/hyprshade/releases?utm_source=chatgpt.com)`and download exact version`
```
git clone https://github.com/FURK4NGG/hyprshade.git
cd hyprshade
mkdir -p ~/.local/bin
sudo mkdir -p ~/.config/scripts/
sudo chmod +x ~/.config/scripts/*.sh
sudo cp -f ~/.config/scripts/hyprshade-auto.sh ~/.local/bin/hyprshade-auto.sh
sudo chmod +x ~/.local/bin/hyprshade-auto.sh
sudo chmod 600 ~/.config/scripts/hyprshade-toggle-state
sudo chown $USER:$USER ~/.config/scripts/hyprshade-toggle-state
systemctl --user daemon-reload
systemctl --user enable --now hyprshade-auto.timer
```

Arch
```
sudo pacman -S --needed python python-pip
```

<br><br>

## 🎉 Run

```
~/.local/bin/hyprshade-auto.sh
```
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

- Manages the `hyprshade-auto.timer` and related user services.  
  `hyprshade-auto.timer` ve ilgili kullanıcı servislerini yönetir.

- Saves the current mode in a state file.  
  Mevcut modu bir durum dosyasına kaydeder.

- Sends desktop notifications when the shader mode changes.  
  Shader modu değiştiğinde masaüstü bildirimleri gönderir.

- Supports command-line arguments and a help message.  
  Komut satırı argümanlarını ve yardım mesajını destekler.

- Provides a `time` argument to refresh the automatic mode.  
  Otomatik modu yenilemek için `time` argümanını sunar.

- Uses `night_screen.frag` as the shader file.  
  Shader dosyası olarak `night_screen.frag` dosyasını kullanır.


# Fast Installation  

sudo pacman -Syu git  
git clone https://github.com/FURK4NGG/hyprshade.git  
cd hyprshade  
chmod +x install.sh  
./install.sh  

## 🔒 License  
<h1 align="center">📜 GPL-3.0 License</h1>

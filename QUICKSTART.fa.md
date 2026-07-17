<!-- @format -->

# راهنمای سریع

نسخهٔ قابل‌حمل از بخش‌های کاربردی برای **مک** و **لینوکس**.

چیزهایی مثل Hyprland / i3 / polybar عمداً حذف شده‌اند — تمرکز روی شِل، Git، Tmux و ابزارهای روزمره است.

---

## نصب در ۳۰ ثانیه

```bash
cd ~/dotfiles   # یا مسیر همین ریپو
chmod +x install.sh
./install.sh
```

اسکریپت **همیشه** می‌پرسد: macOS / Ubuntu / Arch؟  
(مگر اینکه `--os mac|ubuntu|arch` بدهی)

### مک (پیشنهادی)

```bash
./install.sh --os mac --yes --packages --modules core,shell,git,tmux,alacritty,bins
# یا:
make mac
```

### اوبونتو

```bash
./install.sh --os ubuntu --yes --packages
make ubuntu
```

### آرچ

```bash
./install.sh --os arch --yes --packages
# optional AUR:
./install.sh --os arch --yes --packages --aur
make arch
```

### بعد از نصب

```bash
# هویت Git
nvim ~/.config/git/config.local

# ری‌لود شِل
exec zsh -l

# داخل tmux برای نصب پلاگین‌ها:
# Ctrl-a  سپس  Shift-i
```

---

## چی نصب می‌شود؟

| بخش         | توضیح                                                     |
| ----------- | --------------------------------------------------------- |
| `env` + XDG | خانه تمیز؛ تاریخچه و ابزارها زیر `~/.config` و `~/.local` |
| zsh         | oh-my-zsh + autosuggestions + vi-mode + fzf               |
| aliasrc     | git/npm/docker و میانبرهای روزمره (بدون pacman/X11)       |
| git         | aliasهای قوی + delta — بدون ایمیل شخصی                    |
| tmux        | prefix = `Ctrl-a`                                         |
| bin         | `killport`، `port`، `localip`، `ex`، `renpm`، …           |

---

## ماژول‌ها

```bash
./install.sh --modules core,shell,git,tmux,bins
./install.sh --modules alacritty,zed          # اختیاری
./install.sh --unlink                         # حذف symlinkها
```

فایل‌های قبلی با پسوند `.bak.TIMESTAMP` بکاپ می‌شوند.

---

## سفارشی‌سازی

| فایل                         | کاربرد                 |
| ---------------------------- | ---------------------- |
| `~/.config/git/config.local` | نام / ایمیل / signing  |
| `~/.config/zsh/local.zsh`    | تنظیمات فقط همین ماشین |

---

جزئیات بیشتر: [README.md](./README.md)

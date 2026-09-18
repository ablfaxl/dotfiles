# New Mac Setup

1. Install Xcode Command Line Tools:

```sh
xcode-select --install
```

2. Install Homebrew:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

3. Clone dotfiles:

```sh
mkdir -p ~/project
git clone git@github.com:ablfaxl/dotfiles.git ~/project/dotfiles
cd ~/project/dotfiles
```

4. Install packages:

```sh
brew bundle --file Brewfile
```

5. Run installer:

```sh
./install.sh --os mac --yes
```

6. Configure Git identity:

```sh
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

7. Configure GitHub:

```sh
ssh-keygen -t ed25519 -C "you@example.com"
gh auth login
```

8. Verify:

```sh
doctor
```


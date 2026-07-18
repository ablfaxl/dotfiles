.PHONY: install mac ubuntu arch packages validate unlink server help ubuntu-packages default-terminal node

help:
	@echo "make install           interactive install (asks macOS / Ubuntu / Arch)"
	@echo "make mac               macOS install + packages"
	@echo "make ubuntu            Ubuntu install + packages"
	@echo "make ubuntu-packages   apt packages only (needs sudo)"
	@echo "make default-terminal  set Alacritty as system default (Ubuntu/GNOME)"
	@echo "make node              fnm + Node LTS + pnpm/yarn/bun + ni/nr globals"
	@echo "make arch              Arch install + packages"
	@echo "make server            graceful shell for Debian/Arch servers"
	@echo "make packages          packages only (asks OS)"
	@echo "make validate          check installed tools"
	@echo "make unlink            remove managed symlinks"

install:
	./install.sh

mac:
	./install.sh --os mac --yes --packages --modules core,shell,git,tmux,alacritty,bins,node

ubuntu:
	./install.sh --os ubuntu --yes --packages --modules core,shell,git,tmux,alacritty,bins,node

ubuntu-packages:
	./scripts/install-ubuntu-packages.sh

default-terminal:
	./scripts/set-default-terminal.sh

node:
	./scripts/install-node-toolchain.sh

arch:
	./install.sh --os arch --yes --packages --modules core,shell,git,tmux,alacritty,bins,node

linux: ubuntu

packages:
	./install.sh --packages --modules core

validate:
	./scripts/validate-apps.sh

unlink:
	./install.sh --unlink

server:
	./scripts/setup-server-shell.sh --yes

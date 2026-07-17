.PHONY: install mac linux packages unlink help

help:
	@echo "make install    interactive install (asks macOS or Linux)"
	@echo "make mac        macOS install + packages"
	@echo "make linux      Linux install + packages"
	@echo "make packages   packages only (asks OS)"
	@echo "make unlink     remove managed symlinks"

install:
	./install.sh

mac:
	./install.sh --os mac --yes --packages --modules core,shell,git,tmux,alacritty,bins

linux:
	./install.sh --os linux --yes --packages --modules core,shell,git,tmux,bins

# Interactive: always asks mac vs linux
packages:
	./install.sh --packages --modules core

unlink:
	./install.sh --unlink

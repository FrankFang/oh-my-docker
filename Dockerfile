FROM archlinux:base-devel

WORKDIR /tmp
ENV SHELL /bin/bash
ADD mirrorlist /etc/pacman.d/mirrorlist
RUN yes | pacman -Syu 
RUN yes | pacman -S git zsh
VOLUME [ "/home/admin" ]

RUN	useradd --create-home --groups wheel --shell /bin/zsh admin &&\
	echo '%wheel ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER admin
# end 

# zsh
RUN zsh -c 'git clone https://code.aliyun.com/412244196/prezto.git "$HOME/.zprezto"' &&\
	zsh -c 'setopt EXTENDED_GLOB' &&\
	zsh -c 'for rcfile in "$HOME"/.zprezto/runcoms/z*; do ln -s "$rcfile" "$HOME/.${rcfile:t}"; done'
ENV SHELL /bin/zsh
# end

# AUR helper
RUN yes | sudo pacman -S git go &&\
	git clone https://aur.archlinux.org/yay.git /tmp/yay/ &&\
	cd /tmp/yay && yes | makepkg -si && rm -rf /tmp/yay
# end

# basic tools
RUN yes | sudo pacman -S vi vim neovim git curl wget tree python go java-environment-common 
ENV EDITOR=nvim
ENV VISUAL=nvim
# # end

# Python 3 and pip
ENV PYTHONUNBUFFERED=1
ENV PATH="/home/admin/.local/bin:$PATH"
ADD --chown=admin:admin pip.cn.conf /home/admin/.config/pip/pip.conf
RUN python -m ensurepip &&\
	python -m pip install --no-cache --upgrade pip setuptools wheel
# end

# Ruby
ENV PATH="/home/admin/.rvm/bin:$PATH"
RUN gpg2 --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB &&\
	(curl -sSL https://get.rvm.io | bash -s stable) &&\
	echo "ruby_url=https://cache.ruby-china.com/pub/ruby" > ~/.rvm/user/db &&\
	echo 'gem: \"--no-document --verbose\"' > "$HOME/.gemrc" &&\
	rvm install ruby-3
# end 

# # Rust
WORKDIR /tmp
ADD --chown=admin:admin .cargo.cn.config /home/admin/.cargo/config
ENV RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ENV RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
ENV CARGO_HTTP_MULTIPLEXING=false
ENV PATH="/home/admin/.cargo/bin:${PATH}"
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
# # end


# bash
ADD --chown=admin:admin .bash_aliases /home/admin/.bash_aliases
RUN echo 'source /home/admin/.bash_aliases' >> /home/admin/.zshrc &&\
		echo 'source /home/admin/.bash_aliases' >> /home/admin/.bashrc
# # end


# # Install Go
RUN yes | sudo pacman -S go
ENV GOPATH /home/admin/go
ENV PATH $GOPATH/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH" 
ENV GOROOT /usr/lib/go
RUN go env -w GO111MODULE=on &&\
    go env -w GOPROXY=https://goproxy.cn,direct &&\
		go get github.com/silenceper/gowatch
# # end

# Dev env for JS
RUN yes | sudo pacman -S nodejs npm yarn &&\
    npm config set registry=https://registry.npmmirror.com &&\
    yarn global add nrm pnpm 
# end

# Java
RUN yes | sudo pacman -S jre-openjdk-headless jdk-openjdk
ENV JAVA_HOME=/usr/lib/jvm/default/
ENV PATH=$JAVA_HOME/bin:$PATH
# end

# neovim
RUN git clone --depth=1 https://github.com/frankfang/nvim-config.git /home/admin/.config/nvim/ &&\
		git clone --depth=1 https://github.com/wbthomason/packer.nvim /home/admin/.local/share/nvim/site/pack/packer/opt/packer.nvim &&\     
		git clone --depth=1 https://github.com/navarasu/onedark.nvim.git /home/admin/.local/share/nvim/site/pack/packer/opt/onedark.nvim &&\ 
		git clone --depth=1 https://hub.fastgit.org/lifepillar/vim-gruvbox8 /home/admin/.local/share/nvim/site/pack/packer/opt/vim-gruvbox8 &&\
		git clone --depth=1 https://hub.fastgit.org/sainnhe/edge /home/admin/.local/share/nvim/site/pack/packer/opt/edge &&\
		git clone --depth=1 https://hub.fastgit.org/sainnhe/sonokai /home/admin/.local/share/nvim/site/pack/packer/opt/sonokai &&\
		git clone --depth=1 https://hub.fastgit.org/sainnhe/gruvbox-material /home/admin/.local/share/nvim/site/pack/packer/opt/gruvbox-material &&\
		git clone --depth=1 https://hub.fastgit.org/shaunsingh/nord.nvim /home/admin/.local/share/nvim/site/pack/packer/opt/nord.nvim &&\    
		git clone --depth=1 https://hub.fastgit.org/NTBBloodbath/doom-one.nvim /home/admin/.local/share/nvim/site/pack/packer/opt/doom-one.nvim &&\
		git clone --depth=1 https://hub.fastgit.org/sainnhe/everforest /home/admin/.local/share/nvim/site/pack/packer/opt/everforest &&\     
		git clone --depth=1 https://hub.fastgit.org/EdenEast/nightfox.nvim /home/admin/.local/share/nvim/site/pack/packer/opt/nightfox.nvim &&\
		pip install -U pynvim &&\
		pip install 'python-lsp-server[all]' pylsp-mypy pyls-isort vim-vint &&\
	  yarn global add vim-language-server && \
		yes | sudo pacman -S ripgrep
RUN nvim +PackerSync +20sleep +qall
# end 

# others
RUN yes | yay -S fzf
RUN mkdir /home/admin/repos
# end

FROM centos:7

WORKDIR /tmp
ENV SHELL /bin/bash

RUN sed -e 's|^mirrorlist=|#mirrorlist=|g' \
			 	-e 's|^#baseurl=http://mirror.centos.org/centos|baseurl=https://mirrors.ustc.edu.cn/centos|g' \
			 	-e 's|^enabled=0|enabled=1|g' \
        -i.bak \
        /etc/yum.repos.d/CentOS-Base.repo &&\
		yum makecache &&\
		yum install -y gcc-c++ make python3 epel-release git wget tree htop ninja-build libtool autoconf\
			automake cmake gcc pkgconfig unzip patch gettext curl ctags ruby
# Python 3 and pip
ENV PYTHONUNBUFFERED=1
ADD pip.cn.conf /root/.config/pip/pip.conf
RUN python3 -m ensurepip &&\
    pip3 install --no-cache --upgrade pip setuptools
# end

# Ruby
RUN echo "gem: \"--no-document --verbose\"" > /root/.gemrc &&\
		gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/;\
		gem update --system &&\
		gem install bundler --version '~>2.2' &&\
		bundle config mirror.https://rubygems.org https://gems.ruby-china.com; \
		gem sources --add https://rubygems.org/ --remove https://gems.ruby-china.com/; 
# end 

RUN (curl -fsSL https://rpm.nodesource.com/setup_16.x | bash -) &&\
		yum install -y nodejs && corepack enable && npm config set registry=https://registry.npmmirror.com

# Rust
ADD rustup-init.sh rustup-init.sh
ADD .cargo.cn.config /root/.cargo/config
ENV RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ENV RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
ENV CARGO_HTTP_MULTIPLEXING=false
ENV PATH="/root/.cargo/bin:${PATH}"
RUN sh ./rustup-init.sh -y; 
# end


# zsh
ADD .bash_aliases /root/.bash_aliases
RUN yum install -y git make ncurses-devel autoconf man yodl wget &&\
		wget http://nchc.dl.sourceforge.net/project/zsh/zsh/5.8/zsh-5.8.tar.xz &&\
		tar xvf zsh-5.8.tar.xz && cd zsh-5.8 && ./configure --without-tcsetpgrp &&\
			make && make install && cd ..; rm -rf zsh-5.8 zsh-5.8.tar.xz && \
		zsh -c 'git clone https://code.aliyun.com/412244196/prezto.git /root/.zprezto' &&\
    zsh -c 'setopt EXTENDED_GLOB' &&\
    zsh -c 'for rcfile in /root/.zprezto/runcoms/z*; do ln -s "$rcfile" "/root/.${rcfile:t}"; done' &&\
    echo 'source /root/.bash_aliases' >> /root/.zshrc
ENV SHELL /bin/zsh
# end


# Install Go
RUN yum install -y go
RUN git clone --depth=1 --branch go1.17.3 https://go.googlesource.com/go /root/goroot
ENV GOROOT /root/goroot
ENV GOPATH /root/gopath
ENV PATH $GOROOT/bin:$GOPATH/bin:$PATH
RUN cd /root/goroot && cd src && ./make.bash && yum remove -y go
RUN go env -w GO111MODULE=on &&\
    go env -w GOPROXY=https://goproxy.cn,direct &&\
		go install github.com/silenceper/gowatch@latest
# end

# # docker and k8s(kind)
# WORKDIR /tmp
# RUN	GO111MODULE="on" go get sigs.k8s.io/kind@v0.11.1
# # end


# neovim
RUN mkdir /root/bin && \
		ln -s /usr/bin/python3 /root/bin/python && \
    ln -s /usr/bin/pip3 /root/bin/pip
ENV PATH /root/bin:$PATH
RUN git clone --depth=1 https://github.com/frankfang/nvim-config.git /root/.config/nvim/ &&\
		git clone --depth=1 https://github.com/wbthomason/packer.nvim /root/.local/share/nvim/site/pack/packer/opt/packer.nvim &&\
		git clone --depth=1 https://github.com/navarasu/onedark.nvim.git /root/.local/share/nvim/site/pack/packer/opt/onedark.nvim &&\
		git clone --depth=1 https://hub.fastgit.org/lifepillar/vim-gruvbox8 /root/.local/share/nvim/site/pack/packer/opt/vim-gruvbox8 &&\
	 	git clone --depth=1 https://hub.fastgit.org/sainnhe/edge /root/.local/share/nvim/site/pack/packer/opt/edge &&\
		git clone --depth=1 https://hub.fastgit.org/sainnhe/sonokai /root/.local/share/nvim/site/pack/packer/opt/sonokai &&\
	 	git clone --depth=1	https://hub.fastgit.org/sainnhe/gruvbox-material /root/.local/share/nvim/site/pack/packer/opt/gruvbox-material &&\
	 	git clone --depth=1 https://hub.fastgit.org/shaunsingh/nord.nvim /root/.local/share/nvim/site/pack/packer/opt/nord.nvim &&\
		git clone --depth=1 https://hub.fastgit.org/NTBBloodbath/doom-one.nvim /root/.local/share/nvim/site/pack/packer/opt/doom-one.nvim &&\
		git clone --depth=1 https://hub.fastgit.org/sainnhe/everforest /root/.local/share/nvim/site/pack/packer/opt/everforest &&\
		git clone --depth=1 https://hub.fastgit.org/EdenEast/nightfox.nvim /root/.local/share/nvim/site/pack/packer/opt/nightfox.nvim &&\
		pip install -U pynvim &&\
		pip install 'python-lsp-server[all]' pylsp-mypy pyls-isort vim-vint &&\
		pnpm install -g vim-language-server && \
		yum-config-manager --add-repo=https://copr.fedorainfracloud.org/coprs/carlwgeorge/ripgrep/repo/epel-7/carlwgeorge-ripgrep-epel-7.repo &&\
		yum install -y ripgrep
RUN yum -y remove git && \
		yum -y install https://packages.endpoint.com/rhel/7/os/x86_64/endpoint-repo-1.9-1.x86_64.rpm &&\
		yum -y install git &&\
		git clone --depth=1 --branch stable https://github.com/neovim/neovim /tmp/neovim &&\
		cd /tmp/neovim && make -j4 && make install && rm -rf /tmp/neovim
RUN nvim +PackerSync +20sleep +qall
# end 

# # AUR
# RUN useradd -r -m -s /usr/bin/nologin myuser 
# RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
# USER myuser
# RUN git clone --depth=1 https://aur.archlinux.org/yay-git.git /tmp/yay-git/
# # RUN cd /tmp/yay-git && yes | makepkg -si 
# # USER root
# # RUN yay -Syu
# # RUN rm -rf /tmp/yay-git
# # # end

# # # k8s
# # RUN yes | pacman -S kubeadm kubelet
# # # end
# # # extra
# # RUN yes | pacman -S fzf
# # # end

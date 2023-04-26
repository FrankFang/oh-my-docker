FROM archlinux:base-20230319.0.135218

WORKDIR /tmp
ENV SHELL /bin/bash
ADD mirrorlist /etc/pacman.d/mirrorlist
RUN yes | pacman -Syu
RUN yes | pacman -S git zsh which vim curl tree htop
RUN mkdir -p /root/.config
VOLUME [ "/root/.config", "/root/repos", "/root/.vscode-server/extensions", "/root/go/bin", "/var/lib/docker", "/root/.local/share/pnpm", "/usr/local/rvm/gems", "/root/.ssh" ]
# end

# z
ADD z /root/.z_jump
# end

# zsh
RUN zsh -c 'git clone https://code.aliyun.com/412244196/prezto.git "$HOME/.zprezto"' &&\
	  zsh -c 'setopt EXTENDED_GLOB' &&\
	  zsh -c 'for rcfile in "$HOME"/.zprezto/runcoms/z*; do ln -s "$rcfile" "$HOME/.${rcfile:t}"; done'
ENV SHELL /bin/zsh
# end


# Ruby
ENV LANG=C.UTF-8
ADD rvm-rvm-1.29.12-0-g6bfc921.tar.gz /tmp/rvm-stable.tar.gz
ENV PATH /usr/local/rvm/rubies/ruby-3.0.0/bin:$PATH
ENV PATH /usr/local/rvm/gems/ruby-3.0.0/bin:$PATH
ENV PATH /usr/local/rvm/bin:$PATH
ENV GEM_HOME /usr/local/rvm/gems/ruby-3.0.0
ENV GEM_PATH /usr/local/rvm/gems/ruby-3.0.0:/usr/local/rvm/gems/ruby-3.0.0@global

RUN touch /root/.config/.gemrc; ln -s /root/.config/.gemrc /root/.gemrc;
RUN mv /tmp/rvm-stable.tar.gz/rvm-rvm-6bfc921 /tmp/rvm && cd /tmp/rvm && ./install --auto-dotfiles &&\
		echo "ruby_url=https://cache.ruby-china.com/pub/ruby" > /usr/local/rvm/user/db &&\
		echo 'gem: --no-document --verbose' >> "$HOME/.gemrc"
RUN yes | pacman -S gcc make
ADD openssl-1.1.1q.tar.gz /tmp/openssl
RUN cd /tmp/openssl/openssl-1.1.1q &&\
    ./config --prefix=/usr/local/openssl &&\
    make && make install &&\
    rm -rf /usr/local/openssl/ssl/certs && ln -s /etc/ssl/certs /usr/local/openssl/ssl/certs
RUN echo "rvm_silence_path_mismatch_check_flag=1" > /root/.rvmrc &&\
    rvm install ruby-3.0.0 --with-openssl-dir=/usr/local/openssl
RUN gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/ &&\
		gem install solargraph rubocop rufo
# end

# Install Go
RUN yes | pacman -S go
ENV GOPATH /root/go
ENV PATH $GOPATH/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
ENV GOROOT /usr/lib/go
RUN go env -w GO111MODULE=on &&\
    go env -w GOPROXY=https://goproxy.cn,direct &&\
		go install github.com/silenceper/gowatch@latest &&\
    go install golang.org/x/tools/gopls@latest
# end

# Dev env for JS
ENV PNPM_HOME /root/.local/share/pnpm
ENV PATH $PNPM_HOME:$PATH
RUN touch /root/.config/.npmrc; ln -s /root/.config/.npmrc /root/.npmrc; \
    yes | pacman -Syy && yes | pacman -S nodejs npm &&\
    npm config set registry=https://registry.npmmirror.com &&\
		corepack enable &&\
		pnpm setup &&\
		pnpm i -g http-server
# end

# nvm
ENV NVM_DIR /root/.nvm
ADD nvm-0.39.1 /root/.nvm/
RUN sh ${NVM_DIR}/nvm.sh &&\
	echo '' >> /root/.zshrc &&\
	echo 'export NVM_DIR="$HOME/.nvm"' >> /root/.zshrc &&\
	echo '[ -s "${NVM_DIR}/nvm.sh" ] && { source "${NVM_DIR}/nvm.sh" }' >> /root/.zshrc &&\
	echo '[ -s "${NVM_DIR}/bash_completion" ] && { source "${NVM_DIR}/bash_completion" } ' >> /root/.zshrc
# end

# tools
RUN yes | pacman -S fzf openssh exa the_silver_searcher fd rsync &&\
		ssh-keygen -t rsa -N '' -f /etc/ssh/ssh_host_rsa_key &&\
		ssh-keygen -t dsa -N '' -f /etc/ssh/ssh_host_dsa_key
# end



# fq
ADD proxychains.conf /root/.config/proxychains.conf
RUN yes | pacman -S trojan proxychains-ng
# end

# others
RUN yes | pacman -S postgresql-libs
# end

# dotfiles
ADD bashrc /root/.bashrc
RUN echo '[ -f /root/.bashrc ] && source /root/.bashrc' >> /root/.zshrc; \
    echo '[ -f /root/.zshrc.local ] && source /root/.zshrc.local' >> /root/.zshrc
RUN mkdir -p /root/.config; \
    touch /root/.config/.profile; ln -s /root/.config/.profile /root/.profile; \
    touch /root/.config/.gitconfig; ln -s /root/.config/.gitconfig /root/.gitconfig; \
    touch /root/.config/.zsh_history; ln -s /root/.config/.zsh_history /root/.zsh_history; \
    touch /root/.config/.z; ln -s /root/.config/.z /root/.z; \
    touch /root/.config/.rvmrc; ln -s /root/.config/.rvmrc /root/.rvmrc; \
    touch /root/.config/.bashrc; ln -s /root/.config/.bashrc /root/.bashrc.local; \
    touch /root/.config/.zshrc; ln -s /root/.config/.zshrc /root/.zshrc.local;
RUN echo "rvm_silence_path_mismatch_check_flag=1" >> /root/.rvmrc
RUN git config --global core.editor "code --wait"; \
    git config --global init.defaultBranch main
# end

# dockerd
RUN yes | pacman -S docker &&\
		mkdir -p /etc/docker &&\
		echo '{"registry-mirrors": ["http://f1361db2.m.daocloud.io"] }' > /etc/docker/daemon.json
# end

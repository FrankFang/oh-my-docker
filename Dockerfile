FROM alpine:3.14.1

ARG not_in_china
ENV nic=${not_in_china} 
WORKDIR /tmp
ENV SHELL /bin/bash

# Speed up for Chinese users
RUN [ -z "$nic" ] && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
# end

# basic tools
RUN apk update
RUN apk add --update alpine-sdk && \
    apk add libffi-dev openssl-dev && \
    apk --no-cache --update add build-base \
        ca-certificates cmake
RUN apk add --no-cache bash git vim 
ENV EDITOR=/usr/bin/vim
ENV VISUAL=/usr/bin/vim
# end

# Python 3 and pip
ENV PYTHONUNBUFFERED=1
ADD pip.cn.conf /root/.config/pip/pip.conf
RUN [ -z "$nic" ] || rm /root/.config/pip/pip.conf
RUN apk add --update --no-cache python3 &&\
    ln -sf python3 /usr/bin/python &&\
    python3 -m ensurepip &&\
    pip3 install --no-cache --upgrade pip setuptools
# end

# Ruby
RUN apk add --no-cache ruby=~2.7 ruby-dev=~2.7 ruby-full &&\
    echo "gem: \"--no-document --verbose\"" > /root/.gemrc &&\
    [ -z "$nic"] && gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/;\
    gem update --system &&\
    gem install bundler --version '~>2.2' &&\
    [ -z "$nic"] || echo "gem: \"--no-document --verbose\"" > /root/.gemrc; \
    [ -z "$nic"] && bundle config mirror.https://rubygems.org https://gems.ruby-china.com;
# end 

# Rust
WORKDIR /tmp
ADD rustup-init.sh rustup-init.sh
ADD .cargo.cn.config /root/.cargo/config
ENV RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ENV RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
ENV CARGO_HTTP_MULTIPLEXING=false
ENV PATH="/root/.cargo/bin:${PATH}"
RUN [ -z "$nic" ] || rm /root/.cargo/config;\
    apk add --no-cache ca-certificates && \
    sh ./rustup-init.sh -y; 
# end


# zsh
ENV SHELL /bin/zsh
ADD .bash_aliases /root/.bash_aliases
RUN apk add --no-cache zsh &&\
    zsh -c 'git clone https://code.aliyun.com/412244196/prezto.git /root/.zprezto' &&\
    zsh -c 'setopt EXTENDED_GLOB' &&\
    zsh -c 'for rcfile in /root/.zprezto/runcoms/z*; do ln -s "$rcfile" "/root/.${rcfile:t}"; done' &&\
    echo 'source /root/.bash_aliases' >> /root/.zshrc
# end

# Rails
RUN apk add --no-cache libxml2 libxml2-dev libxml2-utils sqlite-dev tzdata;\
    apk add postgresql-dev postgresql; 
# # https://github.com/sass/sassc-ruby/issues/189
# # sassc takes too long to install
# # RUN MAKEFLAGS=-j4 gem install sassc --version '2.1.0' -- --disable-march-tune-native
# RUN gem install rails --version '~>6.1'
# # RUN rails new --skip-sprockets app 
# # WORKDIR /tmp/app 
# # RUN bin/rails webpacker:install 
# # ENTRYPOINT bundle exec puma -p 3000 -e production
# # EXPOSE 3000
# end


# Install Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH
RUN apk add --no-cache go=~1.16.7; \
    mkdir -p ${GOPATH}/src ${GOPATH}/bin; \
    [ -z "$nic" ] && go env -w GO111MODULE=on &&\
    go env -w  GOPROXY=https://goproxy.cn,direct; \
    go get github.com/uudashr/gopkgs/v2; \
    go get github.com/uudashr/gopkgs/v2/cmd/gopkgs; \
    go get github.com/ramya-rao-a/go-outline; \
    go get github.com/cweill/gotests/... ; \
    go get golang.org/x/tools/gopls; \
    go get go get github.com/fatih/gomodifytags; \
    go get github.com/josharian/impl; \
    go get github.com/haya14busa/goplay; \
    go get github.com/haya14busa/goplay/cmd/goplay; \
    go get github.com/go-delve/delve/cmd/dlv; \
    go get honnef.co/go/tools/cmd/staticcheck; \
    go get golang.org/x/tools/gopls@latest; \
    go get golang.org/x/tools/cmd/goimports; 
# end

# Dev env for JS
RUN apk add --no-cache nodejs=~14.17 yarn=~1.22 &&\
    [ -z "$nic" ] && yarn config set registry https://registry.npm.taobao.org; \
    yarn global add nrm; 
# end

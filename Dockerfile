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
RUN apk --no-cache --update add build-base \
        ca-certificates cmake bash git vim \
        libffi-dev openssl-dev alpine-sdk
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


# Install Go
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH
RUN apk add --no-cache go=~1.16; \
    mkdir -p ${GOPATH}/src ${GOPATH}/bin; \
    [ -z "$nic" ] && go env -w GO111MODULE=on &&\
    go env -w GOPROXY=https://goproxy.cn,direct; 
# end

# Dev env for JS
RUN apk add --no-cache nodejs=~14.17 yarn=~1.22 npm=~7.17&&\
    [ -z "$nic" ] && npm config set registry=https://registry.npm.taobao.org; \
    yarn global add nrm pnpm; 
# end

# Java
RUN apk add --no-cache openjdk8=~8
ENV JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH
# end

# fix
RUN apk add --update --no-cache less openssh
# end
FROM alpine:3.14.1

# if you are not in China, remove this line
ARG not_in_china
ENV nic=${not_in_china} 
WORKDIR /tmp

# Speed up for Chinese users
RUN [ -z "$nic" ] && sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
ADD pip.cn.conf /root/.config/pip/pip.conf
RUN [ -z "$nic" ] || rm /root/.config/pip/pip.conf
# end

# basic tools
RUN apk update
RUN apk add --update alpine-sdk && \
    apk add libffi-dev openssl-dev && \
    apk --no-cache --update add build-base \
        ca-certificates
RUN apk add --no-cache bash git vim 
ENV EDITOR=/usr/bin/vim
ENV VISUAL=/usr/bin/vim
# end

# Install Python 3 and pip
ENV PYTHONUNBUFFERED=1
RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools
# end

# Install Go
RUN apk add --no-cache go=~1.16.7
ENV GOROOT /usr/lib/go
ENV GOPATH /go
ENV PATH /go/bin:$PATH
RUN mkdir -p ${GOPATH}/src ${GOPATH}/bin
# end

# Dev env for JS
RUN apk add --no-cache nodejs=~14.17 yarn=~1.22
RUN [ -z "$nic" ] && yarn config set registry https://registry.npm.taobao.org
# end

# Ruby
RUN apk add --no-cache ruby=~2.7 ruby-dev=~2.7 ruby-full
RUN echo "gem: \"--no-document --verbose\"" > /root/.gemrc
RUN [ -z "$nic"] && gem sources --add https://gems.ruby-china.com/ --remove https://rubygems.org/
RUN gem update --system
RUN gem install bundler --version '~>2.2'
# end 

# Rails
RUN apk add --no-cache libxml2 libxml2-dev libxml2-utils sqlite-dev tzdata
# https://github.com/sass/sassc-ruby/issues/189
# sassc takes too long to install
# RUN MAKEFLAGS=-j4 gem install sassc --version '2.1.0' -- --disable-march-tune-native
RUN gem install rails --version '~>6.1'
RUN [ -z "$nic"] && echo "gem: \"--no-document --verbose\"" > /root/.gemrc
RUN [ -z "$nic"] && bundle config mirror.https://rubygems.org https://gems.ruby-china.com
# RUN rails new --skip-sprockets app 
# WORKDIR /tmp/app 
# RUN bin/rails webpacker:install 
# ENTRYPOINT bundle exec puma -p 3000 -e production
# EXPOSE 3000
# # end

# Rust
WORKDIR /tmp
RUN apk add --no-cache ca-certificates
ADD rustup-init.sh rustup-init.sh
ENV RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ENV RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup
RUN sh ./rustup-init.sh -y
ENV PATH="/root/.cargo/bin:${PATH}"
# end


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
ENV PATH /usr/local/go/bin:$PATH

ENV GOLANG_VERSION 1.17.1

RUN set -eux; \
	apk add --no-cache --virtual .fetch-deps gnupg; \
	arch="$(apk --print-arch)"; \
	url=; \
	case "$arch" in \
		'x86_64') \
			export GOARCH='amd64' GOOS='linux'; \
			;; \
		'armhf') \
			export GOARCH='arm' GOARM='6' GOOS='linux'; \
			;; \
		'armv7') \
			export GOARCH='arm' GOARM='7' GOOS='linux'; \
			;; \
		'aarch64') \
			export GOARCH='arm64' GOOS='linux'; \
			;; \
		'x86') \
			export GO386='softfloat' GOARCH='386' GOOS='linux'; \
			;; \
		'ppc64le') \
			export GOARCH='ppc64le' GOOS='linux'; \
			;; \
		's390x') \
			export GOARCH='s390x' GOOS='linux'; \
			;; \
		*) echo >&2 "error: unsupported architecture '$arch' (likely packaging update needed)"; exit 1 ;; \
	esac; \
	build=; \
	if [ -z "$url" ]; then \
# https://github.com/golang/go/issues/38536#issuecomment-616897960
		build=1; \
		url='https://dl.google.com/go/go1.17.1.src.tar.gz'; \
		sha256='49dc08339770acd5613312db8c141eaf61779995577b89d93b541ef83067e5b1'; \
# the precompiled binaries published by Go upstream are not compatible with Alpine, so we always build from source here 😅
	fi; \
	\
	wget -O go.tgz.asc "$url.asc"; \
	wget -O go.tgz "$url"; \
	echo "$sha256 *go.tgz" | sha256sum -c -; \
	\
# https://github.com/golang/go/issues/14739#issuecomment-324767697
	GNUPGHOME="$(mktemp -d)"; export GNUPGHOME; \
# https://www.google.com/linuxrepositories/
	gpg --batch --keyserver keyserver.ubuntu.com --recv-keys 'EB4C 1BFD 4F04 2F6D DDCC EC91 7721 F63B D38B 4796'; \
	gpg --batch --verify go.tgz.asc go.tgz; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" go.tgz.asc; \
	\
	tar -C /usr/local -xzf go.tgz; \
	rm go.tgz; \
	\
	if [ -n "$build" ]; then \
		apk add --no-cache --virtual .build-deps \
			bash \
			gcc \
			go \
			musl-dev \
		; \
		\
		( \
			cd /usr/local/go/src; \
# set GOROOT_BOOTSTRAP + GOHOST* such that we can build Go successfully
			export GOROOT_BOOTSTRAP="$(go env GOROOT)" GOHOSTOS="$GOOS" GOHOSTARCH="$GOARCH"; \
			./make.bash; \
		); \
		\
		apk del --no-network .build-deps; \
		\
# pre-compile the standard library, just like the official binary release tarballs do
		go install std; \
# go install: -race is only supported on linux/amd64, linux/ppc64le, linux/arm64, freebsd/amd64, netbsd/amd64, darwin/amd64 and windows/amd64
#		go install -race std; \
		\
# remove a few intermediate / bootstrapping files the official binary release tarballs do not contain
		rm -rf \
			/usr/local/go/pkg/*/cmd \
			/usr/local/go/pkg/bootstrap \
			/usr/local/go/pkg/obj \
			/usr/local/go/pkg/tool/*/api \
			/usr/local/go/pkg/tool/*/go_bootstrap \
			/usr/local/go/src/cmd/dist/dist \
		; \
	fi; \
	\
	apk del --no-network .fetch-deps; \
	\
	go version

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH
RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH" 
ENV GOROOT /usr/local/go
RUN [ -z "$nic" ] && go env -w GO111MODULE=on &&\
    go env -w GOPROXY=https://goproxy.cn,direct; &&\
		go get github.com/silenceper/gowatch
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
RUN apk add --update --no-cache less openssh tree
# end
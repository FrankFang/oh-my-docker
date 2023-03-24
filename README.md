Oh My Docker
===

你的第一个 Docker 开发环境。

**[视频教程](https://www.bilibili.com/video/BV1LP4y1W7nw)**

## 使用方法

见 https://github.com/FrankFang/oh-my-env-1

## 功能介绍

1. 内置 git / vim / python3 / ruby / gem / bundler / cargo / rustc / zsh / go / node / yarn 等命令
2. 给国内用户配置了加速镜像


## 常见问题

### 如何提升文件性能？

1. 新建一个 Docker volume
2. 在my-projects/.devcontainer/devcontainer.json 中改写 mounts 为
    ```
    "mounts": [
      "source=刚才创建的volume的名字,target=${containerWorkspaceFolder}/high_speed_files,type=volume"
	  ],
    ```
3. 在 VSCode 中运行 rebuild Container
4. 这样一来 high_speed_files 目录里的文件的性能就非常高了
5. 不过要记得经常把 volume 中的文件上传到 GitHub，不然你哪天不小心把 volume 删了，代码就彻底没了 
6. 如果你希望备份 volume 的数据，可以看[这篇问答](https://stackoverflow.com/questions/26331651/how-can-i-backup-a-docker-container-with-its-data-volumes)。

### 如何添加自己的工具？

你只需要在你自己的项目中的 Dockerfile中写 

```
RUN yes | pacman -Syu
RUN yes | pacman -S xxx
```

即可安装 xxx 工具。

### 如何添加自己的配置

oh-my-docker 内置了 chezmoi，它可以用来管理配置文件，举例：

1. 初始化 chezmoi，命令为 `chezmoi init`
2. 把你想要修改的配置添加到仓库，命令为 `chezmoi add ~/.bashrc`
3. 修改配置，命令为 `vim ~/.bashrc` 或 `code ~/.bashrc`
4. 保存你的修改到仓库，命令为 `chezmoi re-add ~/.bashrc`
5. 当你 rebuild container 之后，执行 `chezmoi apply` 就可以把你的配置恢复到最新

注意：这样做的前提是你在 .devcontainer.json 里面添加如下配置：

```
"mounts": [
	"source=chezmoi,target=/root/.local/share/chezmoi,type=volume"
]
```

chezmoi 的详细用法见：https://github.com/twpayne/chezmoi

### .devcontainer/devcontainer.json 参考

```
{
	"name": "OhMyDocker",
	"context": "..",
	"dockerFile": "/path/to/Dockerfile",
	"settings": {},
	"extensions": [],
	"runArgs": [
		//"--network=network1",
		//"--memory=10240m",
		//"--memory-swap=10240m"
		"--dns=114.114.114.114",
		"--privileged",
	],
	"mounts": [
		"source=chezmoi,target=/root/.local/share/chezmoi,type=volume",
		"source=repos,target=/root/repos,type=volume",
		"source=vscode-extensions,target=/root/.vscode-server/extensions,type=volume",
    "source=go-bin,target=/root/go/bin,type=volume",
	],
	"remoteUser": "root",
	"postStartCommand": "/usr/sbin/dockerd & /usr/sbin/sshd -D"
}
```

### 如何连接数据库？

1. 新建一个 Docker network
2. 新建另一个 Docker 的数据库实例，让其连接第一步中的 network
3. 在 my-projects/.devcontainer/devcontainer.json 中改写 runArgs 为 `"runArgs": ["--network=oh-my-docker", "--dns=114.114.114.114"],`
4. 在 VSCode 中运行 rebuild Container



### 如何安装 Rails?

```
apk add --no-cache libxml2 libxml2-dev libxml2-utils sqlite-dev tzdata
apk add postgresql-dev postgresql
gem install rails --version '~>6.1'
rails new --api my_rails_app
```

## 如何让容器与宿主机共享 ssh 认证信息

参考微软官方的教程：https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials

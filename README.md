Oh My Docker
===

你的第一个 Docker 开发环境。

**[视频教程](https://www.bilibili.com/video/BV1LP4y1W7nw)**

## 使用方法

1. 安装最新版 Docker 客户端，并运行 Docker
  1. 国内用户建议按照[这篇教程](https://www.runoob.com/docker/docker-mirror-acceleration.html)配置加速镜像
1. 在本地创建目录 my-projects
2. 使用 VSCode 打开 my-projects，安装 [Remote - Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) 插件
3. 创建 my-project/Dockerfile，并在文件中写入 `FROM frankfang128/oh-my-docker:latest` 即可
4. 在 VSCode 中运行命令（按下快捷键 ctrl+shift+p）输入 Reopen Folder in Container 后回车
5. 稍等片刻，你就可以新建终端，调用 go / node / cargo / python 等命令了。

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

你只需要在 my_projects/Dockerfile 中写 

```
RUN apk add --no-cache XXX
```

就可以安装任意工具了。

### 如何添加自己的配置

oh-my-docker 内置了 chezmoi，它可以用来管理配置文件，举例：

```
chezmoi init
chezmoi add ~/.bashrc
chezmoi edit ~/.bashrc
chezmoi -v apply
```

详细用法见：https://github.com/twpayne/chezmoi

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

参考微软官方的教程：https://code.visualstudio.com/docs/remote/containers#_using-ssh-keys

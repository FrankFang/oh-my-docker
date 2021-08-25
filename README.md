Oh My Docker
===

你的第一个 Docker 开发环境。

## 使用方法

1. `git clone https://github.com/FrankFang/oh-my-docker.git`
2. `cd oh-my-docker`
3. `docker build .` 得到一个字符串，记为 AAAA
4. `docker run -dit -v 你的项目目录的绝对路径:/code -p 3000:3000 --name oh-my-docker AAAA` 运行后你就会得到名为 oh-my-docker 的虚拟开发环境了
5. 用 VSCode 打开你的项目目录，按下 ctrl+shift+P，输入 attach container，选择 oh-my-docker，得到一个新的 VSCode 窗口
6. 在这个新窗口中打开 /code 目录

完。
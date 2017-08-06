# qqqtips
tips for q coding
## 如何解决qml在非windows平台下的编译问题
- 下载qml的包
-  安装 Fortran https://github.com/zholos/qml/wiki/Compiling-on-OS-X
- 修改configrue文件113行为：Darwin:x86_64) KXARCH=m32 ;; # m64
- 正常流程，继续编译，直到完成

- configure文件允许传递参数，只要在参数传递中，制定KXARCH=m32即可，也行

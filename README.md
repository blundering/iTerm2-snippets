This site hosts code for <a href="https://iterm2.com">iTerm2</a>.

[![Build Status](https://travis-ci.org/gnachman/iTerm2.svg?branch=master)](https://travis-ci.org/gnachman/iTerm2)
[![Coverage Status](https://coveralls.io/repos/github/gnachman/iTerm2/badge.svg?branch=master)](https://coveralls.io/github/gnachman/iTerm2?branch=master)

<ul>
<li><a href="https://iterm2.com/bugs">File a bug report here!</a></li>
<li>Issues are on <a href="https://gitlab.com/gnachman/iterm2/issues">Gitlab</a> because Github doesn't support issue attachments.</li>
<li><a href="https://gitlab.com/gnachman/iterm2/wikis/HowToBuild">How do I build this thing?</a></li>
<li><a href="https://iterm2.com/downloads.html">Downloads</a>
</ul>


*************
因为不太懂oc 所以直接复制原来的代码,稍作修改 做了一个简单的snippets功能

snippets 分支中
添加了两个文件(从ToolPasteHistory复制而来,实现功能)
sources/ToolSnippets.h;
sources/ToolSnippets.m;

修改了一个文件(添加菜单)
sources/iTermToolbeltView.m

修改配置文件json形式 

文件地址:/Users/用户名/Library/ApplicationSupport/iTerm2/Toolbelt/Snippets.json

文件内容 

```
[
    {
        "title":"显示当前目录",
        "content":"pwd"
    },
    {
        "title":"进入目录",
        "content":"cd ~"
    }
]
```
![输入图片说明](https://images.gitee.com/uploads/images/2018/1102/153512_26720f41_2135690.png "屏幕截图.png")

具体效果如下 

![输入图片说明](https://images.gitee.com/uploads/images/2018/1102/153335_8c136d74_2135690.gif "iTerm2-snippets.gif")

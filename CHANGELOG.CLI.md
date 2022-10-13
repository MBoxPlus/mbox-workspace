# 2022/02/22

[Added] 移动/重命名 Workspace 可能会导致 Git Worktree 路径错误，增加了 `mbox git repair` 命令可进行自动修复

[Added] `mbox feature merge` 添加 `--[no-]check-conflict` 参数跳过冲突检测

[Fixed] 修复合并其他 Feature 出现验证失败

[Fixed] `--keep-local-changes` 参数不再删除本地变动

[Fixed] 修复 Home 目录是一个符号链接的目录时，判断 Home 目录会出错

[Fixed] 修复用户 Home 目录大小写错误时，判断 Home 目录会出错

[Optimize] Feature Import 更改为总是切到远程分支的最新节点

[Optimize] 允许添加 Workspace 内的不受 MBox 控制的本地仓库

[Optimize] 添加仓库将默认 Pull 最新分支

[Optimize] 移除 Script 类型的仓库将直接删除

[Optimize] `mbox merge` 失败将抛出 Error 信息

[Optimize] 添加/移除仓库后，会排序下仓库列表，这样 `mbox status` 显示顺序更美观

[Optimize] 当两个 Git 仓库同名但是不同组，将会使用全名代替名称，例如 `ios/IM` 和 `android/IM` 两个 Git 仓库，为了简化用户使用，mbox add 到本地的时候都是叫 `IM`，当两个仓库同时 add 时，将会出现混乱。现在 MBox 会自动识别使用全名 `ios/IM` 代替 `IM`.

[Change] Feature 的 target branch 不再是强制性的，增加 `mbox feature set-target-branch` 命令进行设置

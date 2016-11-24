# Git Command #

## 配置 ##
    $ git config --global user.name "John Doe"
    $ git config --global user.email johndoe@example.com
    $ git config --global core.editor emacs
    $ git config --global merge.tool vimdiff

## 创建 ##
复制已创建的仓库

    git clone ssh://user@domain.com/repo.git 

创建本地新仓库 

    git init

## 本地修改 ##
显示工作路径下全部已修改的文件

	git status

显示与上次提交版本的不同

    git diff

显示两个commit之间文件的不同

    git diff <commitA> <commitB> --name-only <file>

显示两个branch之间文件的不同

    git diff <branchA> <branchB> <file>

把当前所有修改添加到下次提交中

    git add .

指定文件的修改到下次提交中

    git add <file>

取消已放到下次提交中的文件

    git reset <file>

提交本地所有修改

    git commit -a

提交之前已标记的变化

    git commit

修改上次提交

    git commit amend

## 撤销 ##
放弃所有未提交的修改

    git reset --hard HEAD
    git reset --hard origin/<branch>

放弃某个文件所有未提交的修改

    git checkout HEAD <file>
    git checkout <commit> <file>

通过一个新提交重置一个提交

    git revert <commit>

将HEAD重置到commit， 并抛弃该commit后面的修改

    git reset --hard <commit>

将HEAD重置到commit，并将之后修改标记为未添加到缓存区的修改,可用于将多个乱七八糟的commit合并

    git reset --soft <commit>

将HEAD重置到commit，并保留未提交的修改

    git reset --keep <commit> 

## 提交历史 ##
显示所有提交记录

    git log

显示指定文件的修改

    git log -p <file>

显示指定作者的修改

    git log --author=<XXX XXX>

显示修改，以简洁形式

    git log --one-line --graph

显示一周内的修改

    git log --after="1 week ago"

谁，何时，修改什么内容

    git blame <file>

## 分支 ##
显示远程端有哪些分支以及本地分支怎样关联远程分支

    git remote show <remote> 

切换当前分支

    git checkout <branch>

创建新分支

    git branch <new-branch>

检出可追溯分支

    git checkout -b <newBranch> <remote/branch>

添加新的远程端

    git remote add <shortname> <url>

下载远程端的所有改动到本地，不会自动合并到当前分支

    git fetch <remote>

下载远程端的所有改动到本地，自动合并到当前分支

    git pull <remote> <branch>

下载远程端的所有改动到本地，自动合并到当前分支，并将当前分支更新置于远端所有更新之上 <<推荐>>

    git pull <remote> <branch> --rebase

发布到远程端

    git push <remote> <branch>

删除本地分支

    git branch -D <branch>

删除远程端分支

    git push origin --delete <branch>

## 获取其他branch上的版本 ##
获取另一个branch下的commit修改的内容 

    git cherry-pick <Commit>

获取另一个branch下的文件内容

	git checkout <branch> -- <path_to_file>

查看另一个branch下文件的内容，而无需切换branch

    git show <branch>:<file> > deleteme.txt

## 标签 ##
给当前提交打标签

    git tag <tag-name> 
发布标签

    git push --tags

## 合并与重置 ##
将分支合并到当前分支

    git merge <branch>

将当前版本的commit重置到分支中

    git rebase <branch>

退出重置

    git rebase --abort

解决冲突后重置

    git rebase --continue

使用配置的合并工具解决冲突

    git mergetool

找两个branch的最后共同祖先

    git merge-base <branchA> <branchB>  

Mergetool的config
[merge]
    tool = gvimdiff2 

## 除merge外其他合并branch的方式 ##
Option 1 rebase: 将<branch>的改动置于最新的master之上，在<branch>上应多用rebase以消除自动出现的merge commit, 但在已push的<branch>上绝不可使用rebase

    $ git checkout <branch> 
    $ git rebase master 

Option 2 squash：将<branch>的所有改动合并成一个commit，并置于master的改动之上。如果之前<branch> 有很多杂乱的commit, squash可以看到比较干净的commit

    $ git checkout master
    $ git merge --squash <branch>

Option 3 rebase -i：结合了Option 1和Option 2， 但操作比较复杂,不推荐

    $ git checkout <branch>
    $ git rebase -i master 

## 合并branch并消除conflict的操作 ##

    git pull
    git checkout master
    git merge <branch>
    git mergetool
    git commit
    git push
    git clean

## Bisect sequence ##
    git bisect start
    git bisect good <commit>
    git bisect bad <commit>
    git bisect log
    git bisect reset

## Stash ##
    git stash save <message>
    git stash list
    git stash apply stash@{0}
    git stash drop stash@{0}
    git stash clear

## Submodule ##
    git submodule add git://github.com/NorbertKrupa/vertica-kit.git Vertica/vertica-kit

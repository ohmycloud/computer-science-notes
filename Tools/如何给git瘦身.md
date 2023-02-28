如何给 git 瘦身：

错误提交了 jar 文件,  然后又删除了,  但是 .git 目录下面文件暂用了很多空间:

$ git filter-branch --force --index-filter \
'git ls --cached --ignore-unmatch *.jar' \
--prune-empty --tag-name-filter cat -- --all


git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch *.jar' --prune-empty --tag-name-filter cat -- --all

git for-each-ref --format='delete %(refname)' refs/original | git update-ref --stdin
git reflog expire --expire=now --all
git gc --prune=now

git push --force --verbose --dry-run
git push --force
git push origin master --force


--

$ rm -rf .git/refs/original/ 
$ git reflog expire --expire=now --all
$ git gc --prune=now
$ git gc --aggressive --prune=now
#!/bin/bash
read -p """Please enter the updated content:" content

echo "=====================（1/2）====================================="
cd /home/ylighgh/workspace/github/hexo/
hexo clean && hexo generate
git add .
git commit -m "$content"
git push
rm -rf /home/ylighgh/workspace/github/ylighgh.github.io/hexo/*
cp -r /home/ylighgh/workspace/github/hexo/public/* /home/ylighgh/workspace/github/ylighgh.github.io/hexo/
echo "=====================（2/2）======================================"
cd /home/ylighgh/workspace/github/ylighgh.github.io/
git add .
git commit -m"$content"
git push
echo "============================Finshed==============================="
exit 0


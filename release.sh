#!/bin/bash
read -p """Please enter the updated content:" content

echo "=====================（1/2）====================================="
cd /home/ylighgh/workspace/github/hexo/
changed_files=$(git diff --name-only -- source/_posts)
current_time=$(date +"%Y-%m-%d %H:%M:%S")
for file in $changed_files; do
    if [ -f "$file" ]; then
        sed -i "3s/.*/date: $current_time/" "$file"
    fi
done
hexo clean && hexo generate
git add .
git commit -m "$content"
git pull
git push
rm -rf /home/ylighgh/workspace/github/ylighgh.github.io/hexo/*
cp -r /home/ylighgh/workspace/github/hexo/public/* /home/ylighgh/workspace/github/ylighgh.github.io/hexo/
echo "=====================（2/2）======================================"
cd /home/ylighgh/workspace/github/ylighgh.github.io/
git add .
git commit -m"$content"
git pull
git push
echo "============================Finshed==============================="
exit 0


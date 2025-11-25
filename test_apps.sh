#!/bin/bash

echo "=== 测试打开应用 ==="

echo ""
echo "1. 测试打开抖音："
/usr/bin/open -a "抖音"
echo "退出码: $?"

sleep 2

echo ""
echo "2. 测试打开汽水音乐："
/usr/bin/open -a "汽水音乐"
echo "退出码: $?"

echo ""
echo "3. 检查应用是否在运行："
ps aux | grep -E "抖音|汽水" | grep -v grep

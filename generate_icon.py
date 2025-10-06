#!/usr/bin/env python3
"""
生成 iDict 应用图标的脚本
使用 SF Symbols 的翻译图标生成不同尺寸的图标文件
"""

import os
import subprocess
import sys

def generate_icon(size, output_path):
    """使用 SF Symbols 生成指定尺寸的图标"""
    try:
        # 使用 sips 命令生成图标
        cmd = [
            'sips', '-s', 'format', 'png',
            '--resampleHeightWidth', str(size), str(size),
            '--out', output_path,
            '/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns'
        ]
        
        # 创建一个临时的 SF Symbol 图标
        temp_icon = f'/tmp/translate_icon_{size}.png'
        
        # 使用 SF Symbols 生成翻译图标
        swift_code = f'''
import AppKit
let config = NSImage.SymbolConfiguration(pointSize: {size/2}, weight: .medium)
let image = NSImage(systemSymbolName: "translate", accessibilityDescription: "Translate")
image?.size = NSSize(width: {size}, height: {size})
if let tiffData = image?.tiffRepresentation,
   let bitmapRep = NSBitmapImageRep(data: tiffData),
   let pngData = bitmapRep.representation(using: .png, properties: [:]) {{
    try pngData.write(to: URL(fileURLWithPath: "{output_path}"))
}}
'''
        
        symbol_cmd = ['swift', '-c', swift_code]
        
        result = subprocess.run(symbol_cmd, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ 生成 {size}x{size} 图标成功: {output_path}")
            return True
        else:
            print(f"❌ 生成 {size}x{size} 图标失败: {result.stderr}")
            return False
            
    except Exception as e:
        print(f"❌ 生成图标时出错: {e}")
        return False

def main():
    """主函数"""
    print("🎨 开始生成 iDict 应用图标...")
    
    # 图标尺寸列表
    sizes = [32, 64, 128, 256, 512, 1024]
    
    # 创建输出目录
    output_dir = "iDict/Assets.xcassets/AppIcon.appiconset"
    os.makedirs(output_dir, exist_ok=True)
    
    success_count = 0
    
    for size in sizes:
        # 生成标准尺寸
        output_path = f"{output_dir}/icon_{size}x{size}.png"
        if generate_icon(size, output_path):
            success_count += 1
        
        # 生成 @2x 尺寸（除了 1024）
        if size != 1024:
            output_path_2x = f"{output_dir}/icon_{size}x{size}@2x.png"
            if generate_icon(size * 2, output_path_2x):
                success_count += 1
    
    print(f"\n🎉 图标生成完成！成功生成 {success_count} 个图标文件")
    print("📁 图标文件保存在: iDict/Assets.xcassets/AppIcon.appiconset/")

if __name__ == "__main__":
    main()

#!/usr/bin/env swift

import AppKit

// 正确的图标尺寸映射
let iconSizes = [
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
    "icon_1024x1024.png": 1024
]

let outputDir = "iDict/Assets.xcassets/AppIcon.appiconset"

print("🔧 修复图标尺寸...")

for (filename, size) in iconSizes {
    let outputPath = "\(outputDir)/\(filename)"
    
    // 创建翻译图标
    guard let image = NSImage(systemSymbolName: "translate", accessibilityDescription: "Translate") else {
        print("❌ 无法创建翻译图标")
        continue
    }
    
    // 设置正确的图标尺寸
    image.size = NSSize(width: size, height: size)
    
    // 创建位图表示
    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("❌ 无法转换图标为 PNG 格式")
        continue
    }
    
    // 写入文件
    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("✅ 修复 \(filename) (\(size)x\(size))")
    } catch {
        print("❌ 写入文件失败: \(error)")
    }
}

print("🎉 图标尺寸修复完成！")

#!/usr/bin/env swift

import AppKit

// 图标尺寸列表
let sizes = [32, 64, 128, 256, 512, 1024]

// 创建输出目录
let outputDir = "iDict/Assets.xcassets/AppIcon.appiconset"
let fileManager = FileManager.default

do {
    try fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true, attributes: nil)
} catch {
    print("❌ 创建目录失败: \(error)")
    exit(1)
}

print("🎨 开始生成 iDict 应用图标...")

var successCount = 0

for size in sizes {
    // 生成标准尺寸
    let outputPath = "\(outputDir)/icon_\(size)x\(size).png"
    if generateIcon(size: size, outputPath: outputPath) {
        successCount += 1
    }
    
    // 生成 @2x 尺寸（除了 1024）
    if size != 1024 {
        let outputPath2x = "\(outputDir)/icon_\(size)x\(size)@2x.png"
        if generateIcon(size: size * 2, outputPath: outputPath2x) {
            successCount += 1
        }
    }
}

print("\n🎉 图标生成完成！成功生成 \(successCount) 个图标文件")
print("📁 图标文件保存在: \(outputDir)/")

func generateIcon(size: Int, outputPath: String) -> Bool {
    // 创建翻译图标
    guard let image = NSImage(systemSymbolName: "translate", accessibilityDescription: "Translate") else {
        print("❌ 无法创建翻译图标")
        return false
    }
    
    // 设置图标尺寸
    image.size = NSSize(width: size, height: size)
    
    // 创建位图表示
    guard let tiffData = image.tiffRepresentation,
          let bitmapRep = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("❌ 无法转换图标为 PNG 格式")
        return false
    }
    
    // 写入文件
    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("✅ 生成 \(size)x\(size) 图标成功: \(outputPath)")
        return true
    } catch {
        print("❌ 写入文件失败: \(error)")
        return false
    }
}

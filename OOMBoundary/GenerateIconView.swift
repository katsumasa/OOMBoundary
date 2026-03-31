//
//  GenerateIconView.swift
//  OOMBoundary
//
//  Created by Katsumasa Kimura on 2026/03/31.
//

import SwiftUI

struct GenerateIconView: View {
    @State private var iconGenerated = false
    @State private var message = "Tap to generate icon"

    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Generator")
                .font(.title)
                .fontWeight(.bold)

            if let icon = IconGenerator.generateAppIcon() {
                Image(uiImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .cornerRadius(44.8) // iOS app icon corner radius
                    .shadow(radius: 10)
            }

            Text(message)
                .foregroundColor(iconGenerated ? .green : .primary)
                .padding()

            Button(action: generateAndSaveIcon) {
                Label("Generate Icon", systemImage: "photo.badge.plus")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            if iconGenerated {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Next steps:")
                        .font(.headline)

                    Text("1. Icon saved to Documents folder")
                    Text("2. Open Files app on your device")
                    Text("3. Navigate to OOMBoundary folder")
                    Text("4. Copy AppIcon.png")
                    Text("5. Add to Assets.xcassets in Xcode")
                }
                .font(.caption)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
        .padding()
    }

    private func generateAndSaveIcon() {
        guard let icon = IconGenerator.generateAppIcon() else {
            message = "Failed to generate icon"
            return
        }

        // DocumentsディレクトリのパスでPNG画像を保存
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let iconPath = documentsPath.appendingPathComponent("AppIcon.png")

        if IconGenerator.saveIcon(image: icon, at: iconPath.path) {
            iconGenerated = true
            message = "Icon saved to:\n\(iconPath.path)"
            print("Icon saved successfully to: \(iconPath.path)")

            // 複数サイズを生成
            generateMultipleSizes(baseIcon: icon, basePath: documentsPath)
        } else {
            message = "Failed to save icon"
        }
    }

    private func generateMultipleSizes(baseIcon: UIImage, basePath: URL) {
        let sizes: [(String, CGFloat)] = [
            ("AppIcon-1024", 1024),
            ("AppIcon-180", 180),
            ("AppIcon-167", 167),
            ("AppIcon-152", 152),
            ("AppIcon-120", 120),
            ("AppIcon-87", 87),
            ("AppIcon-80", 80),
            ("AppIcon-76", 76),
            ("AppIcon-60", 60),
            ("AppIcon-58", 58),
            ("AppIcon-40", 40),
            ("AppIcon-29", 29),
            ("AppIcon-20", 20)
        ]

        for (name, size) in sizes {
            if let resized = resizeImage(image: baseIcon, targetSize: CGSize(width: size, height: size)) {
                let path = basePath.appendingPathComponent("\(name).png")
                _ = IconGenerator.saveIcon(image: resized, at: path.path)
            }
        }
    }

    private func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}

#Preview {
    GenerateIconView()
}

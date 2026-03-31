//
//  IconGenerator.swift
//  OOMBoundary
//
//  Created by Katsumasa Kimura on 2026/03/31.
//

import SwiftUI
import UIKit

struct IconGenerator {
    static func generateAppIcon() -> UIImage? {
        let size: CGFloat = 1024
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))

        let image = renderer.image { context in
            // グラデーション背景（メモリ/テクノロジー感）
            let colors = [
                UIColor(red: 0.2, green: 0.3, blue: 0.8, alpha: 1.0).cgColor,  // 深い青
                UIColor(red: 0.5, green: 0.1, blue: 0.7, alpha: 1.0).cgColor   // 紫
            ]

            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray,
                                     locations: [0.0, 1.0])!

            context.cgContext.drawLinearGradient(gradient,
                                                 start: CGPoint(x: 0, y: 0),
                                                 end: CGPoint(x: size, y: size),
                                                 options: [])

            // メモリチップのイメージ（長方形と線）
            context.cgContext.setStrokeColor(UIColor.white.cgColor)
            context.cgContext.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
            context.cgContext.setLineWidth(12)

            // メインのメモリチップ本体
            let chipRect = CGRect(x: size * 0.25, y: size * 0.3, width: size * 0.5, height: size * 0.4)
            let chipPath = UIBezierPath(roundedRect: chipRect, cornerRadius: 30)
            context.cgContext.addPath(chipPath.cgPath)
            context.cgContext.fillPath()

            context.cgContext.addPath(chipPath.cgPath)
            context.cgContext.strokePath()

            // メモリの線（横線3本）
            for i in 0..<3 {
                let y = chipRect.minY + chipRect.height * (CGFloat(i + 1) / 4.0)
                let lineStartX = chipRect.minX + 40
                let lineEndX = chipRect.maxX - 40

                context.cgContext.move(to: CGPoint(x: lineStartX, y: y))
                context.cgContext.addLine(to: CGPoint(x: lineEndX, y: y))
                context.cgContext.setLineWidth(8)
                context.cgContext.strokePath()
            }

            // ピン（左右に小さな長方形）
            context.cgContext.setFillColor(UIColor.white.cgColor)

            // 左側のピン
            for i in 0..<4 {
                let pinY = chipRect.minY + chipRect.height * (CGFloat(i) / 3.0) - 10
                let leftPin = CGRect(x: chipRect.minX - 30, y: pinY, width: 25, height: 20)
                let leftPinPath = UIBezierPath(roundedRect: leftPin, cornerRadius: 3)
                context.cgContext.addPath(leftPinPath.cgPath)
                context.cgContext.fillPath()

                // 右側のピン
                let rightPin = CGRect(x: chipRect.maxX + 5, y: pinY, width: 25, height: 20)
                let rightPinPath = UIBezierPath(roundedRect: rightPin, cornerRadius: 3)
                context.cgContext.addPath(rightPinPath.cgPath)
                context.cgContext.fillPath()
            }

            // "OOM" テキスト
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 120, weight: .bold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]

            let text = "OOM"
            let textRect = CGRect(x: 0, y: size * 0.75, width: size, height: 150)
            text.draw(in: textRect, withAttributes: attributes)

            // 警告マーク（小さな三角形）
            context.cgContext.setFillColor(UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0).cgColor)

            let warningSize: CGFloat = 80
            let warningX = size * 0.78
            let warningY = size * 0.18

            let warningPath = UIBezierPath()
            warningPath.move(to: CGPoint(x: warningX, y: warningY))
            warningPath.addLine(to: CGPoint(x: warningX - warningSize/2, y: warningY + warningSize))
            warningPath.addLine(to: CGPoint(x: warningX + warningSize/2, y: warningY + warningSize))
            warningPath.close()

            context.cgContext.addPath(warningPath.cgPath)
            context.cgContext.fillPath()

            // 警告マークの"!"
            let exclamationAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 50, weight: .bold),
                .foregroundColor: UIColor.black
            ]

            let exclamation = "!"
            let exclamationRect = CGRect(x: warningX - 15, y: warningY + 10, width: 30, height: 60)
            exclamation.draw(in: exclamationRect, withAttributes: exclamationAttributes)
        }

        return image
    }

    static func saveIcon(image: UIImage, at path: String) -> Bool {
        guard let data = image.pngData() else { return false }
        let url = URL(fileURLWithPath: path)
        do {
            try data.write(to: url)
            return true
        } catch {
            print("Failed to save icon: \(error)")
            return false
        }
    }
}

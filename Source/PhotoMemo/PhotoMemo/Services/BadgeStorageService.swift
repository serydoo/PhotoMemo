//
//  BadgeStorageService.swift
//  PhotoMemo
//
//  Created by MemoMark on 2026/6/17.
//


import Foundation

final class BadgeStorageService {

    private let folderName = "Badges"

    func savePNG(
        data: Data,
        fileName: String
    ) throws -> CustomBadge {

        let folder = try badgeFolderURL()

        let fileURL =
            folder.appendingPathComponent(
                fileName
            )

        try data.write(
            to: fileURL,
            options: .atomic
        )

        return CustomBadge(
            name: fileURL.deletingPathExtension().lastPathComponent,
            fileName: fileURL.lastPathComponent,
            filePath: fileURL.path
        )
    }

    func loadCustomBadges() -> [CustomBadge] {

        guard
            let folder =
                try? badgeFolderURL()
        else {
            return []
        }

        guard
            let files =
                try? FileManager.default.contentsOfDirectory(
                    at: folder,
                    includingPropertiesForKeys: nil
                )
        else {
            return []
        }

        return files
            .filter {
                $0.pathExtension.lowercased() == "png"
            }
            .map {

                CustomBadge(
                    name: $0.deletingPathExtension().lastPathComponent,
                    fileName: $0.lastPathComponent,
                    filePath: $0.path
                )
            }
    }

    func delete(
        badge: CustomBadge
    ) throws {

        try FileManager.default.removeItem(
            atPath: badge.filePath
        )
    }
}

private extension BadgeStorageService {

    func badgeFolderURL() throws -> URL {

        let appSupport =
            try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )

        let folder =
            appSupport.appendingPathComponent(
                folderName
            )

        if !FileManager.default.fileExists(
            atPath: folder.path
        ) {

            try FileManager.default.createDirectory(
                at: folder,
                withIntermediateDirectories: true
            )
        }

        return folder
    }
}

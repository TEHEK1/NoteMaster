//
//  FileManagerService.swift
//  MVC2
//
//  Created by Amir Kashapov on 11.12.2025.
//

import UIKit

final class FileManagerService {
    
    static let shared = FileManagerService()
    
    private init() {
        createImagesDirectoryIfNeeded()
    }
    
    private enum Constants {
        static let imagesDirectoryName = "Images"
        static let imageExtension = "jpg"
        static let compressionQuality: CGFloat = 0.8
    }
    
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var imagesDirectory: URL {
        documentsDirectory.appendingPathComponent(Constants.imagesDirectoryName)
    }
    
    func saveImage(_ image: UIImage) -> String? {
        let fileName = "\(UUID().uuidString).\(Constants.imageExtension)"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: Constants.compressionQuality) else {
            print("Failed to convert image to data")
            return nil
        }
        
        do {
            try data.write(to: fileURL)
            return "\(Constants.imagesDirectoryName)/\(fileName)"
        } catch {
            print("Failed to save image: \(error)")
            return nil
        }
    }
    
    func saveImages(_ images: [UIImage]) -> [String] {
        images.compactMap { saveImage($0) }
    }
    
    func loadImage(at relativePath: String) -> UIImage? {
        let url = documentsDirectory.appendingPathComponent(relativePath)
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        return UIImage(contentsOfFile: url.path)
    }
    
    func loadImages(from paths: [String]) -> [UIImage] {
        paths.compactMap { loadImage(at: $0) }
    }
    
    func deleteImage(at relativePath: String) {
        let url = documentsDirectory.appendingPathComponent(relativePath)
        do {
            try fileManager.removeItem(at: url)
        } catch {
            print("Failed to delete image: \(error)")
        }
    }

    func deleteImages(from paths: [String]) {
        paths.forEach { deleteImage(at: $0) }
    }

    func fullURL(for relativePath: String) -> URL {
        documentsDirectory.appendingPathComponent(relativePath)
    }
    
    private func createImagesDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: imagesDirectory.path) {
            do {
                try fileManager.createDirectory(at: imagesDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create images directory: \(error)")
            }
        }
    }
}


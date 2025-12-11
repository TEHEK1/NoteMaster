//
//  CoreDataManager.swift
//  MVC2
//
//  Created by Amir Kashapov on 11.12.2025.
//

import CoreData
import UIKit

final class CoreDataManager {

    static let shared = CoreDataManager()
    
    private let fileManagerService = FileManagerService.shared
    private init() {}

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Note")
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    @discardableResult
    func createNote(title: String, content: String?, category: String?) -> Note {
        let note = Note(context: context)
        note.id = UUID()
        note.title = title
        note.content = content
        note.category = category
        note.createdDate = Date()
        note.modifiedDate = Date()
        
        saveContext()
        return note
    }
    
    func fetchNotes() -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "modifiedDate", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching notes: \(error)")
            return []
        }
    }
    
    func fetchNote(byId id: UUID) -> Note? {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching note by id: \(error)")
            return nil
        }
    }
    
    func updateNote(_ note: Note, title: String, content: String?, category: String?) {
        note.title = title
        note.content = content
        note.category = category
        note.modifiedDate = Date()
        
        saveContext()
    }
    
    func deleteNote(_ note: Note) {
        if let images = note.images as? Set<NoteImage> {
            for image in images {
                if let path = image.imagePath {
                    fileManagerService.deleteImage(at: path)
                }
                context.delete(image)
            }
        }
        context.delete(note)
        saveContext()
    }
    
    func deleteNote(id: UUID) {
        guard let note = fetchNote(byId: id) else { return }
        deleteNote(note)
    }
    
    @discardableResult
    func addImage(to note: Note, imagePath: String, orderIndex: Int32 = 0) -> NoteImage {
        let noteImage = NoteImage(context: context)
        noteImage.id = UUID()
        noteImage.imagePath = imagePath
        noteImage.orderIndex = orderIndex
        noteImage.note = note
        
        note.modifiedDate = Date()
        
        saveContext()
        return noteImage
    }
    
    func fetchImages(for note: Note) -> [NoteImage] {
        guard let images = note.images as? Set<NoteImage> else { return [] }
        return images.sorted { $0.orderIndex < $1.orderIndex }
    }
    
    func deleteImage(_ noteImage: NoteImage) {
        if let note = noteImage.note {
            note.modifiedDate = Date()
        }
        if let path = noteImage.imagePath {
            fileManagerService.deleteImage(at: path)
        }
        context.delete(noteImage)
        saveContext()
    }
    
    func deleteAllImages(for note: Note) {
        guard let images = note.images as? Set<NoteImage> else { return }
        for image in images {
            if let path = image.imagePath {
                fileManagerService.deleteImage(at: path)
            }
            context.delete(image)
        }
        note.modifiedDate = Date()
        saveContext()
    }

    func deleteImages(for note: Note, paths: [String]) {
        guard !paths.isEmpty else { return }
        let images = fetchImages(for: note)
        for image in images where paths.contains(image.imagePath ?? "") {
            if let path = image.imagePath {
                fileManagerService.deleteImage(at: path)
            }
            context.delete(image)
        }
        note.modifiedDate = Date()
        saveContext()
    }

    func searchNotes(query: String) -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR content CONTAINS[cd] %@", query, query)
        request.sortDescriptors = [NSSortDescriptor(key: "modifiedDate", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error searching notes: \(error)")
            return []
        }
    }

    func fetchNotes(byCategory category: String) -> [Note] {
        let request: NSFetchRequest<Note> = Note.fetchRequest()
        request.predicate = NSPredicate(format: "category == %@", category)
        request.sortDescriptors = [NSSortDescriptor(key: "modifiedDate", ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching notes by category: \(error)")
            return []
        }
    }

    func fetchCategories() -> [String] {
        let notes = fetchNotes()
        let categories = Set(notes.compactMap { $0.category })
        return Array(categories).sorted()
    }
}

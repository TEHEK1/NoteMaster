//
//  NotesListViewController.swift
//  MVC2
//
//  Created by Amir Kashapov on 11.12.2025.
//

import UIKit

final class NotesListViewController: UIViewController {

    private let coreDataManager = CoreDataManager.shared
    private var notes: [Note] = []
    private var selectedCategory: String?
    private let searchController = UISearchController(searchResultsController: nil)

    private lazy var tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.delegate = self
        table.dataSource = self
        table.register(NoteCell.self, forCellReuseIdentifier: NoteCell.identifier)
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 100
        return table
    }()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Нет заметок\nНажмите + чтобы создать"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupSearch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadNotes()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        title = "Заметки"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addNoteTapped)),
            UIBarButtonItem(title: "Категория", style: .plain, target: self, action: #selector(categoryTapped))
        ]
    }

    private func loadNotes() {
        applyFilters(searchText: searchController.searchBar.text)
    }
    
    private func updateEmptyState() {
        emptyStateLabel.isHidden = !notes.isEmpty
        tableView.isHidden = notes.isEmpty
    }

    @objc private func addNoteTapped() {
        let editorVC = NoteEditorViewController()
        navigationController?.pushViewController(editorVC, animated: true)
    }
    
    private func deleteNote(at indexPath: IndexPath) {
        let note = notes[indexPath.row]
        coreDataManager.deleteNote(note)
        applyFilters(searchText: searchController.searchBar.text)
    }
    
    private func setupSearch() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Поиск по заголовку и тексту"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    private func applyFilters(searchText: String?) {
        notes = coreDataManager.fetchNotes(
            search: searchText,
            category: selectedCategory
        )
        tableView.reloadData()
        updateEmptyState()
    }
    
    @objc private func categoryTapped() {
        let categories = coreDataManager.fetchCategories()
        let alert = UIAlertController(title: "Категория", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Все", style: .default) { [weak self] _ in
            self?.selectedCategory = nil
            self?.applyFilters(searchText: self?.searchController.searchBar.text)
        })
        
        for category in categories {
            alert.addAction(UIAlertAction(title: category, style: .default) { [weak self] _ in
                self?.selectedCategory = category
                self?.applyFilters(searchText: self?.searchController.searchBar.text)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
}

extension NotesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return notes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoteCell.identifier, for: indexPath) as? NoteCell else {
            return UITableViewCell()
        }
        
        let note = notes[indexPath.row]
        cell.configure(with: note)
        
        return cell
    }
}

extension NotesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let note = notes[indexPath.row]
        let editorVC = NoteEditorViewController(note: note)
        navigationController?.pushViewController(editorVC, animated: true)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Удалить") { [weak self] _, _, completion in
            self?.deleteNote(at: indexPath)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension NotesListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        applyFilters(searchText: searchController.searchBar.text)
    }
}

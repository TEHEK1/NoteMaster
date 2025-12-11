//
//  NoteEditorViewController.swift
//  MVC2
//
//  Created by Amir Kashapov on 11.12.2025.
//

import UIKit

final class NoteEditorViewController: UIViewController {

    private var note: Note?
    private let coreDataManager = CoreDataManager.shared

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .interactive
        return scroll
    }()
    
    private lazy var contentStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 16
        return stack
    }()
    
    private lazy var titleTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Заголовок"
        field.font = .systemFont(ofSize: 24, weight: .bold)
        field.borderStyle = .none
        return field
    }()
    
    private lazy var categoryTextField: UITextField = {
        let field = UITextField()
        field.placeholder = "Категория (опционально)"
        field.font = .systemFont(ofSize: 16)
        field.borderStyle = .roundedRect
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private lazy var contentTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 17)
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }()
    
    private lazy var contentPlaceholder: UILabel = {
        let label = UILabel()
        label.text = "Введите текст заметки..."
        label.font = .systemFont(ofSize: 17)
        label.textColor = .placeholderText
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(note: Note? = nil) {
        self.note = note
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupKeyboardObservers()
        configureWithNote()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        contentStack.addArrangedSubview(titleTextField)
        contentStack.addArrangedSubview(categoryTextField)
        contentStack.addArrangedSubview(contentTextView)
        
        contentTextView.addSubview(contentPlaceholder)
        contentTextView.delegate = self
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            
            contentTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150),
            
            contentPlaceholder.topAnchor.constraint(equalTo: contentTextView.topAnchor),
            contentPlaceholder.leadingAnchor.constraint(equalTo: contentTextView.leadingAnchor)
        ])
    }
    
    private func setupNavigationBar() {
        title = note == nil ? "Новая заметка" : "Редактирование"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self,
            action: #selector(saveTapped)
        )
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func configureWithNote() {
        guard let note = note else { return }
        
        titleTextField.text = note.title
        contentTextView.text = note.content
        categoryTextField.text = note.category
        contentPlaceholder.isHidden = !(note.content?.isEmpty ?? true)
    }

    @objc private func saveTapped() {
        guard let title = titleTextField.text, !title.isEmpty else {
            showError("Введите заголовок заметки")
            return
        }
        
        let content = contentTextView.text
        let category = categoryTextField.text?.isEmpty == true ? nil : categoryTextField.text
        
        if let existingNote = note {
            coreDataManager.updateNote(existingNote, title: title, content: content, category: category)
        } else {
            coreDataManager.createNote(title: title, content: content, category: category)
        }
        
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        scrollView.contentInset.bottom = keyboardFrame.height
        scrollView.verticalScrollIndicatorInsets.bottom = keyboardFrame.height
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension NoteEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        contentPlaceholder.isHidden = !textView.text.isEmpty
    }
}
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
    private var selectedImages: [UIImage] = []

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
    
    private lazy var addImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Добавить фото", for: .normal)
        button.setImage(UIImage(systemName: "photo.badge.plus"), for: .normal)
        button.tintColor = .systemBlue
        button.contentHorizontalAlignment = .leading
        button.addTarget(self, action: #selector(addImageTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var imagesScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.isHidden = true
        return scroll
    }()
    
    private lazy var imagesStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillProportionally
        return stack
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
        contentStack.addArrangedSubview(addImageButton)
        contentStack.addArrangedSubview(imagesScrollView)
        
        contentTextView.addSubview(contentPlaceholder)
        contentTextView.delegate = self
        imagesScrollView.addSubview(imagesStackView)
        
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
            imagesScrollView.heightAnchor.constraint(equalToConstant: 140),
            
            contentPlaceholder.topAnchor.constraint(equalTo: contentTextView.topAnchor),
            contentPlaceholder.leadingAnchor.constraint(equalTo: contentTextView.leadingAnchor),
            
            imagesStackView.topAnchor.constraint(equalTo: imagesScrollView.topAnchor),
            imagesStackView.leadingAnchor.constraint(equalTo: imagesScrollView.leadingAnchor),
            imagesStackView.trailingAnchor.constraint(equalTo: imagesScrollView.trailingAnchor),
            imagesStackView.bottomAnchor.constraint(equalTo: imagesScrollView.bottomAnchor),
            imagesStackView.heightAnchor.constraint(equalTo: imagesScrollView.heightAnchor)
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
        updateImagesStackView()
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
    
    private func updateImagesStackView() {
        imagesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, image) in selectedImages.enumerated() {
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            imageView.isUserInteractionEnabled = true
            imageView.tag = index
            
            imageView.widthAnchor.constraint(equalToConstant: 140).isActive = true
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            imageView.addGestureRecognizer(tap)
            
            imagesStackView.addArrangedSubview(imageView)
        }
        
        imagesScrollView.isHidden = selectedImages.isEmpty
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc private func addImageTapped() {
        let alert = UIAlertController(title: "Добавить фото", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(title: "Камера", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            })
        }
        
        alert.addAction(UIAlertAction(title: "Галерея", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        picker.sourceType = sourceType
        present(picker, animated: true)
    }
    
    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView else { return }
        let index = imageView.tag
        
        let alert = UIAlertController(title: "Изображение", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.selectedImages.remove(at: index)
            self?.updateImagesStackView()
        })
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        present(alert, animated: true)
    }
}

extension NoteEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        contentPlaceholder.isHidden = !textView.text.isEmpty
    }
}

extension NoteEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let editedImage = info[.editedImage] as? UIImage {
            selectedImages.append(editedImage)
        } else if let originalImage = info[.originalImage] as? UIImage {
            selectedImages.append(originalImage)
        }
        
        updateImagesStackView()
    }
}
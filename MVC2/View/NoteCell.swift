//
//  NoteCell.swift
//  MVC2
//
//  Created by Amir Kashapov on 11.12.2025.
//

import UIKit

final class NoteCell: UITableViewCell {
    
    static let identifier = "NoteCell"

    private lazy var containerStack: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    private lazy var contentPreviewLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var metaStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        return stack
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .tertiaryLabel
        return label
    }()
    
    private lazy var categoryLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        label.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        accessoryType = .disclosureIndicator
        
        contentView.addSubview(containerStack)
        
        containerStack.addArrangedSubview(titleLabel)
        containerStack.addArrangedSubview(contentPreviewLabel)
        containerStack.addArrangedSubview(metaStack)
        
        metaStack.addArrangedSubview(dateLabel)
        metaStack.addArrangedSubview(categoryLabel)
        metaStack.addArrangedSubview(UIView()) // Spacer
        
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            containerStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            containerStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with note: Note) {
        titleLabel.text = note.title
        contentPreviewLabel.text = note.content ?? "Нет содержимого"

        if let date = note.modifiedDate ?? note.createdDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            dateLabel.text = formatter.string(from: date)
        } else {
            dateLabel.text = nil
        }

        if let category = note.category, !category.isEmpty {
            categoryLabel.text = "  \(category)  "
            categoryLabel.isHidden = false
        } else {
            categoryLabel.isHidden = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        contentPreviewLabel.text = nil
        dateLabel.text = nil
        categoryLabel.text = nil
        categoryLabel.isHidden = true
    }
}
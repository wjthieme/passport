//
//  DisplayController.swift
//  PassportScanner
//
//  Created by Wilhelm Thieme on 07/07/2020.
//  Copyright © 2020 Sogeti Nederland B.V. All rights reserved.
//

import UIKit

class DisplayController: UIViewController {
    
    private let backButton = UIButton()
    private let backgroundView = UIView()
    private let nameLabel = UILabel()
    private let ageLabel = UILabel()
    private let imageView = UIImageView()
    private let signatureView = UIView()
    
    var dismissAction: (() -> Void)?
    
    init(name: String, dob: String, image: UIImage) {
        super.init(nibName: nil, bundle: nil)
        
        let formatter = DateFormatter()
        
        nameLabel.text = name
        ageLabel.text = dob
        imageView.image = image
        
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .coverVertical
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(didPressBack), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        backButton.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        backButton.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        backButton.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        backgroundView.backgroundColor = UIColor.systemBackground
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.layer.cornerRadius = 18
        view.addSubview(backgroundView)
        backgroundView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 18).isActive = true
        backgroundView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -18).isActive = true
        backgroundView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18).isActive = true
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 4
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFit
        backgroundView.addSubview(imageView)
        imageView.widthAnchor.constraint(equalTo: backgroundView.widthAnchor, multiplier: 0.45).isActive = true
        imageView.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 18).isActive = true
        imageView.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 18).isActive = true
        imageView.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -18).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.2857).isActive = true
        
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.numberOfLines = 0
        backgroundView.addSubview(nameLabel)
        nameLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 18).isActive = true
        nameLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -18).isActive = true
        nameLabel.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 18).isActive = true
        nameLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        ageLabel.translatesAutoresizingMaskIntoConstraints = false
        ageLabel.numberOfLines = 0
        backgroundView.addSubview(ageLabel)
        ageLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 18).isActive = true
        ageLabel.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -18).isActive = true
        ageLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 18).isActive = true
        ageLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        
        signatureView.translatesAutoresizingMaskIntoConstraints = false
        signatureView.contentMode = .scaleAspectFit
        backgroundView.addSubview(signatureView)
        signatureView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 18).isActive = true
        signatureView.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -18).isActive = true
        signatureView.topAnchor.constraint(equalTo: ageLabel.bottomAnchor, constant: 18).isActive = true
        signatureView.topAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -18).isActive = true
        
        
        
//        ageLabel.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -18).isActive = true
        
    }
    
    @objc private func didPressBack() {
        dismiss(animated: true, completion: nil)
        dismissAction?()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

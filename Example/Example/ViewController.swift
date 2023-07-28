//
//  ViewController.swift
//  Example
//
//  Created by 陈卓 on 2023/7/28.
//

import UIKit
import ThenDynamicLaunch

class ViewController: UIViewController {
    
    lazy var modifyButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle("修改", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.backgroundColor = UIColor.orange
        button.layer.cornerRadius = 10
        button.addTarget(self, action: #selector(modifyClick), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        view.addSubview(modifyButton)
        
        NSLayoutConstraint.activate([
            modifyButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            modifyButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            modifyButton.widthAnchor.constraint(equalToConstant: 120),
            modifyButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    @objc func modifyClick() {
        let controller = UIAlertController(title: "选择", message: nil, preferredStyle: .actionSheet)
        controller.addAction(UIAlertAction(title: "Portrait light", style: .destructive, handler: { _ in
            ThenDynamicLaunch.shared.replace(with: UIImage(named: "pexels-1"), direction: .portraitLight)
        }))
        controller.addAction(UIAlertAction(title: "Portrait dark", style: .destructive, handler: { _ in
            ThenDynamicLaunch.shared.replace(with: UIImage(named: "pexels-2"), direction: .portraitDark)
        }))
        controller.addAction(UIAlertAction(title: "Landscape light", style: .destructive, handler: { _ in
            ThenDynamicLaunch.shared.replace(with: UIImage(named: "pexels-1"), direction: .landscapeLight)
        }))
        controller.addAction(UIAlertAction(title: "Landscape dark", style: .destructive, handler: { _ in
            ThenDynamicLaunch.shared.replace(with: UIImage(named: "pexels-2"), direction: .landscapeDark)
        }))
        controller.addAction(UIAlertAction(title: "cancel", style: .cancel))
        self.present(controller, animated: true)
    }
        
}





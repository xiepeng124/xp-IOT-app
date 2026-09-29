//
//  AnimationListViewController.swift
//  newStudy
//
//  Created by Assistant on 2026/4/17.
//

import UIKit

class AnimationListViewController: UIViewController {
    
    private let demoView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemOrange
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let tableView = UITableView()
    private let animations = [
        "抖动动画 (Shake)",
        "呼吸灯 (Breathing)",
        "3D 翻转 (Flip)",
        "缩放弹出 (Pop)",
        "持续旋转 (Rotate)",
        "停止动画 (Stop)"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "常用动画库"
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(demoView)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            demoView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            demoView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            demoView.widthAnchor.constraint(equalToConstant: 100),
            demoView.heightAnchor.constraint(equalToConstant: 100),
            
            tableView.topAnchor.constraint(equalTo: demoView.bottomAnchor, constant: 40),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension AnimationListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return animations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = animations[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            demoView.shake()
        case 1:
            demoView.breathing()
        case 2:
            demoView.flip()
        case 3:
            demoView.pop()
        case 4:
            demoView.rotate()
        case 5:
            demoView.stopAnimations()
            demoView.alpha = 1.0
        default:
            break
        }
    }
}

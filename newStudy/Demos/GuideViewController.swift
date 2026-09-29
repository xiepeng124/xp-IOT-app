//
//  GuideViewController.swift
//  newStudy
//
//  Created by Assistant on 2026/5/3.
//

import UIKit

class GuideViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    private let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    private var viewControllers = [UIViewController]()
    
    private let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("跳过", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(.systemGray, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let pageControl: UIPageControl = {
        let pc = UIPageControl()
        pc.currentPageIndicatorTintColor = .systemBlue
        pc.pageIndicatorTintColor = .systemGray4
        pc.translatesAutoresizingMaskIntoConstraints = false
        return pc
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("开始使用", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGuidePages()
        setupUI()
    }
    
    private func setupGuidePages() {
        let pages = [
            GuidePage(image: nil, title: "欢迎使用", subtitle: "探索新学习的强大功能", color: .systemBlue),
            GuidePage(image: nil, title: "抖音加载动画", subtitle: "酷炫的 UI 动效体验", color: .systemRed),
            GuidePage(image: nil, title: "美颜相机", subtitle: "支持贴纸、水印和一键拍照", color: .systemGreen),
            GuidePage(image: nil, title: "MQTT 调试", subtitle: "强大的 IoT 连接能力", color: .systemPurple)
        ]
        
        for (index, page) in pages.enumerated() {
            let vc = GuidePageContentViewController(page: page, index: index)
            viewControllers.append(vc)
        }
        
        pageViewController.setViewControllers([viewControllers.first!], direction: .forward, animated: true)
        pageViewController.dataSource = self
        pageViewController.delegate = self
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.didMove(toParent: self)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(skipButton)
        view.addSubview(pageControl)
        view.addSubview(startButton)
        
        pageControl.numberOfPages = viewControllers.count
        
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            skipButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.widthAnchor.constraint(equalToConstant: 200),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        startButton.alpha = 0
        startButton.addTarget(self, action: #selector(startUsingApp), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(startUsingApp), for: .touchUpInside)
    }
    
    @objc private func startUsingApp() {
        UserDefaults.standard.set(true, forKey: "kFirstLaunchCompleted")
        UserDefaults.standard.synchronize()
        dismiss(animated: true)
    }
    
    // MARK: - UIPageViewController DataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = (viewController as? GuidePageContentViewController)?.index, index > 0 else { return nil }
        return viewControllers[index - 1]
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = (viewController as? GuidePageContentViewController)?.index, index < viewControllers.count - 1 else { return nil }
        return viewControllers[index + 1]
    }
    
    // MARK: - UIPageViewController Delegate
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        guard completed, let vc = pageViewController.viewControllers?.first as? GuidePageContentViewController else { return }
        pageControl.currentPage = vc.index
        
        let isLastPage = vc.index == viewControllers.count - 1
        UIView.animate(withDuration: 0.3) {
            self.skipButton.alpha = isLastPage ? 0 : 1
            self.startButton.alpha = isLastPage ? 1 : 0
        }
    }
}

// MARK: - Guide Page Data Structure
struct GuidePage {
    let image: UIImage?
    let title: String
    let subtitle: String
    let color: UIColor
}

// MARK: - Single Page Content VC
class GuidePageContentViewController: UIViewController {
    let page: GuidePage
    let index: Int
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let circleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 100
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    init(page: GuidePage, index: Int) {
        self.page = page
        self.index = index
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupUI()
    }
    
    private func setupUI() {
        circleView.backgroundColor = page.color
        
        titleLabel.text = page.title
        subtitleLabel.text = page.subtitle
        
        view.addSubview(circleView)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            circleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circleView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            circleView.widthAnchor.constraint(equalToConstant: 200),
            circleView.heightAnchor.constraint(equalToConstant: 200),
            
            titleLabel.topAnchor.constraint(equalTo: circleView.bottomAnchor, constant: 40),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 15),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30)
        ])
    }
}

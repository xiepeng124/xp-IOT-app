//
//  HomeViewController.swift
//  newStudy
//
//  Created by ma c on 2026/4/16.
//

import UIKit

class HomeViewController: UIViewController {

    private let tableView = UITableView()
    private let items = [
        "抖音加载动画展示",
        "常用动画库展示",
        "复杂曲线路径动画",
        "三角函数水波动画",
        "高级相机 (美颜/贴纸/水印)",
        "手写签名",
        "NFC",
        "蓝牙",
        "MQTT 消息调试",
        "PCM音频播放",
        "录音及变声",
        "K线图",
        "扫一扫",
        "关于新学习"
    ]
    
    private let guideSeenKey = "kHomeFeatureGuideSeen_v2"
    
    private var hasSeenGuide: Bool {
        get {
            return UserDefaults.standard.bool(forKey: guideSeenKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: guideSeenKey)
            UserDefaults.standard.synchronize()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        // 创建一个自定义串行队列
//        let serialQueue = DispatchQueue(label: "com.example.mySerialQueue")
//
//        // 异步提交任务（在后台按顺序执行，不阻塞主线程）
//        serialQueue.async {
//            print("任务 1 开始并执行完毕")
//            serialQueue.async {
//                print("任务 2 必须等任务 1 完成后才会开始")
//            }
//        }
       
        title = "功能列表"
        view.backgroundColor = .white
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkFirstLaunch()
    }
    
    private func checkFirstLaunch() {
        let isFirstLaunch = !UserDefaults.standard.bool(forKey: "kFirstLaunchCompleted")
        if isFirstLaunch {
            let guideVC = GuideViewController()
            guideVC.modalPresentationStyle = .fullScreen
            present(guideVC, animated: false)
        } else {
            showFeatureGuideIfNeeded()
        }
    }
    
    private func showFeatureGuideIfNeeded() {
        guard !hasSeenGuide else { return }
        guard let window = UIApplication.shared.keyWindow else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.showFeatureGuide(in: window)
        }
    }
    
    private func showFeatureGuide(in window: UIWindow) {
        let steps = generateGuideSteps(in: window)
        
        guard !steps.isEmpty else { return }
        
        let guideView = GuideMaskView(steps: steps)
        guideView.onDismiss = { [weak self] in
            self?.hasSeenGuide = true
        }
        guideView.show(in: window)
    }
    
    private func generateGuideSteps(in window: UIWindow) -> [GuideMaskView.GuideStep] {
        var steps: [GuideMaskView.GuideStep] = []
        
        tableView.setContentOffset(.zero, animated: false)
        tableView.layoutIfNeeded()
        
        for (index, itemTitle) in items.enumerated() {
            if index >= 3 { break }
            if itemTitle == "关于新学习" { break }
            
            let indexPath = IndexPath(row: index, section: 0)
            
            guard let cell = tableView.cellForRow(at: indexPath) else { continue }
            let cellRectInTableView = cell.convert(cell.bounds, to: tableView)
            let cellRectInWindow = tableView.convert(cellRectInTableView, to: window)
            
            if cellRectInWindow.width == 0 || cellRectInWindow.height == 0 { continue }
            
            let description = getGuideDescription(for: itemTitle)
            
            steps.append(GuideMaskView.GuideStep(
                targetRect: cellRectInWindow,
                title: itemTitle,
                description: description,
                isRound: false
            ))
        }
        
        tableView.setContentOffset(.zero, animated: false)
        
        if steps.isEmpty {
            steps = [
                GuideMaskView.GuideStep(
                    targetRect: CGRect(x: 20, y: 100, width: window.bounds.width - 40, height: 60),
                    title: "欢迎使用",
                    description: "探索新学习的丰富功能",
                    isRound: false
                )
            ]
        }
        
        return steps
    }
    
    private func getGuideDescription(for feature: String) -> String {
        switch feature {
        case "抖音加载动画展示":
            return "这里可以看到炫酷的抖音双球环绕加载动画效果"
        case "常用动画库展示":
            return "包含抖动、呼吸、翻转等常用 UI 动画"
        case "复杂曲线路径动画":
            return "学习如何使用 CAKeyframeAnimation"
        default:
            return "点击进入查看此功能的详细演示"
        }
    }
    
    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
    }
}

// MARK: - UITableViewDataSource
extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate
extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case 0:
            let loadingVC = LoadingViewController()
            navigationController?.pushViewController(loadingVC, animated: true)
            
        case 1:
            let animationVC = AnimationListViewController()
            navigationController?.pushViewController(animationVC, animated: true)
            
        case 2:
            let keyframeVC = KeyframeAnimationViewController()
            navigationController?.pushViewController(keyframeVC, animated: true)
            
        case 3:
            let waveVC = WaveAnimationViewController()
            navigationController?.pushViewController(waveVC, animated: true)
            
        case 4:
            let cameraVC = CameraViewController()
            cameraVC.modalPresentationStyle = .fullScreen
            present(cameraVC, animated: true)
        case 5:
            let signatureVC = Signature_ViewController()
            navigationController?.pushViewController(signatureVC, animated: true)
            
        case 6:
            let nfcVC = NFCViewController()
            navigationController?.pushViewController(nfcVC, animated: true)
        case 7:
            let bluetoothVC = BluetoothViewController()
            navigationController?.pushViewController(bluetoothVC, animated: true)
        case 8:
            let mqttVC = MQTTDemoViewController()
            navigationController?.pushViewController(mqttVC, animated: true)
        case 9:
            let pcmPlayer = PCMPlayerViewController()
            navigationController?.pushViewController(pcmPlayer, animated: true)
        case 10:
            let audioChange = AudioChangeViewController()
            navigationController?.pushViewController(audioChange, animated: true)
        case 11:
            let kLineView = KLineViewController()
            navigationController?.pushViewController(kLineView, animated: true)
            case 12:
            let scan = SWQRCodeViewController()
            navigationController?.pushViewController(scan, animated: true)
        default:
            let alert = UIAlertController(title: "关于", message: "这是一个基于 Swift 的学习演示项目", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "知道了", style: .default))
            present(alert, animated: true)
            break
        }
    }
}

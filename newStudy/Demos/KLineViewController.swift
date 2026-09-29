//
//  KLineViewController.swift
//  newStudy
//
//  Created by xp on 2026/8/17.
//

import UIKit
import MetalKit

class KLineViewController: UIViewController {
    private var kLineView: MetalKLineView!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupMetalView()
        generateAndLoadRandomData()
 
        // Do any additional setup after loading the view.
    }
    
    private func setupMetalView() {
        kLineView = MetalKLineView(frame: view.bounds, device: nil)
        kLineView.autoresizingMask = [.flexibleWidth,.flexibleHeight]
        view.addSubview(kLineView)
        if kLineView.device == nil {
            print("当前设备不支持Metal")
        }
    }
    private func generateAndLoadRandomData(){
        let randomPrices = (1...20).map { _ in
            Float.random(in: 100...200)
        }
        kLineView.updateData(with: randomPrices)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

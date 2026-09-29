//
//  Signature‌ViewController.swift
//  newStudy
//
//  Created by ma c on 2026/4/17.
//

import UIKit

class Signature_ViewController: UIViewController {
  private var drawingView: DrawingView2!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        drawingView = DrawingView2(frame: view.bounds)
        view.addSubview(drawingView)
        createButton(title: "撤销", action: #selector(undo), index: 0)
        createButton(title: "清空", action: #selector(clear), index: 1)
        createButton(title: "保存", action: #selector(save), index: 2)
        // Do any additional setup after loading the view.
    }
    
    private func createButton(title: String, action: Selector,index:Int)  {
      let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: view.bounds.height - 80, width: 80, height: 40)
        switch index {
        case 0:
            button.frame.origin.x = 20
        case 1:
            button.frame.origin.x = view.bounds.width/2 - 40
        case 2:
            button.frame.origin.x = view.bounds.width - 100
        default:
            break
        }
        button.backgroundColor = .lightGray
      button.setTitle(title, for: .normal)
      button.addTarget(self, action: action, for: .touchUpInside)
        view.addSubview(button)
        
    }
    
    @objc private func clear() {
        drawingView.clear()
    }
    
    @objc private func save() {
        let image = drawingView.getImage()
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    @objc private func undo() {
        drawingView.undo()
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // 保存失败
            print("保存失败: \(error.localizedDescription)")
        } else {
            // 保存成功
            print("保存成功!")
        }
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

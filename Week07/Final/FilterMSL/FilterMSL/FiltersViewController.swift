//
//  FiltersViewController.swift
//  FilterMSL
//
//  Created by 陈逸安 on 4/29/24.
//

import UIKit

class FiltersViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupFilterButtons()
    }

    private func setupFilterButtons() {
        let button = UIButton(frame: CGRect(x: 100, y: 200, width: 200, height: 50))
        button.backgroundColor = .blue
        button.setTitle("Start Video", for: .normal)
        button.addTarget(self, action: #selector(startVideo), for: .touchUpInside)
        view.addSubview(button)
    }

    @objc private func startVideo() {
        let videoViewController = ViewController()
        navigationController?.pushViewController(videoViewController, animated: true)
    }
}

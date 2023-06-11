//
//  ResponseCell.swift
//  OpenAi
//
//  Created by hyd on 2023/2/25.
//

import UIKit
import MarkdownView
import SafariServices
class ResponseCell: UITableViewCell {
 
    private var tipLab:UILabel!
    public  var markdownView:MarkdownView!
    public  var contentLab:UILabel!
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let tipLab = UILabel(frame: .zero)
        tipLab.backgroundColor = .black
        tipLab.text = "A"
        tipLab.textAlignment = .center
        tipLab.textColor = .white
        tipLab.font = .systemFont(ofSize: 12)
        self.contentView.addSubview(tipLab)
        tipLab.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.width.height.equalTo(20)
        }
        tipLab.layer.cornerRadius = 10
        tipLab.layer.masksToBounds = true
        self.tipLab = tipLab
        
        let contentLab = UILabel()
        contentLab.font = .systemFont(ofSize: 16)
        contentLab.textAlignment = .left
        contentLab.numberOfLines = 0
        self.contentView.addSubview(contentLab)
        contentLab.snp.makeConstraints { make in
            make.top.equalTo(tipLab)
            make.leading.equalTo(tipLab.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-12)
        }
        self.contentLab = contentLab
        
        
//        markdownView = MarkdownView(css: "", plugins: [])
//        markdownView.isScrollEnabled = false
//        self.contentView.addSubview(markdownView)
//        markdownView.snp.makeConstraints { make in
//            make.top.equalTo(tipLab)
//            make.leading.equalTo(tipLab.snp.trailing).offset(12)
//            make.trailing.equalToSuperview().offset(-12)
//            make.bottom.equalToSuperview().offset(-12)
//        }
//        // called when user touch link
//        markdownView.onTouchLink = { [weak self] request in
//          guard let url = request.url else { return false }
//
//          if url.scheme == "file" {
//            return false
//          } else if url.scheme == "https" {
//            let safari = SFSafariViewController(url: url)
//              if let navigationController = self?.getCurrentNavigationController() {
//                  // 在这里使用找到的导航控制器
//                  navigationController.pushViewController(safari, animated: true)
//              }
//
//            return false
//          } else {
//            return false
//          }
//        }

    }
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if #available(iOS 13.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                self.backgroundColor = UIColor(hex: "#3c3d4a")
                self.tipLab.backgroundColor = .white
                self.tipLab.textColor = .black

            } else {
                self.backgroundColor = UIColor(hex: "#f6f6f7")
                self.tipLab.backgroundColor = .black
                self.tipLab.textColor = .white
            }
        } else {
            self.backgroundColor = UIColor(hex: "#f6f6f7")
            self.tipLab.backgroundColor = .black
            self.tipLab.textColor = .white
        }
    }
    
 
    func configure(with markdown: String, onRendered: @escaping (CGFloat) -> Void) {
        self.contentLab.text = markdown
//        markdownView.onRendered = { [weak self] height in
//            guard let self = self else { return }
//            // 计算整个 UITableViewCell 的高度
//            let cellHeight = height + self.contentView.layoutMargins.top + self.contentView.layoutMargins.bottom
//            onRendered(cellHeight)
//        }
//        markdownView.load(markdown: markdown)

    }
  
}

extension ResponseCell {
    func getCurrentNavigationController() -> UINavigationController? {
        var responder: UIResponder? = self
        
        while responder != nil {
            if let navigationController = responder as? UINavigationController {
                return navigationController
            } else if let viewController = responder as? UIViewController {
                return viewController.navigationController
            }
            
            responder = responder?.next
        }
        
        return nil
    }
    

}

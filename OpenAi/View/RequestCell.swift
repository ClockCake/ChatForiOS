//
//  RequestCell.swift
//  OpenAi
//
//  Created by hyd on 2023/2/25.
//

import UIKit
class RequestCell: UITableViewCell {
    var model:SaveModel?{
        didSet{
            setModel()
        }
    }
    private var contentLab:UILabel!
    private var tipLab:UILabel!
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let tipLab = UILabel(frame: .zero)
        tipLab.text = "Q"
        tipLab.backgroundColor = .black
        tipLab.textAlignment = .center
        tipLab.textColor = .white
        tipLab.font = .systemFont(ofSize: 12)
        self.contentView.addSubview(tipLab)
        tipLab.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.width.height.equalTo(20)
        }
        tipLab.layer.cornerRadius = 10
        tipLab.layer.masksToBounds = true
        self.tipLab = tipLab
        
        let contentLab = UILabel(frame: .zero)
        contentLab.textColor = .black
        contentLab.textAlignment = .left
        contentLab.font = .systemFont(ofSize: 16)
        contentLab.numberOfLines = 0
        self.contentView.addSubview(contentLab)
        contentLab.snp.makeConstraints { make in
            make.top.equalTo(tipLab)
            make.trailing.equalTo(tipLab.snp.leading).offset(-12)
            make.leading.greaterThanOrEqualToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        self.contentLab = contentLab
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if #available(iOS 13.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                self.backgroundColor = UIColor(hex: "#2e2e39")
                self.contentLab.textColor = .white
                self.tipLab.backgroundColor = .white
                self.tipLab.textColor = .black
            } else {
                self.backgroundColor = .white
                self.contentLab.textColor = .black
                self.tipLab.backgroundColor = .black
                self.tipLab.textColor = .white
            }
        } else {
            self.backgroundColor = .white
            self.contentLab.textColor = .black
            self.tipLab.backgroundColor = .black
            self.tipLab.textColor = .white

        }
    }
    
    func setModel(){
        guard let model = model else { return  }
        self.contentLab.text = model.question
    }
}

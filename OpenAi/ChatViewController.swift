import UIKit
import RxSwift
import RxCocoa
import SnapKit
import OpenAIStreamingCompletions
class ChatViewController: UIViewController {
    private var messages:[OpenAIAPI.Message] = []
    var cellHeights: [IndexPath: CGFloat] = [:]
    let disposeBag = DisposeBag()
    private var themeButton:UIBarButtonItem!

    lazy var textView: PlaceholderTextView = {
        let textView = PlaceholderTextView()
        textView.isScrollEnabled = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        textView.layer.cornerRadius = 4
        textView.layer.borderWidth = 1
        textView.placeholder = "Type a Message..."
        textView.layer.borderColor = traitCollection.userInterfaceStyle == .dark ? UIColor.white.cgColor : UIColor.systemGray4.cgColor
        textView.backgroundColor = UIColor(dynamicProvider: { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(hex: "#3c3d4a")
            } else {
                return .white
            }
        }) // 设置背景颜色
        
        return textView
    }()
    
    lazy var senderBtn:UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(scale: .medium)
        let color = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor(named: "LightModeColor") ?? UIColor(hex: "#3c3d4a")
        let image = UIImage(systemName: "paperplane", withConfiguration: config)?.withTintColor(color, renderingMode: .alwaysOriginal)
        button.setImage(image, for: .normal)
        button.rx.tap.withUnretained(self).subscribe(onNext: { _ in
            self.view.endEditing(true)
            let textViewStr = self.textView.text ?? ""
            self.textView.text = ""
            self.requestOpenAIMessage(prompt: textViewStr)
            
        }).disposed(by: disposeBag)
        
        return button
    }()
    
    lazy var tableView:UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.register(RequestCell.self, forCellReuseIdentifier: "RequestCell")
        tableView.register(ResponseCell.self, forCellReuseIdentifier: "ResponseCell")
        tableView.showsVerticalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        return tableView
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ChatBot"
        view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#3c3d4a") : .white
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        configNavColor(Mode: traitCollection.userInterfaceStyle)


        view.addSubview(textView)
        view.addSubview(senderBtn)
        view.addSubview(tableView)
        setupConstraints()
        setupRx()
        
        if let _ = UserDefaultsManager.shared.load() {
            DispatchQueue.main.async {
                self.tableView.reloadData()
                self.scrollToBottom()
            }

        }
        
        ///收起发起请求
        if let url = URL(string: "https://openai.com/") {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error)")
                } else if let data = data {
                    print("Data: \(data)")
                }
            }
            task.resume()
        }
        
        

    }

    func configNavColor(Mode:UIUserInterfaceStyle) {
         navigationController?.navigationBar.isTranslucent = false
         // 导航背景色
         if #available(iOS 13.0, *) {
             let apperance = UINavigationBarAppearance()
             apperance.backgroundColor = Mode == .light ? .white : UIColor(hex: "#3c3d4a")
             // 去除导航栏阴影（如果不设置clear，导航栏底下会有一条阴影线）
             apperance.titleTextAttributes = [.foregroundColor:(Mode == .light ? .black : UIColor(hex: "#FFFFFF") ), .font:UIFont.systemFont(ofSize: 18)]
             apperance.shadowColor = UIColor.clear
             navigationController?.navigationBar.scrollEdgeAppearance = apperance
             navigationController?.navigationBar.standardAppearance = apperance
             
             // 创建带图标的按钮
             let themeImage = traitCollection.userInterfaceStyle == .dark ? UIImage(systemName: "sun.max.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal) : UIImage(systemName: "moon.fill")?.withTintColor(UIColor(hex: "#1e1e20"), renderingMode: .alwaysOriginal)
             
             let themeButton = UIBarButtonItem(image: themeImage, style: .plain, target: self, action: #selector(toggleTheme))
             navigationItem.rightBarButtonItem = themeButton
             self.themeButton = themeButton
             
         } else {
             // Fallback on earlier versions
             let apperance = UINavigationBar.appearance()
             apperance.barTintColor = .white
             apperance.titleTextAttributes = [.foregroundColor:UIColor.black, .font:UIFont.systemFont(ofSize: 18)]
             apperance.shadowImage = UIImage()
         }
     }
    deinit {
        // 移除键盘弹出和回收的通知
        NotificationCenter.default.removeObserver(self)
    }
 

    
    /// light Model /  Dark Model
    /// - Parameter previousTraitCollection:
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                ///背景色
                view.backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor(hex: "#3c3d4a") : .white
                /// 发送按钮
                let config = UIImage.SymbolConfiguration(scale: .medium)
                let color = UITraitCollection.current.userInterfaceStyle == .dark ? UIColor.white : UIColor(named: "LightModeColor") ?? UIColor(hex: "#3c3d4a")
                let image = UIImage(systemName: "paperplane", withConfiguration: config)?.withTintColor(color, renderingMode: .alwaysOriginal)
                senderBtn.setImage(image, for: .normal)
                textView.layer.borderColor = traitCollection.userInterfaceStyle == .dark ? UIColor.white.cgColor : UIColor.systemGray4.cgColor
            }
        } else {
            // Fallback on earlier versions
        }
    }

    
    func setupConstraints() {
        textView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(24)
            make.trailing.equalToSuperview().offset(-48)
            make.bottom.equalToSuperview().offset(KIsIPhoneXSeries ?  -KSafeAreaBottomHeight : -24)
            make.height.equalTo(36)
        }
        senderBtn.snp.makeConstraints { make in
            make.centerY.equalTo(textView)
            make.trailing.equalToSuperview().offset(-12)
            make.width.equalTo(36)
        }
        
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(textView.snp.top).offset(-12)
        }
        
    }

    
    func setupRx() {
        textView.rx.text
            .orEmpty
            .subscribe(onNext: { [weak self] text in
                guard let self = self else { return }
                let maxHeight: CGFloat = 108 // 5 lines * 18 points per line
                let size = CGSize(width: self.textView.bounds.width, height: maxHeight)
                let estimatedSize = self.textView.sizeThatFits(size)
                let height = min(maxHeight, max(36, estimatedSize.height))
                self.textView.snp.updateConstraints { make in
                    make.height.equalTo(height)
                }
                self.textView.isScrollEnabled = height == maxHeight
                self.senderBtn.isUserInteractionEnabled = text.isEmpty == true ? false : true
            })
            .disposed(by: disposeBag)
    }
    

}

extension ChatViewController: UITextViewDelegate,UITableViewDelegate,UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if let loadData = UserDefaultsManager.shared.load() {
            if loadData.isEmpty {
                // 如果数据为空，则显示缺省图
                let noDataView = EmptyDataView(frame: tableView.bounds)
                tableView.backgroundView = noDataView
                tableView.separatorStyle = .none
                return 0
            } else {
                // 如果数据不为空，则取消显示缺省图
                tableView.backgroundView = nil
                return loadData.count
            }
            
        }
        // 如果数据为空，则显示缺省图
        let noDataView = EmptyDataView(frame: tableView.bounds)
        tableView.backgroundView = noDataView
        tableView.separatorStyle = .none
        return 0

    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView.init()
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView.init()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 1{
            if let height = cellHeights[indexPath] {
                return height
            } else {
                return UITableView.automaticDimension
            }
        }
        else{
            return UITableView.automaticDimension
        }
        
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.row == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath) as! RequestCell
            if let loadedData = UserDefaultsManager.shared.load() {
                cell.model = loadedData[indexPath.section]
                cell.selectionStyle = .none
            }
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "ResponseCell", for: indexPath) as! ResponseCell
            if let loadedData = UserDefaultsManager.shared.load() {
                let model = loadedData[indexPath.section]
                let markdownText = model.answer.prefix { $0 == "\n" }.count == 0 ? model.answer : String(model.answer.drop { $0 == "\n" })
                cell.configure(with: markdownText) { [weak self] height in
                    guard let self = self else { return }
                    self.cellHeights[indexPath] = height
                    // 更新 tableView，以实时调整 cell 高度
                    tableView.performBatchUpdates(nil)
                }
                cell.selectionStyle = .none
            }
            return cell
        }
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollView.contentOffset.x = 0
    }

    func reloadNewData(){
        self.tableView.reloadData()
        let lastsectionIndex = self.tableView.numberOfSections - 1
        let lastIndexPath = IndexPath(row: 0, section: lastsectionIndex)
        self.tableView.scrollToRow(at: lastIndexPath, at: .top, animated: true)
        
    }
    

    func scrollToBottom() {
        let lastsectionIndex = self.tableView.numberOfSections - 1
        let lastIndexPath = IndexPath(row: 1, section: lastsectionIndex)
        self.tableView.scrollToRow(at: lastIndexPath, at: .bottom, animated: true)
    }
}


extension ChatViewController{
    func requestOpenAIMessage(prompt:String){
        messages.removeAll()
        let data = SaveModel(question: prompt, answer: "Thinking, please wait...", creatTime: String.DateToString())
        UserDefaultsManager.shared.save(array: [data])
        self.reloadNewData()
        self.senderBtn.isUserInteractionEnabled = false
        let api = OpenAIAPI(apiKey: String.generateRandomString())
        let questions = UserDefaultsManager().load()?.map({$0.question }) ?? []
        let message = OpenAIAPI.Message(role: .system, content: "You are ChatGPT, a large language model trained by OpenAI. Follow the user's instructions carefully. Respond using markdown.")
        messages.append(message)
        for question in questions {
            let message = OpenAIAPI.Message(role: .user, content: question)
            messages.append(message)
        }


        Task {
            let stream =  try api.completeChatStreaming(.init(messages:  messages,max_tokens: maxToken)) ///SSE请求
            for await message in stream {
                print("\(message.content)") // each message contains a small part of the response
                if let loadData = UserDefaultsManager.shared.load() {
                    let data = SaveModel(question: prompt, answer: message.content, creatTime: String.DateToString())
                    UserDefaultsManager.shared.replace(saveModel: data, atIndex: loadData.count - 1)
                }
                self.reloadNewData()
            }
        }

    }

    @objc func keyboardWillShow(notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        
        textView.snp.updateConstraints { update in
            update.bottom.equalToSuperview().offset(-(keyboardFrame.height + 12))
        }
        
        tableView.snp.updateConstraints { update in
            update.bottom.equalTo(textView.snp.top).offset(-12)
        }
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }

    }

    @objc func keyboardWillHide(notification: Notification) {
        textView.snp.updateConstraints { update in
            update.bottom.equalToSuperview().offset(KIsIPhoneXSeries ?  -KSafeAreaBottomHeight : -24)
        }
        
        tableView.snp.updateConstraints { update in
            update.bottom.equalTo(textView.snp.top).offset(-12)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
   

    }

    @objc func toggleTheme() {
        self.view.endEditing(true)
        if let keyWindow = UIApplication.shared.keyWindow {
            if keyWindow.traitCollection.userInterfaceStyle == .dark {
                keyWindow.overrideUserInterfaceStyle = .light
                let themeImage = UIImage(systemName: "moon.fill")?.withTintColor(UIColor(hex: "#1e1e20"), renderingMode: .alwaysOriginal)
                self.themeButton.image = themeImage
            } else {
                keyWindow.overrideUserInterfaceStyle = .dark
                let themeImage = UIImage(systemName: "sun.max.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
                self.themeButton.image = themeImage
            }
            configNavColor(Mode: keyWindow.overrideUserInterfaceStyle)
        }
    }
}

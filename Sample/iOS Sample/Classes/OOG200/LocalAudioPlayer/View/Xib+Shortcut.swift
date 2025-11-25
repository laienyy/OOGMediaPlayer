
import Foundation
import UIKit

extension NSObject {
    static var classNameStr: String {
        let str = NSStringFromClass(self).components(separatedBy: ".").last!
        return str
    }
    
    var classNameStr: String {
        return NSStringFromClass(self.classForCoder.self).components(separatedBy: ".").last!
    }
}

extension UIView {
    
    static func haveNib(_ bundle: Bundle = .main) -> Bool {
        return bundle.path(forResource: classNameStr, ofType: "nib") != nil
    }
    
    static func nib(bundle: Bundle = .main) -> UINib {
        return .init(nibName: classNameStr, bundle: bundle)
    }
    
    static func fromNib<T: UIView>(bundle: Bundle = .main) -> T {
        return nib(bundle: bundle).instantiate(withOwner: nil).first as! T
    }
}

extension UITableView {
    
    func registerCellFromNib<T: UITableViewCell>(_: T.Type) {
        let nib = T.nib()
        register(nib, forCellReuseIdentifier: T.classNameStr)
    }
    
    func registerCellFromClass<T: UITableViewCell>(_: T.Type) {
        register(T.self, forCellReuseIdentifier: T.classNameStr)
    }
    
    func registerHeaderFooterFromNib<T: UITableViewHeaderFooterView>( _: T.Type) {
        let nib = T.nib()
        register(nib, forHeaderFooterViewReuseIdentifier: T.classNameStr)
    }
    
    func registerHeaderFooterFromClass<T: UITableViewHeaderFooterView>( _: T.Type) {
        register(T.self, forHeaderFooterViewReuseIdentifier: T.classNameStr)
    }
}

extension UITableViewCell {
    static func reuse<T: UITableViewCell>(from tableView: UITableView) -> T {
        var cell = tableView.dequeueReusableCell(withIdentifier: T.classNameStr)
        if cell == nil {
            // 尚未注册，根据类名注册
            tableView.registerCellFromNib(T.self)
            cell = tableView.dequeueReusableCell(withIdentifier: T.classNameStr)
        }
        return cell as! T
    }
}

extension UITableViewHeaderFooterView {
    static func reuse<T: UITableViewHeaderFooterView>(from tableView: UITableView) -> T {
        var cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: T.classNameStr)
        if cell == nil {
            // 尚未注册，根据类名注册
            tableView.registerHeaderFooterFromNib(T.self)
            cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: T.classNameStr)
        }
        return cell as! T
    }
}

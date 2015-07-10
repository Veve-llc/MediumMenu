//
//  MediumMenu.swift
//  MediumMenu
//
//  Created by pixyzehn on 2/2/15.
//  Copyright (c) 2015 pixyzehn. All rights reserved.
//

import UIKit

public typealias completionHandler = () -> ()

public class MediumMenu: UIView {

    public enum State {
        case Shown
        case Closed
        case Displaying
    }
    
    public enum Alignment {
        case Left
        case Right
        case Center
    }

    private struct Color {
        static let mediumWhiteColor = UIColor(red:0.98, green:0.98, blue:0.98, alpha:1)
        static let mediumBlackColor = UIColor(red:0.05, green:0.05, blue:0.05, alpha:1)
        static let mediumGlayColor = UIColor(red:0.57, green:0.57, blue:0.57, alpha:1)
    }

    public var heightForHeaderInSection: CGFloat = 30
    public var heightForRowAtIndexPath: CGFloat  = 57
    public var velocityTreshold: CGFloat         = 1000
    public var autoCloseVelocity: CGFloat        = 1200
    public var menuBounceOffset: CGFloat         = 0

    public var currentMenuState: State = .Closed
    public var startIndex: Int = 1
    public var highLighedIndex: Int = 1
    public var cellIdentifier: String            = "menucell"
    public var panGestureEnable: Bool            = true

    public var textColor: UIColor?
    public var highLightTextColor: UIColor?
    public var titleFont: UIFont?
    public var titleAlignment: Alignment?

    public var menuItems: [MediumMenuItem] = [MediumMenuItem]()

    private var _height: CGFloat?
    public var height: CGFloat? {
        get {
            return _height
        }
        set {
            var menuFrame: CGRect = frame
            menuFrame.size.height = newValue!
            menuContentTable?.frame = menuFrame
            _height = newValue
        }
    }

    private var _backgroundColor: UIColor?
    override public var backgroundColor: UIColor? {
        get {
            return _backgroundColor
        }
        set {
            _backgroundColor = newValue
            menuContentTable?.backgroundColor = newValue
        }
    }
    
    private var _menuContentTable: UITableView?
    public var menuContentTable: UITableView? {
        get {
            return _menuContentTable
        }
        set {
            newValue?.delegate = self
            newValue?.dataSource = self
            newValue?.showsVerticalScrollIndicator = false
            newValue?.separatorColor = UIColor.clearColor()
            newValue?.allowsMultipleSelection = false
            _menuContentTable = newValue
            addSubview(_menuContentTable!)
        }
    }

    private var _contentController: UIViewController?
    public var contentController: UIViewController? {
        get {
            return _contentController
        }
        set {
            if let value = newValue?.navigationController {
                _contentController = value.navigationController
            } else {
                _contentController = newValue
            }
            let pan: UIPanGestureRecognizer = UIPanGestureRecognizer(target: self, action: "didPan:")
            _contentController?.view.addGestureRecognizer(pan)
            setShadowProperties()
            _contentController?.view.autoresizingMask = UIViewAutoresizing.None
            let menuController: UIViewController = UIViewController()
            menuController.view = self
            UIApplication.sharedApplication().delegate?.window??.rootViewController = menuController
            UIApplication.sharedApplication().delegate?.window??.addSubview(_contentController!.view!)
        }
    }

    //MARK:Initializers

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.titleFont = UIFont(name: "HelveticaNeue-Light", size: 28)
        self.height = 466
        self.textColor = Color.mediumWhiteColor
        self.highLightTextColor = Color.mediumGlayColor
        self.backgroundColor = Color.mediumBlackColor
    }

    required public init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public convenience init(_ menuItems: [MediumMenuItem], titleAlignment: Alignment = .Left, forViewController: UIViewController) {
        self.init()
        self.frame = CGRectMake(0, 0, CGRectGetWidth(UIScreen.mainScreen().bounds), height!)
        self.menuContentTable = UITableView(frame: frame)
        self.menuItems = menuItems
        self.titleAlignment = titleAlignment
        self.contentController = forViewController
    }
    
    public static let sharedInstance = MediumMenu()
    
    public override func layoutSubviews() {
        frame = CGRectMake(0, 0, CGRectGetWidth(UIScreen.mainScreen().bounds), height!);
        contentController?.view.frame = CGRectMake(0, 0, CGRectGetWidth(UIScreen.mainScreen().bounds), CGRectGetHeight(UIScreen.mainScreen().bounds));
        setShadowProperties()
        menuContentTable = UITableView(frame: frame)
        menuContentTable?.backgroundColor = backgroundColor
    }
    
    private func setShadowProperties() {
        _contentController?.view.layer.shadowOffset = CGSizeMake(0, 1)
        _contentController?.view.layer.shadowRadius = 4.0
        _contentController?.view.layer.shadowColor = UIColor.lightGrayColor().CGColor
        _contentController?.view.layer.shadowOpacity = 0.4
        _contentController?.view.layer.shadowPath = UIBezierPath(rect: _contentController!.view.bounds).CGPath
    }
    
    //MARK:StatusBar
    
    public func showStatusBar() {
        UIApplication.sharedApplication().setStatusBarHidden(false, withAnimation: UIStatusBarAnimation.Slide)
    }
    
    public func dismissStatusBar() {
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: UIStatusBarAnimation.Slide)
    }
    
    //MARK:Menu Interactions
    
    public func showMenu() {
        if currentMenuState == .Shown || currentMenuState == .Displaying {
            animateMenuClosingWithCompletion(nil)
        } else {
            currentMenuState = .Displaying
            animateMenuOpening()
        }
    }
    
    public func didPan(pan: UIPanGestureRecognizer) {
        if panGestureEnable {
            if var viewCenter = pan.view?.center {
                if pan.state == .Began || pan.state == .Changed {
                    let translation: CGPoint = pan.translationInView(pan.view!.superview!)
                    
                    if viewCenter.y >= UIScreen.mainScreen().bounds.size.height/2 && viewCenter.y <= (UIScreen.mainScreen().bounds.size.height/2 + height!) - menuBounceOffset {
                        currentMenuState = .Displaying
                        viewCenter.y = abs(viewCenter.y + translation.y)
                        if viewCenter.y >= UIScreen.mainScreen().bounds.size.height/2 && viewCenter.y <= (UIScreen.mainScreen().bounds.size.height/2 + height!) - menuBounceOffset {
                            contentController?.view.center = viewCenter
                        }
                        pan.setTranslation(CGPointZero, inView: contentController?.view)
                    }
                } else if pan.state == .Ended {
                    let velocity: CGPoint = pan.velocityInView(contentController?.view.superview)
                    
                    if velocity.y > velocityTreshold {
                        openMenuFromCenterWithVelocity(velocity.y)
                        return
                    } else if velocity.y < -velocityTreshold {
                        closeMenuFromCenterWithVelocity(abs(velocity.y))
                        return
                    }
                    if viewCenter.y <= contentController?.view.frame.size.height {
                        animateMenuClosingWithCompletion(nil)
                    } else {
                        animateMenuOpening()
                    }
                }
            }
        }
    }

    //MARK:Animation and menu operations

    public func animateMenuOpening() {
        showStatusBar()
        if currentMenuState != .Shown {
            if let x = contentController?.view.center.x {
                UIView.animateWithDuration(0.2, animations: {[unowned self]() -> Void in
                    self.contentController?.view.center = CGPointMake(x, UIScreen.mainScreen().bounds.size.height/2 + self.height!)
                }, completion: {[unowned self](finished: Bool) -> Void in
                    UIView.animateWithDuration(0.2, animations: {[unowned self]() -> Void in
                        self.contentController?.view.center = CGPointMake(x, UIScreen.mainScreen().bounds.size.height/2 + self.height! - menuBounceOffset)
                    }, completion: {(finished: Bool) -> Void in
                        self.currentMenuState = .Shown
                    })
                })
            }
        }
    }
    
    public func animateMenuClosingWithCompletion(completion: completionHandler?) {
        dismissStatusBar()
        if let center = contentController?.view.center {
            UIView.animateWithDuration(0.2, animations: {[unowned self]() -> Void in
                self.contentController?.view.center = CGPointMake(center.x, center.y + menuBounceOffset)
            }, completion: {[unowned self](finished: Bool) -> Void in
                UIView.animateWithDuration(0.2, animations: {[unowned self]() -> Void in
                    self.contentController?.view.center = CGPointMake(center.x, UIScreen.mainScreen().bounds.size.height/2)
                }, completion: {(finished: Bool) -> Void in
                    if finished {
                        self.currentMenuState = .Closed
                        if let com = completion {
                            completion!()
                        }
                    }
                })
            })
        }
    }

    public func openMenuFromCenterWithVelocity(velocity: CGFloat) {
        showStatusBar()
        let viewCenterY: CGFloat = UIScreen.mainScreen().bounds.size.height/2 + height! - menuBounceOffset
        currentMenuState = .Displaying
        let duration: NSTimeInterval = Double((viewCenterY - contentController!.view.center.y) / velocity)
        UIView.animateWithDuration(duration, animations: {[unowned self]() -> Void in
            if let center = self.contentController?.view.center {
                self.contentController?.view.center = CGPointMake(center.x, viewCenterY)
            }
        }, completion: {[unowned self](finished: Bool) -> Void in
            self.currentMenuState = .Shown
        })
    }

    public func closeMenuFromCenterWithVelocity(velocity: CGFloat) {
        dismissStatusBar()
        let viewCenterY: CGFloat = UIScreen.mainScreen().bounds.size.height/2
        currentMenuState = .Displaying
        let duration: NSTimeInterval = Double((contentController!.view.center.y - viewCenterY) / velocity)
        UIView.animateWithDuration(duration, animations: {[unowned self]() -> Void in
            if let center = self.contentController?.view.center {
                self.contentController?.view.center = CGPointMake(center.x, UIScreen.mainScreen().bounds.size.height/2)
            }
        }, completion: {[unowned self](finished: Bool) -> Void in
                self.currentMenuState = .Closed
        })
    }
    
    //MARK:Custom Function
    
    public func setHighLighedRow(row: Int) {
        highLighedIndex = row
        menuContentTable?.reloadData()
        let selectedItem: MediumMenuItem = menuItems[row - startIndex]
    }
    
    public func setHighLighedRowAtIndexPath(indexPath: NSIndexPath) {
        highLighedIndex = indexPath.row
        menuContentTable?.reloadData()
        let selectedItem: MediumMenuItem = menuItems[indexPath.row - startIndex]
    }
    
    public func setMenuTitleAlligmentForCell(cell: UITableViewCell) {
        if let tAlignment = titleAlignment {
            switch tAlignment {
            case .Left:
                cell.textLabel?.textAlignment = .Left
            case .Center:
                cell.textLabel?.textAlignment = .Center
            case .Right:
                cell.textLabel?.textAlignment = .Right
            default:
                break
            }
        }
    }
}

extension MediumMenu: UITableViewDataSource, UITableViewDelegate {
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count + 2 * startIndex
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var menuCell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as? UITableViewCell
        var mediumMenuItem: MediumMenuItem?
        
        if menuCell == nil {
            menuCell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: cellIdentifier)
            setMenuTitleAlligmentForCell(menuCell!)
            menuCell?.backgroundColor = UIColor.clearColor()
            menuCell?.selectionStyle = UITableViewCellSelectionStyle.None
            menuCell?.textLabel?.textColor = textColor
            menuCell?.textLabel?.font = titleFont
        }
        
        if indexPath.row >= startIndex && indexPath.row <= (menuItems.count - 1 + startIndex) {
            mediumMenuItem = menuItems[indexPath.row - startIndex]
            menuCell?.textLabel?.text = mediumMenuItem?.title
        }
        
        return menuCell!
    }
    
    public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if highLighedIndex == indexPath.row {
            cell.textLabel?.textColor = highLightTextColor
            cell.textLabel?.font = titleFont?.fontWithSize(titleFont!.pointSize)
        } else {
            cell.textLabel?.textColor = textColor
            cell.textLabel?.font = titleFont?.fontWithSize(titleFont!.pointSize)
        }
    }
    
    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row < startIndex || indexPath.row > menuItems.count - 1 + startIndex {
            return
        }
        dismissStatusBar()
        highLighedIndex = indexPath.row
        menuContentTable?.reloadData()
        let selectedItem: MediumMenuItem = menuItems[indexPath.row - startIndex]
        animateMenuClosingWithCompletion(selectedItem.completion!)
    }
    
    public func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view: UIView = UIView(frame: CGRectMake(0, 0, frame.width, 30))
        view.backgroundColor = UIColor.clearColor()
        return view
    }
    
    public func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return heightForHeaderInSection
    }
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return heightForRowAtIndexPath
    }
}

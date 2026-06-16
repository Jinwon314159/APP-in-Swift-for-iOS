//
//  PageViewController.swift
//  InternCard
//
//  Created by idl on 2018. 6. 25..
//  Copyright © 2018년 InterCard. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController, UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func newVc(viewController: String) -> UIViewController {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: viewController)
    }
    
    var orderedViewControllers: [UIViewController] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        orderedViewControllers.append(self.newVc(viewController: "sbContentCards"))
        orderedViewControllers.append(self.newVc(viewController: "sbChildCards"))
        
        self.dataSource = self
        
        if ContentCardsViewController.Constants.childCardAdded {
            if let lastViewController = orderedViewControllers.last {
                setViewControllers([lastViewController],
                                   direction: .forward,
                                   animated: true,
                                   completion: nil)
            }
            ContentCardsViewController.Constants.childCardAdded = false
        } else {
            if let firstViewController = orderedViewControllers.first {
                setViewControllers([firstViewController],
                                   direction: .forward,
                                   animated: true,
                                   completion: nil)
            }
        }
        
        //DispatchQueue.global(qos:.userInteractive).async { self.run() }
    }

    var i: Int64 = 0
    func run() {
        while true {
            
            print("bg thread" + String(i))
            i += 1
            
            activity_summary()
            
            usleep(1000000)
        }
    }
    
    func fetch(callback: @escaping ()->()) {
        print("fetch" + String(i))
        i += 1
        callback()
    }
    
    func activity_summary() {
        
        let c: child = child()
        c.select_for_summary() { ()->() in
            print(c.remote_no)
            
            let apd: activity_per_day = activity_per_day()
            apd.child_no = c.remote_no
            apd.summarize_and_insert() { (end: TimeInterval)->() in
                
            }
        }
    }

    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let previousIndex = viewControllerIndex - 1
        
        guard previousIndex >= 0 else {
            return nil //orderedViewControllers.last
        }
        
        guard orderedViewControllers.count > previousIndex else {
            return nil
        }
        
        return orderedViewControllers[previousIndex]
    }
    
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let viewControllerIndex = orderedViewControllers.index(of: viewController) else {
            return nil
        }
        
        let nextIndex = viewControllerIndex + 1
        
        guard orderedViewControllers.count != nextIndex else {
            return nil //orderedViewControllers.first
        }
        
        guard orderedViewControllers.count > nextIndex else {
            return nil
        }
        
        return orderedViewControllers[nextIndex]
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

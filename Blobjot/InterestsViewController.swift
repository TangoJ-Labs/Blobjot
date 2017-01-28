//
//  InterestsViewController.swift
//  Blobjot
//
//  Created by Sam Kudadji on 1/20/17.
//  Copyright © 2017 blobjot. All rights reserved.
//

import UIKit

//import FacebookCore
//import FacebookLogin


class InterestsViewController: UIViewController, UIScrollViewDelegate, UITableViewDelegate, UITableViewDataSource
{
    let screenQ: CGRect = UIScreen.main.bounds
    
    var interestsTableView: UITableView!
    
    var titleViewOne = UILabel()
    var titleViewTwo = UILabel()
    
    //var genArray = [UIImage: String]()
    var caunt : Int = 20
    
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        UIApplication.shared.statusBarStyle = .lightContent
        
        //genArray = [UIImage(named: "FB.png")!: "Houston Art Gallery", UIImage(named: "FB.png")!: "Los Angeles Library"]
        print("IVC - CHECK 1")
        self.loadGens()
        
        //        if let accessToken = AccessToken.current {
        //            // User is logged in, use 'accessToken' here.
        //        }
        //        else {
        //
        //            let loginManager = LoginManager()
        //
        //
        //
        //            loginManager.logIn([ .publicProfile, .email, .userFriends ], viewController: self) { loginResult in
        //                switch loginResult {
        //                case .failed(let error):
        //                    print(error)
        //                case .cancelled:
        //                    print("User cancelled login.")
        //                case .success(let grantedPermissions, let declinedPermissions, let accessToken):
        //                    print("Logged in!")
        //                }
        //
        //            }
        //
        //        }
    }
    
    
    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)
    }
    
    func loadGens()
    {
        print("IVC - CHECK 2")
        self.view.backgroundColor = UIColor(red: 197.0/255.0, green: 59.0/255.0, blue: 62.0/255.0, alpha: 1.0)
        
        titleViewOne.frame = CGRect.init(x: self.screenQ.width * 0.1, y: self.screenQ.height * 0.02, width: self.screenQ.width * 0.8, height: self.screenQ.height * 0.1)
        titleViewOne.textAlignment = .center
        
        //let formattedStringi = NSMutableAttributedString()
        //formattedStringi.normal(text: "I ").normal(text: "N ").normal(text: "T ").normal(text: "E ").normal(text: "R ").normal(text: "E ").normal(text: "S ").normal(text: "T ").normal(text: "S")
        
        titleViewOne.attributedText = NSAttributedString(string: "INTERESTS")

        titleViewTwo.frame = CGRect.init(x: self.screenQ.width * 0.1 + 2, y: self.screenQ.height * 0.02, width: self.screenQ.width * 0.8, height: self.screenQ.height * 0.1)
        titleViewTwo.textAlignment = .center
        titleViewTwo.font = UIFont(name: "Chalkduster", size : 22)
        titleViewTwo.textColor = UIColor.white
        titleViewTwo.text = "I N T E R E S T S"
        print("IVC - CHECK 3")
        interestsTableView = UITableView(frame: CGRect(x: 0, y: self.screenQ.height * 0.12, width: self.screenQ.width, height: self.screenQ.height * 1.88))
        interestsTableView.delegate = self
        interestsTableView.dataSource = self
        interestsTableView.register(InterestsTableViewCell.self, forCellReuseIdentifier: "interests")
        interestsTableView.backgroundColor = UIColor(red: 249.0/255.0, green: 249.0/255.0, blue: 249.0/255.0, alpha: 1.0)
        interestsTableView.rowHeight = screenQ.height * 0.15
        interestsTableView.separatorColor = UIColor.clear
        interestsTableView.showsVerticalScrollIndicator = false
        interestsTableView.showsHorizontalScrollIndicator = false
        print("IVC - CHECK 4")
        self.view.addSubview(titleViewOne)
        self.view.addSubview(titleViewTwo)
        self.view.addSubview(interestsTableView)
    }
    
    
    func deleteTBL(sender : UIGestureRecognizer)
    {
        print("IVC - CHECK 5")
        let ciel = NSIndexPath.init(row: sender.view!.tag, section: 0)
        let ceel = interestsTableView.cellForRow(at: ciel as IndexPath) as! InterestsTableViewCell
        
        //slider(viewee: ceel.IntScroll)
        //Timer.scheduledTimer(timeInterval:0.6, target:self, selector: #selector(InterestVC.relood), userInfo: nil, repeats: false)
    }
    
    func relood()
    {
        print("IVC - CHECK 6")
        caunt = caunt - 1
        interestsTableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return caunt
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return Constants.Dim.peopleTableViewCellHeight
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    {
        return self.screenQ.height
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int)
    {
        print("IVC - CHECK 11")
        if type(of: view) === UITableViewHeaderFooterView.self
        {
            (view as! UITableViewHeaderFooterView).backgroundView!.backgroundColor = UIColor.clear
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        print("IVC - CHECK 7")
        let cell = tableView.dequeueReusableCell(withIdentifier: "interests", for: indexPath) as! InterestsTableViewCell
        //cell.frame = CGRect.init(x: 0, y: 0, width: self.screenQ.width, height: self.screenQ.height * 0.15)
        cell.INT = indexPath.row % 2
        
        print("IVC - CHECK 8")
        if indexPath.row % 2 == 0
        {
            cell.IntRounder.backgroundColor = UIColor.darkGray
            cell.IntImage.image = UIImage(named: "FB.png")
            
            //let formattedStringi = NSMutableAttributedString()
            //formattedStringi.bold(text: "Houston Art Gallery")
            
            cell.interestLabel.attributedText = NSAttributedString(string: "Houston Art Gallery")
        }
        
        print("IVC - CHECK 9")
        if indexPath.row % 2 == 1
        {
            cell.IntRounder.backgroundColor = UIColor(red: 197.0/255.0, green: 59.0/255.0, blue: 62.0/255.0, alpha: 1.0)
            cell.IntImage.image = UIImage(named: "FB.png")
            
            //let formattedStringi = NSMutableAttributedString()
            //formattedStringi.bold(text: "Los Angeles Library")
            
            cell.interestLabel.attributedText = NSAttributedString(string: "Los Angeles Library")
        }
        
        print("IVC - CHECK 10")
        let taps = UITapGestureRecognizer(target: self, action: #selector(InterestsViewController.deleteTBL(sender:)))
        
        cell.deleteLabel.addGestureRecognizer(taps)
        cell.deleteLabel.isUserInteractionEnabled = true
        cell.deleteLabel.tag = indexPath.row
        
        return cell
    }
    
    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

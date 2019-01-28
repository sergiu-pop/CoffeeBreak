//
//  UserStatsDatasourceController.swift
//  CoffeeBreakExample
//
//  Created by Alex Nagy on 27/05/2018.
//  Copyright © 2018 Alex Nagy. All rights reserved.
//

import LBTAComponents
import JGProgressHUD

class UserStatsDatasourceController: DatasourceController, UISearchBarDelegate {
  
  var statsType: FirebaseMagic.StatFetchType = .followers
  let userStatsDatasource = UserStatsDatasource()
  
  lazy var backBarButtonItem: UIBarButtonItem = {
    var item = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(handleBackBarButtonItemTapped))
    return item
  }()
  
  @objc func handleBackBarButtonItemTapped() {
    dismiss(animated: true, completion: nil)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    collectionView?.backgroundColor = .white
    collectionView?.alwaysBounceVertical = true
    collectionView?.showsVerticalScrollIndicator = false
    guard let navBar = navigationController?.navigationBar else { return }
    navBar.barTintColor = .white
    navigationItem.title = statsType == .followers ? "Followers" : "Following"
    navigationItem.setLeftBarButton(backBarButtonItem, animated: false)
    
    datasource = userStatsDatasource
    userStatsDatasource.statsType = statsType
    
    fetchUsers(fetchType: statsType) { (result) in
      print("Fetched \(self.statsType) with result:", result)
    }
    
  }
  
  fileprivate func fetchUsers(fetchType: FirebaseMagic.StatFetchType, completion: @escaping (_ result: Bool) -> ()) {
    // MARK: FirebaseMagic - Fetch user followers / following
    let hud = JGProgressHUD(style: .light)
    FirebaseMagicService.showHud(hud, text: "Fetching user \(fetchType)...")
    FirebaseMagic.fetchUserStats(forUid: FirebaseMagic.currentUserUid(), fetchType: fetchType, in: self) { (result, err) in
      if let err = err {
        print("Failed to fetch user \(fetchType) with err:", err)
        FirebaseMagicService.dismiss(hud, afterDelay: nil, text: nil)
        FirebaseMagicService.showAlert(style: .alert, title: "Fetch error", message: "Failed to fetch user \(fetchType) with err: \(err)")
        completion(false)
        return
      } else if result == false {
        FirebaseMagicService.dismiss(hud, afterDelay: nil, text: "Something went wrong...")
        completion(false)
        return
      }
      print("Successfully fetched user \(fetchType)")
      FirebaseMagicService.dismiss(hud, afterDelay: nil, text: nil)
      completion(true)
    }
  }
  
  @objc func handleUpdateSearchDatasourceController() {
    collectionView?.reloadData()
  }
  
  override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: ScreenSize.width, height: 72)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 0
  }
  
}



















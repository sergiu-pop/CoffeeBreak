//
//  UserProfileDatasourceController.swift
//  CoffeeBreakExample
//
//  Created by Alex Nagy on 21/05/2018.
//  Copyright © 2018 Alex Nagy. All rights reserved.
//

import LBTAComponents
import Firebase
import JGProgressHUD

class UserProfileDatasourceController: DatasourceController {
  
  let userProfileDatasource = UserProfileDatasource()
  
  lazy var refreshControl : UIRefreshControl = {
    var rc = self.getRefreshControl()
    return rc
  }()
  
  lazy var logoutBarButtonItem: UIBarButtonItem = {
    var item = UIBarButtonItem(title: "Logout", style: .done, target: self, action: #selector(handleLogoutBarButtonItemTapped))
    return item
  }()
  
  @objc func handleLogoutBarButtonItemTapped() {
    let logOutAction = UIAlertAction(title: "Logout", style: .destructive) { (action) in
      // MARK: FirebaseMagic - Log out
      let hud = JGProgressHUD(style: .light)
      FirebaseMagicService.showHud(hud, text: "Logging out...")
      FirebaseMagic.logout(completion: { (err) in
        FirebaseMagicService.dismiss(hud, afterDelay: nil, text: nil)
        
        if let err = err {
          FirebaseMagicService.showAlert(style: .alert, title: "Logout Error", message: err.localizedDescription)
          return
        }
        
        self.deleteCurrentUserSession()
        let controller = SignUpController()
        let navController = UINavigationController(rootViewController: controller)
        self.present(navController, animated: true, completion: nil)
      })
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    FirebaseMagicService.showAlert(style: .actionSheet, title: nil, message: nil, actions: [logOutAction, cancelAction], completion: nil)
  }
  
  @objc fileprivate func handleUserSharedAPost() {
    fetchCurrentUser() { (currentUser) in
      self.reloadAllPosts { (result) in
        print("Reloaded posts after user have shared a new post with result:", result)
      }
    }
  }
  
  @objc fileprivate func handleFollowedUser() {
    fetchCurrentUser() { (currentUser) in
      print("Reloaded user stats after user has followed.")
    }
  }
  
  @objc fileprivate func handleUnfollowedUser() {
    fetchCurrentUser() { (currentUser) in
      print("Reloaded user stats after user has unfollowed.")
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    NotificationCenter.default.addObserver(self, selector: #selector(handleUserSharedAPost), name: FirebaseMagicService.notificationNameUserSharedAPost, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleFollowersButtonTapped), name: FirebaseMagicService.notificationNameShowFollowers, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleFollowingButtonTapped), name: FirebaseMagicService.notificationNameShowFollowing, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleFollowedUser), name: FirebaseMagicService.notificationNameFollowedUser, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(handleUnfollowedUser), name: FirebaseMagicService.notificationNameUnfollowedUser, object: nil)
    
    datasource = userProfileDatasource
    collectionView?.refreshControl = refreshControl
    
    setupController()
    
    fetchCurrentUser() { (currentUser) in
      self.navigationItem.title = currentUser.username
      self.reloadAllPosts(completion: { (result) in
        print("Fetched post with result:", result)
      })
    }
  }
  
  func fetchCurrentUser(completion: @escaping (CurrentUser) -> ()) {
    // MARK: FirebaseMagic - Fetch current user
    guard let uid = FirebaseMagic.currentUserUid() else { return }
    let hud = JGProgressHUD(style: .light)
    FirebaseMagicService.showHud(hud, text: "Fetching user...")
    FirebaseMagic.fetchUser(withUid: uid) { (user, err) in
      if let err = err {
        FirebaseMagicService.dismiss(hud, afterDelay: nil, text: nil)
        FirebaseMagicService.showAlert(style: .alert, title: "Error fetching user", message: err.localizedDescription)
        return
      }
      guard let user = user else {
        FirebaseMagicService.dismiss(hud, afterDelay: nil, text: "Could not fetch...")
        return
      }
      print("Successfully fetched user:", user.username)
      
      FirebaseMagicService.dismiss(hud, afterDelay: nil, text: nil)
      self.userProfileDatasource.user = user
      self.collectionView?.reloadData()
      completion(user)
    }
    
  }
  
  fileprivate func setupController() {
    collectionView?.backgroundColor = .white
    navigationItem.title = "Me"
    navigationItem.setRightBarButton(logoutBarButtonItem, animated: false)
    collectionView?.showsVerticalScrollIndicator = false
    
    let bgImage = UIImageView()
    bgImage.image = #imageLiteral(resourceName: "BlankFeed")
    bgImage.contentMode = .scaleAspectFill
    collectionView?.backgroundView = bgImage
    collectionView?.backgroundView?.alpha = 0.0
  }
  
  fileprivate func clearPosts() {
    // MARK: FirebaseMagic - Remove current user posts if any
    FirebaseMagic.fetchedUserPosts.removeAll()
    FirebaseMagic.fetchedUserPostsCurrentKey = nil
    collectionView?.reloadData()
  }
  
  fileprivate func fetchPosts(completion: @escaping (_ result: Bool) -> ()) {
    // MARK: FirebaseMagic - Fetch current user posts
    let hud = JGProgressHUD(style: .light)
    FirebaseMagicService.showHud(hud, text: "Fetching user posts...")
    FirebaseMagic.fetchUserPosts(forUid: FirebaseMagic.currentUserUid(), fetchType: .onUserProfile, in: self, completion: { (result, err) in
      if let err = err {
        print("Failed to fetch user posts with err:", err)
        FirebaseMagicService.dismiss(hud, afterDelay: nil, text: nil)
        FirebaseMagicService.showAlert(style: .alert, title: "Fetch error", message: "Failed to fetch user posts with err: \(err)")
        completion(false)
        return
      } else if result == false {
        FirebaseMagicService.dismiss(hud, afterDelay: nil, text: "Could not fetch...")
        completion(false)
        return
      }
      print("Successfully fetched user posts")
      FirebaseMagicService.dismiss(hud, afterDelay: nil, text: nil)
      completion(true)
    })
  }
  
  fileprivate func reloadAllPosts(completion: @escaping (_ result: Bool) -> ()) {
    clearPosts()
    fetchPosts { (result) in
      completion(result)
    }
  }
  
  override func handleRefresh() {
    fetchCurrentUser() { (currentUser) in
      self.reloadAllPosts { (result) in
        self.refreshControl.endRefreshing()
      }
    }
  }
  
  @objc fileprivate func handleFollowersButtonTapped() {
    let controller = UserStatsDatasourceController()
    controller.statsType = .followers
    let navController = UINavigationController(rootViewController: controller)
    self.navigationController?.present(navController, animated: true, completion: nil)
  }
  
  @objc fileprivate func handleFollowingButtonTapped() {
    let controller = UserStatsDatasourceController()
    controller.statsType = .following
    let navController = UINavigationController(rootViewController: controller)
    self.navigationController?.present(navController, animated: true, completion: nil)
  }
  
  fileprivate func deleteCurrentUserSession() {
    
  }
  
  override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
    
    // MARK: FirebaseMagic - Trigger pagination when last item will be displayed on user profile
    if FirebaseMagic.fetchedUserPosts.count > FirebaseMagic.paginationElementsLimitUserPosts - 1 {
      if indexPath.row == FirebaseMagic.fetchedUserPosts.count - 1 {
        fetchPosts { (result) in
          print("Paginated user posts with result:", result)
        }
      }
    }
    
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
    return CGSize(width: ScreenSize.width, height: 180)
  }
  
  override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    let width = (ScreenSize.width - 2) / 3
    return CGSize(width: width, height: width)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
    return 1
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return 1
  }
  
}

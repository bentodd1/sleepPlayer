
import UIKit
import AVFoundation
import MediaPlayer
import SwiftyStoreKit
import StoreKit


extension UIImageView {
    
    func setRounded() {
        let radius = self.frame.width / 2
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}

enum RegisteredPurchase : String {
    case Dolla10 = "10Dolla"
    case RemoveAds = "RemoveAds"
    case autoRenewable = "autoRenewable"
}




class PlayerViewController: UIViewController, UITableViewDelegate,UITableViewDataSource,AVAudioPlayerDelegate {
    
    //Choose background here. Between 1 - 7
    let selectedBackground = 1
    
    
    var audioPlayer:AVAudioPlayer! = nil
    var currentAudio = ""
    var currentAudioPath:URL!
    var audioList:NSArray!
    var currentAudioIndex = 0
    var timer:Timer!
    var audioLength = 0.0
    var toggle = true
    var effectToggle = true
    var totalLengthOfAudio = ""
    var finalImage:UIImage!
    var isTableViewOnscreen = false
    var shuffleState = false
    var repeatState = false
    var shuffleArray = [Int]()
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet var songNo : UILabel!
    @IBOutlet var lineView : UIView!
    @IBOutlet weak var albumArtworkImageView: UIImageView!
    @IBOutlet weak var artistNameLabel: UILabel!
    @IBOutlet weak var albumNameLabel: UILabel!
    @IBOutlet var songNameLabel : UILabel!
    @IBOutlet var songNameLabelPlaceHolder : UILabel!
    @IBOutlet var progressTimerLabel : UILabel!
    @IBOutlet var playerProgressSlider : UISlider!
    @IBOutlet var totalLengthOfAudioLabel : UILabel!
    @IBOutlet var previousButton : UIButton!
    @IBOutlet var playButton : UIButton!
    @IBOutlet var nextButton : UIButton!
    @IBOutlet var listButton : UIButton!
    @IBOutlet var tableView : UITableView!
    @IBOutlet var blurImageView : UIImageView!
    @IBOutlet var enhancer : UIView!
    @IBOutlet var tableViewContainer : UIView!
    @IBOutlet var _username: UITextField!
    @IBOutlet var _password: UITextField!
    @IBOutlet var _login_button: UIButton!
    
    @IBOutlet weak var shuffleButton: UIButton!
    @IBOutlet weak var repeatButton: UIButton!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    
    @IBOutlet weak var tableViewContainerTopConstrain: NSLayoutConstraint!
    
    
    //MARK:- Lockscreen Media Control
    
    // This shows media info on lock screen - used currently and perform controls
    func showMediaInfo(){
        let artistName = readArtistNameFromPlist(currentAudioIndex)
        let songName = readSongNameFromPlist(currentAudioIndex)
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [MPMediaItemPropertyArtist : artistName,  MPMediaItemPropertyTitle : songName]
        //presentListTableView(self)
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        if event!.type == UIEventType.remoteControl{
            switch event!.subtype{
            case UIEventSubtype.remoteControlPlay:
                play(self)
            case UIEventSubtype.remoteControlPause:
                play(self)
            case UIEventSubtype.remoteControlNextTrack:
                next(self)
            case UIEventSubtype.remoteControlPreviousTrack:
                previous(self)
            default:
                print("There is an issue with the control")
            }
        }
    }
    
        //MARK-
    
    
    // Table View Part of the code. Displays Song name and Artist Name
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell  {
        var songNameDict = NSDictionary();
        songNameDict = audioList.object(at: (indexPath as NSIndexPath).row) as! NSDictionary
        let songName = songNameDict.value(forKey: "songName") as! String
        
        var albumNameDict = NSDictionary();
        albumNameDict = audioList.object(at: (indexPath as NSIndexPath).row) as! NSDictionary
        let albumName = albumNameDict.value(forKey: "albumName") as! String
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-BookIta", size: 25.0)
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.text = songName
        
        cell.detailTextLabel?.font = UIFont(name: "BodoniSvtyTwoITCTT-Book", size: 16.0)
        cell.detailTextLabel?.textColor = UIColor.white
        cell.detailTextLabel?.text = "purchase"
        //cell.detailTextLabel?.
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 54.0
    }
    
    
    
    func tableView(_ tableView: UITableView,willDisplay cell: UITableViewCell,forRowAt indexPath: IndexPath){
        tableView.backgroundColor = UIColor.clear
        
        let backgroundView = UIView(frame: CGRect.zero)
        backgroundView.backgroundColor = UIColor.clear
        cell.backgroundView = backgroundView
        cell.backgroundColor = UIColor.clear
    }
    
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        animateTableViewToOffScreen()
        currentAudioIndex = (indexPath as NSIndexPath).row
        prepareAudio()
        playAudio()
        effectToggle = !effectToggle
        let showList = UIImage(named: "list")
        let removeList = UIImage(named: "listS")
        effectToggle ? "\(listButton.setImage( showList, for: UIControlState()))" : "\(listButton.setImage(removeList , for: UIControlState()))"
        let play = UIImage(named: "play")
        let pause = UIImage(named: "pause")
        audioPlayer.isPlaying ? "\(playButton.setImage( pause, for: UIControlState()))" : "\(playButton.setImage(play , for: UIControlState()))"
        
        blurView.isHidden = true
       // presentListTableView(self)

    }
    
    class NetworkActivityIndicatorManager : NSObject {
        
        private static var loadingCount = 0
        
        class func NetworkOperationStarted() {
            if loadingCount == 0 {
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            loadingCount += 1
        }
        class func networkOperationFinished(){
            if loadingCount > 0 {
                loadingCount -= 1
                
            }
            
            if loadingCount == 0 {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                
            }
        }
    }
    
    func purchase(purchase : RegisteredPurchase) {
        NetworkActivityIndicatorManager.NetworkOperationStarted()
        SwiftyStoreKit.purchaseProduct("bundleID" + "." + purchase.rawValue, completion: {
            result in
            NetworkActivityIndicatorManager.networkOperationFinished()
            
            if case .success(let product) = result {
                
                if product.productId == "bundleID" + "." + "10Dolla"{
                    
                   // 0 += 10
                   // self.MoneyLbl.text = "\(self.Money)"
                    
                }
               // if product.productId == self.bundleID + "." + "RemoveAds" {
                    
                   // self.Money += 100
                    // self.MoneyLbl.text = "\(self.Money)"
               // }
                
                if product.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(product.transaction)
                }
               // self.showAlert(alert: self.alertForPurchaseResult(result: result))
            }
            
            
        })
        
    }
    
    

    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.default
    }
    
    override var prefersStatusBarHidden : Bool {
        
        if isTableViewOnscreen{
            return true
        }else{
            return false
        }
    }
    
    
    
    
    override func viewDidLoad() {
        print("View Did Load")
        //effectToggle = !effectToggle
        let preferences = UserDefaults.standard
        
        if(preferences.object(forKey: "session") != nil)
        {
           // presentListTableView(self)
          //  LoginDone()
        }
        else
        {
           // presentListTableView(self)
           // LoginToDo()
        }
        super.viewDidLoad()
        
        //assing background
        backgroundImageView.image = UIImage(named: "background\(selectedBackground)")
        
        //this sets last listened trach number as current
        retrieveSavedTrackNumber()
        prepareAudio()
        
        updateLabels()
        assingSliderUI()
        setRepeatAndShuffle()
        retrievePlayerProgressSliderValue()
        //LockScreen Media control registry
        if UIApplication.shared.responds(to: #selector(UIApplication.beginReceivingRemoteControlEvents)){
            UIApplication.shared.beginReceivingRemoteControlEvents()
            UIApplication.shared.beginBackgroundTask(expirationHandler: { () -> Void in
            })
        }
       // presentListTableView(self)

    }

    
    func setRepeatAndShuffle(){
        shuffleState = UserDefaults.standard.bool(forKey: "shuffleState")
        repeatState = UserDefaults.standard.bool(forKey: "repeatState")
        if shuffleState == true {
            shuffleButton.isSelected = true
        } else {
            shuffleButton.isSelected = false
        }
        
        if repeatState == true {
            repeatButton.isSelected = true
        }else{
            repeatButton.isSelected = false
        }
    
    }
    
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tableViewContainerTopConstrain.constant = 1000.0
        self.tableViewContainer.layoutIfNeeded()
        blurView.isHidden = true
        presentListTableView(self)
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        albumArtworkImageView.setRounded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK:- AVAudioPlayer Delegate's Callback method
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool){
        if flag == true {
            
            if shuffleState == false && repeatState == false {
                // do nothing
                playButton.setImage( UIImage(named: "play"), for: UIControlState())
                return
            
            } else if shuffleState == false && repeatState == true {
            //repeat same song
                prepareAudio()
                playAudio()
            
            } else if shuffleState == true && repeatState == false {
            //shuffle songs but do not repeat at the end
            //Shuffle Logic : Create an array and put current song into the array then when next song come randomly choose song from available song and check against the array it is in the array try until you find one if the array and number of songs are same then stop playing as all songs are already played.
               shuffleArray.append(currentAudioIndex)
                if shuffleArray.count >= audioList.count {
                playButton.setImage( UIImage(named: "play"), for: UIControlState())
                return
                
                }
                
                
                var randomIndex = 0
                var newIndex = false
                while newIndex == false {
                    randomIndex =  Int(arc4random_uniform(UInt32(audioList.count)))
                    if shuffleArray.contains(randomIndex) {
                        newIndex = false
                    }else{
                        newIndex = true
                    }
                }
                currentAudioIndex = randomIndex
                prepareAudio()
                playAudio()
            
            } else if shuffleState == true && repeatState == true {
                //shuffle song endlessly
                shuffleArray.append(currentAudioIndex)
                if shuffleArray.count >= audioList.count {
                    shuffleArray.removeAll()
                }
                
                
                var randomIndex = 0
                var newIndex = false
                while newIndex == false {
                    randomIndex =  Int(arc4random_uniform(UInt32(audioList.count)))
                    if shuffleArray.contains(randomIndex) {
                        newIndex = false
                    }else{
                        newIndex = true
                    }
                }
                currentAudioIndex = randomIndex
                prepareAudio()
                playAudio()
                
            
            }
            
        }
    }
    
    
    //Sets audio file URL
    func setCurrentAudioPath(){
        currentAudio = readSongNameFromPlist(currentAudioIndex)
        print("\(currentAudio)")
        currentAudioPath = URL(fileURLWithPath: Bundle.main.path(forResource: currentAudio, ofType: "mp3")!)
        print("\(currentAudioPath)")
    }
    
    
    func saveCurrentTrackNumber(){
        UserDefaults.standard.set(currentAudioIndex, forKey:"currentAudioIndex")
        UserDefaults.standard.synchronize()
        
    }
    
    func retrieveSavedTrackNumber(){
        if let currentAudioIndex_ = UserDefaults.standard.object(forKey: "currentAudioIndex") as? Int{
            currentAudioIndex = currentAudioIndex_
        }else{
            currentAudioIndex = 0
        }
    }


    
    // Prepare audio for playing
    func prepareAudio(){
        setCurrentAudioPath()
        do {
            //keep alive audio at background
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        } catch _ {
        }
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch _ {
        }
        UIApplication.shared.beginReceivingRemoteControlEvents()
        audioPlayer = try? AVAudioPlayer(contentsOf: currentAudioPath)
        audioPlayer.delegate = self
        audioLength = audioPlayer.duration
        playerProgressSlider.maximumValue = CFloat(audioPlayer.duration)
        playerProgressSlider.minimumValue = 0.0
        playerProgressSlider.value = 0.0
        audioPlayer.prepareToPlay()
        showTotalSongLength()
        updateLabels()
        progressTimerLabel.text = "00:00"
        
        //print("Preparing audio")
        
        
    }
    
    //MARK:- Player Controls Methods
    func  playAudio(){
        audioPlayer.play()
        startTimer()
        updateLabels()
        saveCurrentTrackNumber()
        showMediaInfo()
    }
    
    func playNextAudio(){
        currentAudioIndex += 1
        if currentAudioIndex>audioList.count-1{
            currentAudioIndex -= 1
            
            return
        }
        if audioPlayer.isPlaying{
            prepareAudio()
            playAudio()
        }else{
            prepareAudio()
        }
        
    }
    
    
    func playPreviousAudio(){
        currentAudioIndex -= 1
        if currentAudioIndex<0{
            currentAudioIndex += 1
            return
        }
        if audioPlayer.isPlaying{
            prepareAudio()
            playAudio()
        }else{
            prepareAudio()
        }
        
    }
    
    
    func stopAudiplayer(){
        audioPlayer.stop();
        
    }
    
    func pauseAudioPlayer(){
        audioPlayer.pause()
        
    }
    
    
    //MARK:-
    
    func startTimer(){
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(PlayerViewController.update(_:)), userInfo: nil,repeats: true)
            timer.fire()
        }
    }
    
    func stopTimer(){
        timer.invalidate()
        
    }
    
    
    func update(_ timer: Timer){
        if !audioPlayer.isPlaying{
            return
        }
        let time = calculateTimeFromNSTimeInterval(audioPlayer.currentTime)
        progressTimerLabel.text  = "\(time.minute):\(time.second)"
        playerProgressSlider.value = CFloat(audioPlayer.currentTime)
        UserDefaults.standard.set(playerProgressSlider.value , forKey: "playerProgressSliderValue")

        
    }
    
    func retrievePlayerProgressSliderValue(){
        let playerProgressSliderValue =  UserDefaults.standard.float(forKey: "playerProgressSliderValue")
        if playerProgressSliderValue != 0 {
            playerProgressSlider.value  = playerProgressSliderValue
            audioPlayer.currentTime = TimeInterval(playerProgressSliderValue)
            
            let time = calculateTimeFromNSTimeInterval(audioPlayer.currentTime)
            progressTimerLabel.text  = "\(time.minute):\(time.second)"
            playerProgressSlider.value = CFloat(audioPlayer.currentTime)
            
        }else{
            playerProgressSlider.value = 0.0
            audioPlayer.currentTime = 0.0
            progressTimerLabel.text = "00:00:00"
        }
    }

    
    
    //This returns song length
    func calculateTimeFromNSTimeInterval(_ duration:TimeInterval) ->(minute:String, second:String){
       // let hour_   = abs(Int(duration)/3600)
        let minute_ = abs(Int((duration/60).truncatingRemainder(dividingBy: 60)))
        let second_ = abs(Int(duration.truncatingRemainder(dividingBy: 60)))
        
       // var hour = hour_ > 9 ? "\(hour_)" : "0\(hour_)"
        let minute = minute_ > 9 ? "\(minute_)" : "0\(minute_)"
        let second = second_ > 9 ? "\(second_)" : "0\(second_)"
        return (minute,second)
    }
    

    
    func showTotalSongLength(){
        calculateSongLength()
        totalLengthOfAudioLabel.text = totalLengthOfAudio
    }
    
    
    func calculateSongLength(){
        let time = calculateTimeFromNSTimeInterval(audioLength)
        totalLengthOfAudio = "\(time.minute):\(time.second)"
    }
    
    
    //Read plist file and creates an array of dictionary
    func readFromPlist(){
        let path = Bundle.main.path(forResource: "list", ofType: "plist");
        print ("\(path)");
        audioList = NSArray(contentsOfFile:path!)
    }
    
    func readArtistNameFromPlist(_ indexNumber: Int) -> String {
        readFromPlist()
        var infoDict = NSDictionary();
        infoDict = audioList.object(at: indexNumber) as! NSDictionary
        let artistName = infoDict.value(forKey: "artistName") as! String
        return artistName
    }
    
    func readAlbumNameFromPlist(_ indexNumber: Int) -> String {
        readFromPlist()
        var infoDict = NSDictionary();
        infoDict = audioList.object(at: indexNumber) as! NSDictionary
        let albumName = infoDict.value(forKey: "albumName") as! String
        return albumName
    }

    
    func readSongNameFromPlist(_ indexNumber: Int) -> String {
        readFromPlist()
        var songNameDict = NSDictionary();
        songNameDict = audioList.object(at: indexNumber) as! NSDictionary
        let songName = songNameDict.value(forKey: "songName") as! String
        return songName
    }
    
    func readArtworkNameFromPlist(_ indexNumber: Int) -> String {
        readFromPlist()
        var infoDict = NSDictionary();
        infoDict = audioList.object(at: indexNumber) as! NSDictionary
        let artworkName = infoDict.value(forKey: "albumArtwork") as! String
        return artworkName
    }

    
    func updateLabels(){
        updateArtistNameLabel()
        updateAlbumNameLabel()
        updateSongNameLabel()
        updateAlbumArtwork()

        
    }
    
    
    func updateArtistNameLabel(){
        let artistName = readArtistNameFromPlist(currentAudioIndex)
        artistNameLabel.text = artistName
    }
    func updateAlbumNameLabel(){
        let albumName = readAlbumNameFromPlist(currentAudioIndex)
        albumNameLabel.text = albumName
    }
    
    func updateSongNameLabel(){
        let songName = readSongNameFromPlist(currentAudioIndex)
        songNameLabel.text = songName
    }
    
    func updateAlbumArtwork(){
        let artworkName = readArtworkNameFromPlist(currentAudioIndex)
        albumArtworkImageView.image = UIImage(named: artworkName)
    }
    
  
    //creates animation and push table view to screen
    func animateTableViewToScreen(){
        self.blurView.isHidden = false
        UIView.animate(withDuration: 0.15, delay: 0.01, options:
            UIViewAnimationOptions.curveEaseIn, animations: {
            self.tableViewContainerTopConstrain.constant = 0.0
            self.tableViewContainer.layoutIfNeeded()
            }, completion: { (bool) in
        })
        
    }
    
    
    
    
    func animateTableViewToOffScreen(){
        isTableViewOnscreen = false
        setNeedsStatusBarAppearanceUpdate()
        self.tableViewContainerTopConstrain.constant = 1000.0
        UIView.animate(withDuration: 0.20, delay: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
           self.tableViewContainer.layoutIfNeeded()
            
            }, completion: {
                (value: Bool) in
                self.blurView.isHidden = true
        })
    }
    
    
   
    func assingSliderUI () {
        let minImage = UIImage(named: "slider-track-fill")
        let maxImage = UIImage(named: "slider-track")
        let thumb = UIImage(named: "thumb")

        playerProgressSlider.setMinimumTrackImage(minImage, for: UIControlState())
        playerProgressSlider.setMaximumTrackImage(maxImage, for: UIControlState())
        playerProgressSlider.setThumbImage(thumb, for: UIControlState())

    
    }
    
    
    
    @IBAction func play(_ sender : AnyObject) {
        
        if shuffleState == true {
            shuffleArray.removeAll()
        }
        let play = UIImage(named: "play")
        let pause = UIImage(named: "pause")
        if audioPlayer.isPlaying{
            pauseAudioPlayer()
            audioPlayer.isPlaying ? "\(playButton.setImage( pause, for: UIControlState()))" : "\(playButton.setImage(play , for: UIControlState()))"
            
        }else{
            playAudio()
            audioPlayer.isPlaying ? "\(playButton.setImage( pause, for: UIControlState()))" : "\(playButton.setImage(play , for: UIControlState()))"
        }
    }
    
    
    
    @IBAction func next(_ sender : AnyObject) {
        playNextAudio()
       // presentListTableView(self)
        
    }
    
    
    @IBAction func previous(_ sender : AnyObject) {
        playPreviousAudio()
    }
    
    
    
    
    @IBAction func changeAudioLocationSlider(_ sender : UISlider) {
        audioPlayer.currentTime = TimeInterval(sender.value)
        
    }
    
    
    @IBAction func userTapped(_ sender : UITapGestureRecognizer) {
        
        play(self)
    }
    
    @IBAction func userSwipeLeft(_ sender : UISwipeGestureRecognizer) {
        next(self)
    }
    
    @IBAction func userSwipeRight(_ sender : UISwipeGestureRecognizer) {
        previous(self)
    }
    
    @IBAction func userSwipeUp(_ sender : UISwipeGestureRecognizer) {
        presentListTableView(self)
    }
    
    
    @IBAction func shuffleButtonTapped(_ sender: UIButton) {
        shuffleArray.removeAll()
        if sender.isSelected == true {
        sender.isSelected = false
        shuffleState = false
        UserDefaults.standard.set(false, forKey: "shuffleState")
        } else {
        sender.isSelected = true
        shuffleState = true
        UserDefaults.standard.set(true, forKey: "shuffleState")
        }
        
        
        
    }
    
    
    @IBAction func repeatButtonTapped(_ sender: UIButton) {
        if sender.isSelected == true {
            sender.isSelected = false
            repeatState = false
            UserDefaults.standard.set(false, forKey: "repeatState")
        } else {
            sender.isSelected = true
            repeatState = true
            UserDefaults.standard.set(true, forKey: "repeatState")
        }

        
    }
    
    
    
    
    @IBAction func presentListTableView(_ sender : AnyObject) {
       //effectToggle = !effectToggle
        //print("animate table view on screen")
        if effectToggle{
            print("animate table view to on screen")
            isTableViewOnscreen = true
            setNeedsStatusBarAppearanceUpdate()
            self.animateTableViewToScreen()
            
        }else{
            print("animate table view to off screen")
            self.animateTableViewToOffScreen()
            
        }
        effectToggle = !effectToggle
        let showList = UIImage(named: "list")
        let removeList = UIImage(named: "listS")
        effectToggle ? "\(listButton.setImage( showList, for: UIControlState()))" : "\(listButton.setImage(removeList , for: UIControlState()))"
        
    }
    
    

    
    
    @IBAction func LoginButton(_ sender: Any) {
        
        if(_login_button.titleLabel?.text == "Logout")
        {
            let preferences = UserDefaults.standard
            preferences.removeObject(forKey: "session")
            
            LoginToDo()
            return
        }
        
        
        let username = _username.text
        let password = _password.text
        
        if(username == "" || password == "")
        {
            return
        }
        
        DoLogin(username!, password!)
    }
    
    
    func DoLogin(_ user:String, _ psw:String)
    {
        let url = URL(string: "http://www.kaleidosblog.com/tutorial/login/api/login")
        let session = URLSession.shared
        
        let request = NSMutableURLRequest(url: url!)
        request.httpMethod = "POST"
        
        let paramToSend = "username=" + user + "&password=" + psw
        
        request.httpBody = paramToSend.data(using: String.Encoding.utf8)
        
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {
            (data, response, error) in
            
            guard let _:Data = data else
            {
                return
            }
            
            let json:Any?
            
            do
            {
                json = try JSONSerialization.jsonObject(with: data!, options: [])
            }
            catch
            {
                return
            }
            
            
            guard let server_response = json as? NSDictionary else
            {
                return
            }
            
            
            if let data_block = server_response["data"] as? NSDictionary
            {
                if let session_data = data_block["session"] as? String
                {
                    let preferences = UserDefaults.standard
                    preferences.set(session_data, forKey: "session")
                    
                    DispatchQueue.main.async (
                        execute:self.LoginDone
                    )
                }
            }
            
        })
        
        task.resume()
    }
    
    
    func LoginToDo()
    {
        _username.isEnabled = true
        _password.isEnabled = true
        
        _login_button.setTitle("Login", for: .normal)
    }
    
    func LoginDone()
    {
        _username.isEnabled = false
        _password.isEnabled = false
        
        _login_button.setTitle("Logout", for: .normal)
    }
    
    
    @IBOutlet weak var TableViewIsClicked: UITableView!
    
    @IBAction func Next(_ sender: Any) {
    }
}

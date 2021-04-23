import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var listener: ListenerRegistration? = nil;
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        tableView.delegate = self
        messageTextfield.delegate = self
        tableView.dataSource = self
        title = K.appName
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
    }
    
    func loadMessages() {
// .order sorts by
// .addSnapShotListener refreshes when the entire function when a new object is added into the firstore database
        listener = db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)
            .addSnapshotListener { (querySnapShot, error) in
            
            self.messages = [] // avoids duplicates
            
            if let e = error {
                print("There was an issue retriving data from FireStore. \(e)")
            }else {
                if let snapshotDocuments = querySnapShot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        // downcasting to optional string instead of any
                        if let messageSender = data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField] as? String {
                            let newMessage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage)
                            
                            DispatchQueue.main.async {
                                self.tableView.reloadData() // reloads the tableview to load the data
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                // scrolls to the bottom
                                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                            }
                        }
                            
                    }
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
        if (messageTextfield.text != "") {
            if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email {
                db.collection(K.FStore.collectionName).addDocument(data: [
                    K.FStore.senderField: messageSender,
                    K.FStore.bodyField: messageBody,
                    K.FStore.dateField: Date().timeIntervalSince1970
                ]) { (error) in
                    if let e = error {
                        print("There was an issue saving data to firestore, \(e)")
                    }else {
                        print("Successfully saved data.")
                        //happens on the main thread
                        DispatchQueue.main.async {
                            self.messageTextfield.text = "";
                        }
                    }
                }
            }
        }

    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
    do {
      try Auth.auth().signOut()
        listener?.remove();
        navigationController?.popToRootViewController(animated: true)
    } catch let signOutError as NSError {
      print ("Error signing out: %@", signOutError)
    }
    }
    
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier) as! MessageCell // uses custom nib file instead of generic "as!" is type casting
//        cell?.textLabel?.text = "This is a cell"
//        cell?.textLabel?.text = messages[indexPath.row].body
        cell.label.text = message.body
        
        if message.sender == Auth.auth().currentUser?.email { // This is message from current logged in user
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        }
        // this is a message from another sende.
        else {
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
        }

        return cell
    }
}

    // Used to check what the user did at the particular cell, eg: - To Do list check off
//extension ChatViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print(indexPath.row)
//    }
//}

extension ChatViewController: UITextFieldDelegate {

   
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("inside chat");
        if (messageTextfield.text != "") {
            if let messageBody = messageTextfield.text, let messageSender = Auth.auth().currentUser?.email {
                db.collection(K.FStore.collectionName).addDocument(data: [
                    K.FStore.senderField: messageSender,
                    K.FStore.bodyField: messageBody,
                    K.FStore.dateField: Date().timeIntervalSince1970
                ]) { (error) in
                    if let e = error {
                        print("There was an issue saving data to firestore, \(e)")
                    }else {
                        print("Successfully saved data.")
                        //happens on the main thread
                        DispatchQueue.main.async {
                            self.messageTextfield.text = "";
                        }
                    }
                }
            }
        }
        return true
    }
        
}
    

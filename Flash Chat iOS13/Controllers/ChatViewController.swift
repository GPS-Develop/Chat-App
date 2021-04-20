import UIKit
import Firebase

class ChatViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextfield: UITextField!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        tableView.delegate = self
        tableView.dataSource = self
        title = K.appName
        navigationItem.hidesBackButton = true
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)
        
        loadMessages()
    }
    
    func loadMessages() {
// .order sorts by
// .addSnapShotListener refreshes when the entire function when a new object is added into the firstore database
        db.collection(K.FStore.collectionName)
            .order(by: K.FStore.dateField)
            .addSnapshotListener { (querySnapShot, error) in
            
            self.messages = [] // avoids duplicates
            
            if let e = error {
                print("There waqs an issue retriving data from FireStore. \(e)")
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
                            }
                        }
                            
                    }
                }
            }
        }
    }
    
    @IBAction func sendPressed(_ sender: UIButton) {
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
                }
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
    do {
      try Auth.auth().signOut()
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
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier) as! MessageCell // uses custom nib file instead of generic "as!" is type casting
//        cell?.textLabel?.text = "This is a cell"
//        cell?.textLabel?.text = messages[indexPath.row].body
        cell.label.text = messages[indexPath.row].body
        return cell
    }
}

    // Used to check what the user did at the particular cell, eg: - To Do list check off
//extension ChatViewController: UITableViewDelegate {
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print(indexPath.row)
//    }
//}

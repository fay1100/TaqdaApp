//
//  ViewController.swift
//  TaqdaApp
//
//  Created by Rahaf ALghuraibi on 14/05/1446 AH.
//

import SwiftUI
import UIKit
import CloudKit
import SwiftUI

struct ViewControllerWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        // Leave empty for now, as no updates are needed.
    }
}
class ViewController: UIViewController {

    let cloudKitManager = CloudKitManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // Example usage
        saveListExample()
    }

    func saveListExample() {
        // Example owner reference (replace "owner_id" with a real record name)
        let ownerReference = CKRecord.Reference(recordID: CKRecord.ID(recordName: "owner_id"), action: .none)

        // Create a new list
        let newList = List(
            listName: "Grocery Shopping",
            isShared: false,
            ownedId: ownerReference,
            totalItems: 10,
            isFavorite: true
        )

        // Save the list to CloudKit
        cloudKitManager.addList(list: newList) { result in
            switch result {
            case .success(let record):
                print("List saved successfully: \(record)")
            case .failure(let error):
                print("Error saving list: \(error.localizedDescription)")
            }
        }
    }
}

// #Preview block (for SwiftUI Previews)
import SwiftUI
struct ViewControllerPreview: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> ViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {}
}

#Preview {
    ViewControllerPreview()
}

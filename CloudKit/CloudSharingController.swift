//
//  CloudSharingController.swift
//  TurboList
//
//  Created by Rahaf ALghuraibi on 04/05/1446 AH.
//
import SwiftUI
import CloudKit

struct CloudSharingController: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) {
            print("Share successfully created.")
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            print("Stopped sharing the record.")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            return "Collaborative List"
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("Failed to save share: \(error.localizedDescription)")
        }

        func cloudSharingController(_ csc: UICloudSharingController, willStopSharing item: CKRecord) {
            print("Will stop sharing item: \(item.recordID)")
        }
    }
}

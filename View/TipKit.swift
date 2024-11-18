import Foundation
import TipKit

struct AddItemTip: Tip {
    var title: Text {
        Text("Add Items to Your Grocery List")
    }

    var message: Text? {
        Text("Separate items using a comma, or list each item on a new line.")
    }

//    var image: Image? {
//        Image(systemName: "info.circle")
//
//    }
}

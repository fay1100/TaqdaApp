import Foundation
import SwiftUI
import UIKit

struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: CustomTextField
        var isPlaceholderVisible = true
        
        init(_ parent: CustomTextField) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if isPlaceholderVisible {
                textView.text = ""
                textView.textColor = UIColor(named: "nameColor") ?? UIColor.black // استخدم nameColor هنا
                isPlaceholderVisible = false
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = UIColor(named: "CustomDarkGray") ?? UIColor.systemGray
                isPlaceholderVisible = true
            } else {
                parent.text = textView.text
                textView.textColor = UIColor(named: "nameColor") ?? UIColor.black // استخدم nameColor هنا
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            if !isPlaceholderVisible {
                parent.text = textView.text
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor(named: "CustomDarkGray") ?? UIColor.systemGray
            context.coordinator.isPlaceholderVisible = true
        } else {
            textView.text = text
            textView.textColor = UIColor(named: "nameColor") ?? UIColor.black // استخدم nameColor هنا
            context.coordinator.isPlaceholderVisible = false
        }
        
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.isScrollEnabled = true
        
        // إعدادات التصحيح الإملائي
        textView.autocorrectionType = .yes // تمكين التصحيح التلقائي
        textView.spellCheckingType = .yes // تمكين تصحيح الإملاء
        textView.layer.borderWidth = 0
        textView.layer.borderColor = UIColor(named: "bakgroundTap")?.cgColor
        textView.layer.cornerRadius = 11
        textView.backgroundColor = UIColor(named: "bakgroundTap")

        textView.layer.shadowColor = UIColor.black.cgColor
        textView.layer.shadowOpacity = 0.1
        textView.layer.shadowOffset = CGSize(width: 0, height: 5)
        textView.layer.shadowRadius = 10
        textView.layer.masksToBounds = false
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if text.isEmpty && !uiView.isFirstResponder {
            uiView.text = placeholder
            uiView.textColor = UIColor(named: "CustomDarkGray") ?? UIColor.systemGray
            context.coordinator.isPlaceholderVisible = true
        } else if !text.isEmpty && context.coordinator.isPlaceholderVisible {
            uiView.text = text
            uiView.textColor = UIColor(named: "nameColor") ?? UIColor.black // استخدم nameColor هنا
            context.coordinator.isPlaceholderVisible = false
        }
    }
}

struct ExpandingTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var dynamicHeight: CGFloat
    var placeholder: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.delegate = context.coordinator

        // إعداد النص الافتراضي (placeholder) إذا كان النص فارغًا
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = UIColor.gray
        } else {
            textView.text = text
            textView.textColor = UIColor.black
        }

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // التأكد من عدم تغيير النص إذا كان المستخدم يكتب أو إذا كان النص الافتراضي موجودًا
        if uiView.text == placeholder && !text.isEmpty {
            uiView.text = text
            uiView.textColor = UIColor.black
        }

        // لا تعيين النص الافتراضي إذا كان النص فارغًا هنا
        if uiView.text.isEmpty && !text.isEmpty {
            uiView.text = text
            uiView.textColor = UIColor.black
        }

        // تحديث ارتفاع النص
        ExpandingTextField.recalculateHeight(view: uiView, result: $dynamicHeight)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ExpandingTextField

        init(_ parent: ExpandingTextField) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            // عند بداية الكتابة، يتم مسح النص الافتراضي فقط
            if textView.text == parent.placeholder {
                textView.text = ""
                textView.textColor = UIColor.black
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            // إذا انتهى المستخدم من الكتابة وترك الحقل فارغًا، أعد النص الافتراضي
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = UIColor.gray
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            // تحديث النص الحقيقي عند التغيير
            parent.text = textView.text == parent.placeholder ? "" : textView.text
            ExpandingTextField.recalculateHeight(view: textView, result: parent.$dynamicHeight)
        }
    }

    private static func recalculateHeight(view: UIView, result: Binding<CGFloat>) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.width, height: CGFloat.greatestFiniteMagnitude))
        if result.wrappedValue != newSize.height {
            DispatchQueue.main.async {
                result.wrappedValue = newSize.height
            }
        }
    }
}

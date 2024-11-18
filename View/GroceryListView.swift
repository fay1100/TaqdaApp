//
//  GroceryListView.swift
//  TaqdaApp
//
//  Created by Faizah Almalki on 13/05/1446 AH.
//

import Foundation
import SwiftUI

//struct CollaborativeGroceryListView: View {
//    @State private var isHeartSelected: Bool = false
//    var body: some View {
//        VStack(spacing: 16) {
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Collaborative list")
//                    .font(.system(size: 20, weight: .bold))
//                    .foregroundColor(.white)
//                    .frame(width: 200, alignment: .leading)
//
//                HStack {
//                    Image(systemName: "person.2.circle")
//                        .foregroundColor(Color("Color44"))
//                        .font(.system(size: 30))
//
//                    Button(action: {
//                        isHeartSelected.toggle()
//                    }) {
//                        ZStack {
//                            if isHeartSelected {
//                                Circle()
//                                    .fill(Color.white)
//                                    .frame(width: 30, height: 30)
//
//                                Image(systemName: "heart.fill")
//                                    .foregroundColor(.red)
//                                    .font(.system(size: 17))
//                            } else {
//                                Image(systemName: "heart.circle.fill")
//                                    .foregroundColor(.white)
//                                    .font(.system(size: 30))
//                            }
//                        }
//                        .frame(width: 30, height: 30)
//                    }
//                }
//            }
//            .offset(x: -40)
//            .frame(width: 350, height: 100)
//            .background(
//                LinearGradient(
//                    gradient: Gradient(stops: [
//                        .init(color: Color(hex: "051937"), location: 0.0),
//                        .init(color: Color(hex: "004D7A"), location: 0.25),
//                        .init(color: Color(hex: "008793"), location: 0.70),
//                        .init(color: Color(hex: "00BF72"), location: 1.3)
//                    ]),
//                    startPoint: .leading,
//                    endPoint: .trailing
//                )
//            )
//            .cornerRadius(20)
//            .shadow(radius: 5)
//        }
//    }
//}

struct GroceryListView: View {
    var listName: String
    @Binding var isHeartSelected: Bool
    var onHeartTapped: () -> Void // وظيفة ممررة لتحديث الحالة

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(listName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 50)
                
                HStack {
                    Button(action: {
                        onHeartTapped()
                    }) {
                        ZStack {
                            if isHeartSelected {
                                Circle()
                                    .fill(Color.white)
                                    .frame(width: 30, height: 30)
                                
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 17))
                                
                            } else {
                                Image(systemName: "heart.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 30))
                            }
                        }.padding(.trailing ,20)
                    }
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 30))
                        .padding(.leading ,-20)
                    
                }
            }
            .frame(width: 160, height: 190)
            .background(Color("PrimaryColor"))
            .cornerRadius(20)
        }
    }
}


#Preview {
    @State var isHeartSelectedPreview = false

    return VStack {
        GroceryListView(
            listName: "Sample List 1",
            isHeartSelected: $isHeartSelectedPreview,
            onHeartTapped: {
                isHeartSelectedPreview.toggle()
                print("Tapped on Sample List 1. New state: \(isHeartSelectedPreview)")
            }
        )
        
        GroceryListView(
            listName: "Sample List 2",
            isHeartSelected: $isHeartSelectedPreview,
            onHeartTapped: {
                isHeartSelectedPreview.toggle()
                print("Tapped on Sample List 2. New state: \(isHeartSelectedPreview)")
            }
        )
    }
}


//
//  CentralView.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 16/11/22.
//

import SwiftUI
import CoreBluetooth

struct CentralView: View {
    @ObservedObject var centralController = CentralController()
    
    var body: some View {
            VStack {
                Text("Central Screen")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height / 8)
                        .foregroundColor(.green)
                        .opacity(0.4)
                    )
                
                Spacer()
                
                List(centralController.peripherals, id: \.identifier) {
                    Text($0.name ?? "Bluetooth Device")
                }
                .listStyle(.automatic)
                .cornerRadius(10.0)
                
            }
            .edgesIgnoringSafeArea([.top])
            .padding()
        }
}

struct CentralView_Previews: PreviewProvider {
    static var previews: some View {
        CentralView()
            .previewLayout(.sizeThatFits)
    }
}

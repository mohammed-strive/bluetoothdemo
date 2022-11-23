//
//  PeripheralView.swift
//  bluetoothdemo
//
//  Created by Shaik mohammed Jaffer on 21/11/22.
//

import SwiftUI

struct PeripheralView: View {
    @ObservedObject var peripheralController = PeripheralController()
    var body: some View {
        VStack {
            Text("Waiting for a Central to Connect")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            ProgressView()
            
            NavigationView {
                NavigationLink(destination: PeripheralChatView(controller: peripheralController, user: peripheralController.peripheralUser ?? nil)) {
                    Text(peripheralController.centralConnected ? "Central": "Not connected yet")
                }
            }
        }
    }
}

struct PeripheralView_Previews: PreviewProvider {
    static var previews: some View {
        PeripheralView()
    }
}

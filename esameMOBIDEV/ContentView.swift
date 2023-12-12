//
//  ContentView.swift
//  esameMOBIDEV
//
//  Created by Marco on 11/06/21.
//

import SwiftUI
import RealityKit

struct ContentView : View {

    private let arvc = ARViewController(nibName: "ARViewController", bundle: .main)
    
    var body: some View {
        ZStack{
            ARViewContainer(arvc: arvc).edgesIgnoringSafeArea(.all)
        }
    }
}

struct ARViewContainer: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = ARViewController
    
    let arvc : ARViewController
    
    
    func makeUIViewController(context: Context) -> ARViewController {
        return self.arvc
    }
    
    func updateUIViewController(_ uiViewController: ARViewController, context: Context) {}
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif

//
//  ViewController.swift
//  AI-Assignment-1
//
//  Created by Samuel Pineda on 17/10/2016.
//  All rights reserved.
//

class Node {
    var estimatedValue = 0
    var children:[Node] = []
    
    init(estimatedValue: Int) {
        self.estimatedValue = estimatedValue
    }
    
    func addChild(n: Node) {
        children.append(n)
    }
}

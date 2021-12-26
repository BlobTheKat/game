//
//  API.swift
//  game
//
//  Created by Matthew on 16/12/2021.
//

import Foundation

struct api{
    static func position(completion: @escaping (_ x: Int, _ y: Int) -> ()){
        DispatchQueue.main.async {
            completion(secx, secy)
        }
    }
}

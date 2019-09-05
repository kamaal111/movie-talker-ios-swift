//
//  APIRequest.swift
//  movie-listener
//
//  Created by Kamaal Farah on 03/09/2019.
//  Copyright © 2019 Kamaal. All rights reserved.
//

import Foundation

func apiRequest(at url: String, for title: String, on page: String, completion: @escaping (_ res: [String: Any]) -> Void) {
    guard let url = URL(string: "\(url)/movies/search/\(title)/\(page)") else { return }
    let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
        guard let dataResponse = data, error == nil else {
            print(error?.localizedDescription ?? "Response Error")
            return
        }
        do {
            let jsonResponse = try JSONSerialization.jsonObject(with: dataResponse, options: [])
            completion(jsonResponse as! [String : Any])
        } catch let parsingError { print("Error", parsingError) }
    }
    task.resume()
}

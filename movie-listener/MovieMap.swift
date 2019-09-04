//
//  MovieMap.swift
//  movie-listener
//
//  Created by Kamaal Farah on 03/09/2019.
//  Copyright © 2019 Kamaal. All rights reserved.
//

struct MovieMap {
    var results: [[String: Any]]
    
    init(_ dict: [String: Any]) {
        self.results = dict["results"] as? [[String: Any]] ?? [[:]]
    }
}

//
//  Enums.swift
//  MyMovies
//
//  Created by Kerby Jean on 2/28/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation

enum HttpMethods: String {
    case PUT
}

enum Urls: CustomStringConvertible {
    
    case movieUrl
    case firebaseUrl
    
    var description: String {
        switch self {
        case .movieUrl:
            return "https://api.themoviedb.org/3/search/movie"
        case .firebaseUrl:
            return "https://sprint-9a616.firebaseio.com/"
        }
    }
}

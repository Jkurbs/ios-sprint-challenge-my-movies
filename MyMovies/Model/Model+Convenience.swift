//
//  Model+Convenience.swift
//  sprint
//
//  Created by Kerby Jean on 2/28/20.
//  Copyright © 2020 Kerby Jean. All rights reserved.
//

import Foundation
import CoreData

extension Movie {
    
    var movieRepresentation: MovieRepresentation? {
        guard let title = title else { return nil }
        return MovieRepresentation(title: title, identifier: UUID(), hasWatched: false)
    }
    
    @discardableResult convenience init(title: String, identifier: UUID = UUID(), hasWatched: Bool, context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        self.init(context: context)
        self.title = title
        self.identifier = identifier
        self.hasWatched = hasWatched
    }
    
    @discardableResult convenience init?(taskRepresentation: MovieRepresentation,
                                         context: NSManagedObjectContext = CoreDataStack.shared.mainContext) {
        guard let identifierString = taskRepresentation.identifier?.uuidString, let identifier = UUID(uuidString: identifierString) else {
                return nil
        }
        
        self.init(title: taskRepresentation.title, identifier: identifier, hasWatched: false, context: context)
    }
}

//
//  MovieManaged+Mapping.swift
//  JMBd
//
//  Created by Timple Soft on 05/12/16.
//  Copyright © 2016 TimpleSoft. All rights reserved.
//

import Foundation

extension MovieManaged {
    
    func mappedObject() -> Movie {
        return Movie(id: self.id, title: self.title, order: Int(self.order), summary: self.summary, image: self.image, category: self.category, director: self.director)
    }
    
}

//
//  Hero.swift
//  mapSqlite
//
//  Created by Vrushabh Rupala on 08/10/20.
//

import Foundation

class Hero {
 
    var id: Int
    var name: String?
    var powerRanking: Int
 
    init(id: Int, name: String?, powerRanking: Int){
        self.id = id
        self.name = name
        self.powerRanking = powerRanking
    }
}

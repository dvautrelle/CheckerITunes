//
//  Album.swift
//  CheckerITunes
//
//  Created by Dominique VAUTRELLE on 09/01/2017.
//  Copyright © 2017 Dominique VAUTRELLE. All rights reserved.
//

import Foundation

class Album
{
    var _name : String
    var _artiste: String
    var _titres = [String:String]()
    var _directories = [String : [String]]()
    
    init (name : String, artiste: String)
    {
        _name = name
        _artiste = artiste
    }
    
    func addTrack( trackName: String, inDirectory: String )
    {
        _titres[trackName] = inDirectory
        
        var newList = [String]()
        if let listDir = _directories[inDirectory]
        {
            newList = listDir
           
        }
        
        newList.append(trackName)
        _directories[inDirectory] = newList
    }
}

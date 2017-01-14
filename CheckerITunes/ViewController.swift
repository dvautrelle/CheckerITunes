//
//  ViewController.swift
//  CheckerITunes
//
//  Created by Dominique VAUTRELLE on 01/01/2017.
//  Copyright © 2017 Dominique VAUTRELLE. All rights reserved.
//

import Cocoa
import MediaLibrary

// Essai de check de la librairie iTunes
// probleme de cette librarie:
// - contient des track qui ne sont pas localement chargés (ItunesMatch)    --> pourrait être téléchargé
// - parfois le track dit "non téléchargé" l'est déjà mais pas réérencé dans la library itunes

// - contient des fichiers doublon/triplon de divers origines, type (mp3 aac) , et donc taille differentes



// sur le track, attributs possibles
// "emplacement" = iCloud                   fichier Absent localement
// "état iCloud" = Téléchargé               (téléchargé sur le cloud: car n'etait pas connu de la base iCloud)
//               = Mis en correspondance    (connu de la base iCloud, donc associé à cette ref en bbase iCloud)

// "emplacement" = "/path/du/fichier"        fichier Local
// "état iCloud" = Téléchargé               (téléchargé sur le cloud: car n'etait pas connu de la base iCloud)
//               = Mis en correspondance    (connu de la base iCloud, donc associé à cette ref en bbase iCloud)
//               = Achats


/*
 Sources: about MLMediaLibrary
   http://stackoverflow.com/questions/34570897/accessing-the-media-library-on-os-x-with-swift-code
   https://developer.apple.com/library/content/samplecode/MediaLibraryLoader/Listings/MediaLibraryLoader_ViewController_swift.html
 
 */

class ViewController: NSViewController {

    //var library : MLMediaLibrary!
    var iTunes : MLMediaSource!
    var rootGroup : MLMediaGroup!
    
    // MLMediaLibrary instances for loading the item
    private var mediaLibrary: MLMediaLibrary!
    private var mediaSource: MLMediaSource!
    private var rootMediaGroup: MLMediaGroup!
    private var musicMediaGroup: MLMediaGroup!
    
    // MLMediaLibrary property values for KVO.
    private struct MLMediaLibraryPropertyKeys {
        static let mediaSourcesKey = "mediaSources"
        static let rootMediaGroupKey = "rootMediaGroup"
        static let mediaObjectsKey = "mediaObjects"
        static let contentTypeKey = "contentType"
    }
    
    private var mediaSourcesContext = 1
    private var rootMediaGroupContext = 2
    private var mediaObjectsContext = 3
    
    var _nbDoublon = 0
    var _nbVraiDoublon = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let options : [String : AnyObject] = [ MLMediaLoadSourceTypesKey : MLMediaSourceType.audio.rawValue   as AnyObject,
                                               MLMediaLoadIncludeSourcesKey: [ MLMediaSourceiTunesIdentifier , MLMediaSourceiTunesIdentifier]  as AnyObject ]
        mediaLibrary = MLMediaLibrary(options: options)
        mediaLibrary.addObserver(self, forKeyPath: "mediaSources", options: NSKeyValueObservingOptions.new , context: &mediaSourcesContext)
    
    
        _ = mediaLibrary.mediaSources // trigger load, status will be reported back in observeValueForKeyPath

    }
    
    
    //func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutableRawPointer) {
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print ("observeValue ini for path =  \(keyPath)")
        guard let path = keyPath else { return }
        
        print ("observeValue go...")
        //assertionFailure()
        
        
        switch path {
        case "mediaSources":
            print ("observeValue --> loadSources")
            loadSources()
        case "rootMediaGroup":
            print ("observeValue --> loadRootGroup")
            loadRootGroup()
        case MLMediaLibraryPropertyKeys.mediaObjectsKey:
            print ("observeValue --> loadObjects")
            loadObjects()
        default:
            print("Nothing to do for \(path)")
        }
    }
    
    func loadSources(){
      
        //  if let mediaSources = mediaLibrary.mediaSources {
            
        if let mediaSource = self.mediaLibrary.mediaSources?[MLMediaSourceiTunesIdentifier] {
            self.mediaSource = mediaSource
            
            self.mediaSource.addObserver(self,
                                         forKeyPath: "rootMediaGroup",
                                         options: NSKeyValueObservingOptions.new,
                                         context: &rootMediaGroupContext)
            self.mediaSource.rootMediaGroup
            
//            let mediaSources = mediaLibrary.mediaSources
//            for (ident, source) in mediaSources {
//                print("Ident: \(ident)")
//                print("Source Ident: \(source.mediaSourceIdentifier)")
//                iTunes = source
//                iTunes.addObserver(self, forKeyPath: "rootMediaGroup", options: NSKeyValueObservingOptions.new, context: &rootMediaGroupContext)
//                iTunes.rootMediaGroup
//            }
        }
    }
    
    func loadRootGroup()
    {
        if let rootGroup = self.mediaSource.rootMediaGroup {
            print("Root Group Identifier: \(rootGroup.identifier)")
            print("Root Group Type Ident: \(rootGroup.typeIdentifier)")
            print (rootGroup.attributes)
            
            // Done observing for media groups.
            self.mediaSource.removeObserver(self, forKeyPath: "rootMediaGroup", context:&rootMediaGroupContext)
            
            
//            for child in rootGroup.childGroups!
//            {
//                print("\n  Child Group Identifier: \(child.identifier)")
//                print("  Child Group Type Ident: \(child.typeIdentifier)")
//                print (child.attributes)
//                
//                if child.attributes["name"] as! String == "Musique"
//                {
//                    
//                    
//                    //self.musicMediaGroup = child
//                    
//
//                    //child.mediaObjects
//                }
//            }
            
            self.rootMediaGroup = self.mediaSource.rootMediaGroup
            self.rootMediaGroup.addObserver(self,
                              forKeyPath: MLMediaLibraryPropertyKeys.mediaObjectsKey,
                              options: NSKeyValueObservingOptions.new,
                              context: &mediaObjectsContext)
            
            self.rootMediaGroup.mediaObjects
         
        }
        
        
    }

   
    /* Attribut obtenu
     ["Date Modified": 2015-12-06 11:36:43 +0000,
     "modificationDate": 2015-12-06 11:36:43 +0000,
     "Date Added": 2015-12-06 10:37:39 +0000,
     "contentType": com.apple.m4a-audio / public.mp3
     "Year": 2015,
     "Genre": Hip-hop/Rap, podcast
     "identifier": D8D56D8D3F2D4F5B, 
     "Track ID": D8D56D8D3F2D4F5B,
     "Name": Birth,
     "Track Count": 15,
     "Duration": 206.864, 
     "Total Time": 206864,
     "Podcast": 1               --> attribut exst si podcast
     "Bit Rate": 256,
     "Sample Rate": 44100,
     "name": Birth,
     "Kind": Fichier audio AAC acheté / Fichier audio MPEG
        "Kind": Fichier audio AAC mis en correspondance
     "Artist": A.S.M., 
     "mediaSourceIdentifier": com.apple.iTunes, 
     "Album": The Jade Amulet,
     "mediaType": 1, = audio, 4 =video
     "Track Number": 1
     "URL": file:///Users/Dom/Music/iTunes%201/iTunes%20Media/Music/A.S.M_/The%20Jade%20Amulet/01%20Birth.m4a, 
     "fileSize": 7720498, 
     "Composer": Adam Simmons, Benjamin Bambach, Maik Schindler, Matthieu Detton & Benjamin Bouton,
     "Release Date": 2015-10-16 07:00:00 +0000]
     
     !!  pas de "status iCloud" trouvé  !!!   où le trouver ??????????
     
   */
    func loadObjects()
    {
        print("loadObjects")
        // Done observing for media objects that group.
        //self.rootMediaGroup.removeObserver(self, forKeyPath: MLMediaLibraryPropertyKeys.mediaObjectsKey, context:&mediaObjectsContext)
        
        if let mediaObjects = self.rootMediaGroup.mediaObjects
        //if let mediaObjects = self.musicMediaGroup.mediaObjects
        {
            var compteur = 0
            
            var prevArtist = ""
            var prevAlbum  = ""
            var listTrackSameAlbum = [MLMediaObject]()

            for mediaObject in mediaObjects
            {
                let attrs = mediaObject.attributes
                if  let _ = attrs["Podcast"]
                {
                    continue
                }
                compteur = compteur + 1
            
                print ("\n====== \(attrs["Album"])")
//                for (key , val )in attrs
//                {
//                    print (key, "\t ", val)
//                    if (key.lowercased().range(of: "album") != nil)
//                    {
//                        print ("attr ALBUM : [\(key)]")
//                    }
//                }
//                continue
            
                if  let artist = attrs["Artist"] ,  let album = attrs["Album"]
                {
                    if prevArtist == artist as! String && prevAlbum == album as! String
                    {
                        listTrackSameAlbum.append(mediaObject)
                        
                    }
                    else if prevArtist == "" && prevAlbum == ""
                    {
                        
                    }
                    else // donc changement d'album
                    {
                        //-- d'abord traiter cet ALBUM
                        // --> GO traitement
                        //let pathFileURL = attrs["URL"] as! URL
                        
                        checkAlbumForDoublonAndUnusedFile(listTrackSameAlbum)
                        
                        //-- puis list ce medio object
                        listTrackSameAlbum.removeAll()
                        listTrackSameAlbum.append(mediaObject)
                        //prevArtist = artist as! String
                        //prevAlbum = album as! String
                        
                    }
                    
                    
                    prevArtist = artist as! String
                    prevAlbum  = album  as! String
                    
                    
                    continue
                    
                    
                    let pathFileURL = attrs["URL"] as! URL
                    //let pathFile = String(content: pathFileURL)
                    let trackName = attrs["name"] as! String
                    
                    var piste = attrs["Track Number"]
                    if piste == nil
                    {
                        piste = "?"
                    }
                    var trackCount = attrs["Track Count"]
                    if trackCount == nil
                    {
                        trackCount = "?"
                    }
                     //print ("\(artist): \(album) \(attrs["Track Number"])/\(attrs["Track Count"])  \(attrs["name"]!) [\(attrs["Kind"]!)] = \(pathFile) ")
                     print ("\n<\(artist)>  \(album) : (\(piste!)/\(trackCount!))  \(trackName) [\(attrs["Kind"]!)] = \(attrs["contentType"]!) ")
                     //print(attrs)
                     //checkTrackFile(pathFileURL , for: trackName)
                    
                    //if artist as! String == "137 Studios"
                     //{
                       
                        
                       
                        /*
                        ["Date Modified": 2014-01-19 19:36:01 +0000,
                        "contentType": public.mp3,
                        "Year": 2014, 
                         "Genre": Podcast, 
                         "identifier": 40B2AAA33ABE037F,
                         "Track ID": 40B2AAA33ABE037F, 
                         "Name": Magnetic 9 - Le pantalon de Chewbacca, "Duration": 4128.496, "Total Time": 4128496, "Podcast": 1, "Sample Rate": 44100, "name": Magnetic 9 - Le pantalon de Chewbacca, "Bit Rate": 64, "Kind": Fichier audio MPEG, "Artist": 137 Studios, "mediaSourceIdentifier": com.apple.iTunes, "Album": Magnetic, "modificationDate": 2014-01-19 19:36:01 +0000, "mediaType": 1, "Track Number": 9, "Date Added": 2014-01-19 19:36:01 +0000, "URL": file:///Users/Dom/Music/iTunes%201/iTunes%20Media/Podcasts/Magnetic/09%20Magnetic%209%20-%20Le%20pantalon%20de%20Chewbacca.mp3, "fileSize": 33168690, "Composer": Apollo, "Release Date": 2014-01-16 15:00:00 +0000]
                        */
                    //}
                }
            }

            print("il y a \(mediaObjects.count) morceaux")
            print("il y a \(_nbDoublon) doublons")
            print("il y a \(_nbVraiDoublon) vrais doublons")
        }
    }
    
    func checkAlbumForDoublonAndUnusedFile(_ listMediaObject: [MLMediaObject] )
    {
        // tous ces objects sont censés être du même album
        // donc le dir de l'album doit être le même (à checker)
        var prevTrackDir : URL?
        
        var listTrackFileFoundForAlbum = [String]()
        
        for checkedMediaObj in listMediaObject
        {
            let attrs = checkedMediaObj.attributes
            //let trackName   = attrs["name"] as! String
            
            let pathTrackFileURL = attrs["URL"] as! URL
            let trackDir = pathTrackFileURL.deletingLastPathComponent()
            
            if prevTrackDir != nil && prevTrackDir != trackDir
            {
                print ("ALERTE: DIR differente : prevTrackDir= [\(prevTrackDir!.path)]  for \(attrs["Name"]!)")
                print ("ALERTE                       trackDir= [\(trackDir.path)]")
            }
            else
            {
                prevTrackDir = trackDir
                // quel est le fichier lié ?
                print("for Album Dir \(trackDir.path)   pathTrackFileURL \(pathTrackFileURL.lastPathComponent)")
                listTrackFileFoundForAlbum.append(pathTrackFileURL.lastPathComponent)
                
            }
           
        }
        print("nb fichiés liés trouvé \(listTrackFileFoundForAlbum.count)")
        
        //-- parcourt physique repertoire pour voir si il y a dautres fichiers que ceuls listés par iTunes:
        let fileManager = FileManager()
        let trackDirPATH = prevTrackDir?.path
        let en = fileManager.enumerator(atPath: trackDirPATH!)   //(at: trackDirPATH, includingPropertiesForKeys: nil)
        
        print("-> parcourt du dir \(trackDirPATH)   ")
        //var fileNameRecognized = false
        while let element = en?.nextObject() as? String
        {
            //-- element est sous la forme  "01 Walk.m4a"
            //== analyse de la fin du nom
            let fileName = URL(fileURLWithPath: element).relativePath
            //print ("  element = [\(element)]   fileName = [\(fileName)] ")
            
            // filename est-il dans la liste des fichier liés ?
            if listTrackFileFoundForAlbum.contains(fileName)
            {
                print ("ok fichié fileName = [\(fileName)] trouvé était bien listé...")
            }
            else
            {
                print("fichier non listés par iTunes \(fileName)")
            }
        }
        
        
        
    }
    
    
    func checkTrackFile(_ pathTrackFile: URL, for TrackName: String)
    {
         print ("checkTrackFile pathTrackFile=\(pathTrackFile)    & TrackName= [\(TrackName)]")
        // souvent le nom du fichier est "xx TRACKNAME yy.EXTENSION"
        //   xx         souvent indice de numero de piste : 1, ou 01, ou rien
        //   TRACKNAME  est le nom du morceau ( = Attr Name)
        //   yy         soit rien, soir indice de copie multiple
        //   EXTENSION  mp3, m4a, etc
        
        //-- il faut donc chercher si il exsite dans le même repertoire, des fichiers qui ne sont plus LIé a la base iTunes, doublon du fichier lié
        
        let trackDir = pathTrackFile.deletingLastPathComponent()
        //print ("checkTrackFile trackDir     =\(trackDir)")
        
        //--
        let trackFileName = pathTrackFile.lastPathComponent  // deletingPathExtension
        // suppression extension
        let trackFileExt  = pathTrackFile.pathExtension     // deletingPathExtension
        //let trackFilePath = trackFileName.path     // deletingPathExtension
         let trackFileBase = trackFileName.replacingOccurrences(of: "."+trackFileExt , with: "")
        //trackFileName.
        
        
        print ("checkTrackFile trackFileName = [\(trackFileName)]   donc base = [\(trackFileBase)]     ext = [\(trackFileExt)]")
        
        //let pathTest = "/Volumes/diskE/Users/dve/Music/iTunes/iTunes Media/Music/Guillaume Perret/Free"
        
        let fileManager = FileManager()                   // let fileManager = NSFileManager.defaultManager()
        // parcourt de ce dir :
        let trackDirPATH = trackDir.path
        print ("checkTrackFile trackDirPATH = [\(trackDirPATH)] for enumeration...")
        let en = fileManager.enumerator(atPath: trackDirPATH)   //(at: trackDirPATH, includingPropertiesForKeys: nil)
     
        var fileNameRecognized = false
        while let element = en?.nextObject() as? String
        {
            //-- element est sous la forme  "01 Walk.m4a"
            print ("  element = [\(element)]")
            
            //== analyse de la fin du nom
            
            let fileName = URL(fileURLWithPath: element).relativePath
            //print ("checkTrackFile element fileName=\(fileName)")
            // est-ce le fichier lié
            if fileName == trackFileName
            {
                print("  --> OK le fichier lié est trouvé : [\(trackFileName)]")
                fileNameRecognized = true
            }
            else
            {
                // autre fichiers de ce dir, contenant le Trackname
                if let _ = fileName.range(of: TrackName)
                {
                    let tabElt = fileName.components(separatedBy: TrackName)
                    print ("   fileName= [\(fileName)]   tabElt = \(tabElt) --> faux doublon ?")
                    _nbDoublon += 1
                }
                
                //let chaine = trackFileBase
                if let _ = fileName.range(of: trackFileBase)
                {
                    let tabElt = fileName.components(separatedBy: trackFileBase)
                    print ("   fileName= [\(fileName)]   tabElt = \(tabElt) --> vrai doublon ")
                    _nbVraiDoublon += 1
                }
            }
            /*  FAUX DOUBLON : le TrackName se retrouve dans 2 morceau, mais normal (en 01 et en 03) 
                Comment distinguer ce cas du VRAI doublon
             <松任谷由実>  ついてゆくわ　シングル  (1/4)  ついてゆくわ [Fichier audio AAC] = com.apple.m4a-audio
             checkTrackFile pathTrackFile=file:///Users/Dom/Music/iTunes%201/iTunes%20Media/Music/%E6%9D%BE%E4%BB%BB%E8%B0%B7%E7%94%B1%E5%AE%9F/%E3%81%A4%E3%81%84%E3%81%A6%E3%82%86%E3%81%8F%E3%82%8F%E3%80%80%E3%82%B7%E3%83%B3%E3%82%AF%E3%82%99%E3%83%AB/01%20%E3%81%A4%E3%81%84%E3%81%A6%E3%82%86%E3%81%8F%E3%82%8F%201.m4a    & TrackName=ついてゆくわ
             checkTrackFile trackDir     =file:///Users/Dom/Music/iTunes%201/iTunes%20Media/Music/%E6%9D%BE%E4%BB%BB%E8%B0%B7%E7%94%B1%E5%AE%9F/%E3%81%A4%E3%81%84%E3%81%A6%E3%82%86%E3%81%8F%E3%82%8F%E3%80%80%E3%82%B7%E3%83%B3%E3%82%AF%E3%82%99%E3%83%AB/
             checkTrackFile trackFileName=01 ついてゆくわ 1.m4a
             checkTrackFile trackDirPATH = [/Users/Dom/Music/iTunes 1/iTunes Media/Music/松任谷由実/ついてゆくわ　シングル] for enumeration...
             element = [01 ついてゆくわ 1.m4a]
             --> OK le fichier lié est trouvé : [01 ついてゆくわ 1.m4a]
             element = [01 ついてゆくわ.m4a]
             fileName= [01 ついてゆくわ.m4a]   tabElt=["01 ", ".m4a"] --> doublon
             element = [02 あなたに届くように.m4a]
             element = [03 ついてゆくわ inst..m4a]
             fileName= [03 ついてゆくわ inst..m4a]   tabElt=["03 ", " inst..m4a"] --> doublon         FAUX !!!!!
             element = [04 あなたに届くように inst..m4a]
            */
            
            
            
            
            
//            if element.hasSuffix("mp3")  || element.hasSuffix("m4a") {
//                // do something with the_path/*.ext ....
//                print ("has suffix \(element)")
//            }
            
//            if element.hasPrefix("01 Walk"){
//                // do something with the_path/*.ext ....
//                print ("has prefix \(element)")
//            }
            
        }
        assert(fileNameRecognized, "fichier \(trackFileName) non reconnu dans le directory")
        
    }

    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    deinit {
        
        // Make sure to remove us as an observer before "mediaLibrary" is released.
        self.mediaLibrary.removeObserver(self, forKeyPath: MLMediaLibraryPropertyKeys.mediaSourcesKey, context:&mediaSourcesContext)
    }


}


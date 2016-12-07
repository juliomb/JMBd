//
//  LocalCoreDataService.swift
//  JMBd
//
//  Created by Timple Soft on 05/12/16.
//  Copyright © 2016 TimpleSoft. All rights reserved.
//

import Foundation
import CoreData

class LocalCoreDataService {
    
    let remoteMovieService = RemoteiTunesMovieService()
    let stack = CoreDataStack.sharedInstance
    
    func searchMovies(byTerm: String, remoteHandler: @escaping ([Movie]?) -> Void){
        
        remoteMovieService.searchMovies(byTerm: byTerm) { movies in
         
            if let movies = movies {
                
                var modelMovies = [Movie]()
                for movie in movies {
                    let modelMovie = Movie(id: movie["id"], title: movie["title"], order: nil, summary: movie["summary"], image: movie["image"], category: movie["category"], director: movie["director"])
                    modelMovies.append(modelMovie)
                }
                remoteHandler(modelMovies)
                
            } else {
                print("Error while calling REST services")
                remoteHandler(nil)
            }
            
        }
    }
    
    
    func getTopMovies(localHandler: ([Movie]?) -> Void, remoteHandler: @escaping ([Movie]?) -> Void) {
    
        localHandler(self.queryTopMovies())
        
        remoteMovieService.getTopMovies() { movies in
        
            if let movies = movies {
                
                self.markAllMoviesAsUnsync()
                
                var order = 1
                for movieDictionary in movies {
                
                    if let movie = self.getMovieById(id: movieDictionary["id"]!, favorite: false){
                        self.updateMovie(movieDictionary: movieDictionary, movie: movie, order: order)
                    } else {
                        self.insertMovie(movieDictionary: movieDictionary, order: order)
                    }
                    order += 1
                    
                }
                
                self.removeOldNotFavoriteMovies()
                remoteHandler(self.queryTopMovies())
                
            } else {
                remoteHandler(nil)
            }
            
        }
        
    }
    
    
    func getFavoriteMovies() -> [Movie]?  {
        let context = stack.persistentContainer.viewContext
        let request : NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        let predicate = NSPredicate(format: "favorite = \(true)")
        request.predicate = predicate
        
        do {
            
            let fechtedMovies = try context.fetch(request)
            var movies = [Movie]()
            for managedMovie in fechtedMovies {
                movies.append(managedMovie.mappedObject())
            }
            return movies
            
        } catch  {
            print("Error recuperando los favoritos")
            return nil
        }
    }
    
    func queryTopMovies() -> [Movie]? {
        
        let context = stack.persistentContainer.viewContext
        let request : NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "order", ascending: true)
        request.sortDescriptors = [sortDescriptor]
        let predicate = NSPredicate(format: "favorite = \(false)")
        request.predicate = predicate
        
        do {
            let fethcedMovies = try context.fetch(request)
            var movies = [Movie]()
            for manageMovie in fethcedMovies{
                movies.append(manageMovie.mappedObject())
            }
            return movies
            
        } catch {
            print("Error recuperando películas de Core Data")
            return nil
        }
        
    }

    
    func markAllMoviesAsUnsync() {
        
        let context = stack.persistentContainer.viewContext
        let request : NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        let predicate = NSPredicate(format: "favorite = \(false)")
        request.predicate = predicate
        
        do {
            let fethcedMovies = try context.fetch(request)
            for manageMovie in fethcedMovies{
                manageMovie.sync = false
            }
            try context.save()
            
        } catch {
            print("Error actualizando películas de Core Data")
        }
        
        
    }
    
    
    func getMovieById(id: String, favorite: Bool) -> MovieManaged? {
     
        let context = stack.persistentContainer.viewContext
        let request : NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        let predicate = NSPredicate(format: "id = \(id) and favorite = \(favorite)")
        request.predicate = predicate
        
        do {
            let fethcedMovies = try context.fetch(request)
            if fethcedMovies.count > 0 {
                return fethcedMovies.last
            } else {
                return nil
            }
            
        } catch {
            print("Error recuperando una película de Core Data")
            return nil
        }
        
    }
    
    
    func insertMovie(movieDictionary: [String:String], order: Int){
        let context = stack.persistentContainer.viewContext
        let movie = MovieManaged(context: context)
        
        movie.id = movieDictionary["id"]
        updateMovie(movieDictionary: movieDictionary, movie: movie, order: order)
    
    }
    
    func updateMovie(movieDictionary: [String: String], movie: MovieManaged, order: Int){
        
        let context = stack.persistentContainer.viewContext
        movie.order = Int16(order)
        movie.title = movieDictionary["title"]
        movie.summary = movieDictionary["summary"]
        movie.category = movieDictionary["category"]
        movie.director = movieDictionary["director"]
        movie.image = movieDictionary["image"]
        movie.sync = true
        
        do {
            try context.save()
        } catch {
            print("Error actualizando Core Data")
        }
        
    }
    
    
    func removeOldNotFavoriteMovies() {
        let context = stack.persistentContainer.viewContext
        let request : NSFetchRequest<MovieManaged> = MovieManaged.fetchRequest()
        let predicate = NSPredicate(format: "sync = \(false) and favorite = \(false)")
        request.predicate = predicate
        
        do {
            let fetchedMovies = try context.fetch(request)
            for movie in fetchedMovies{
                context.delete(movie)
            }
        } catch {
            print("Error eliminando de Core Data")
        }
        
    }
    
    
    func isMovieFavorite(movie: Movie) -> Bool {
        
        if let _ = getMovieById(id: movie.id!, favorite: true) {
            return true
        }
        return false
        
    }
    
    
    func markUnmarkFavorite(movie: Movie) {
        
        let context = stack.persistentContainer.viewContext
        if let exists = getMovieById(id: movie.id!, favorite: true){
            context.delete(exists)
        } else {
            let favorite = MovieManaged(context: context)
            
            favorite.id = movie.id
            favorite.title = movie.title
            favorite.summary = movie.summary
            favorite.category = movie.category
            favorite.director = movie.director
            favorite.image = movie.image
            favorite.favorite = true
        }
        
        do {
            try context.save()
        } catch {
            print("Error marcando favorito")
        }
        
        updateFavoritesBadge()
        
    }
    
    
    func updateFavoritesBadge(){
        if let totalFavorites = getFavoriteMovies()?.count {
            let notification = Notification(name: Notification.Name("updateFavoritesBadgeNotification"), object: totalFavorites, userInfo: nil)
            NotificationCenter.default.post(notification)
        }
    }
    
    
}


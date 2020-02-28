//
//  MovieController.swift
//  MyMovies
//
//  Created by Spencer Curtis on 8/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//


import CoreData
import Foundation


class MovieController {
    
    private let apiKey = "4cc920dab8b729a619647ccc4d191d5e"
    
    typealias CompletionHandler = (Error?) -> Void
    
    // MARK: - Properties
    
    var searchedMovies: [MovieRepresentation] = []
    
    private let movieUrl = URL(string: Urls.movieUrl.description)!
    private let firebaseUrl = URL(string: Urls.firebaseUrl.description)!
    
    init() {
        getMoviesFromServer()
    }
    
    func searchForMovie(with searchTerm: String, completion: @escaping (Error?) -> Void) {
        
        var components = URLComponents(url: movieUrl, resolvingAgainstBaseURL: true)
        
        let queryParameters = ["query": searchTerm, "api_key": apiKey]
        
        components?.queryItems = queryParameters.map({URLQueryItem(name: $0.key, value: $0.value)})
        
        guard let requestURL = components?.url else {
            completion(NSError())
            return
        }
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            
            if let error = error {
                NSLog("Error searching for movie with search term \(searchTerm): \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                NSLog("No data returned from data task")
                completion(NSError())
                return
            }
            do {
                let movieRepresentations = try JSONDecoder().decode(MovieRepresentations.self, from: data).results
                self.searchedMovies = movieRepresentations
                completion(nil)
            } catch {
                NSLog("Error decoding JSON data: \(error)")
                completion(error)
            }
        }.resume()
    }
    
    func sendMovieToServer(movie: Movie, completion: @escaping CompletionHandler = { _ in }) {
        
        let uuid = movie.identifier!
        let requestURL = firebaseUrl.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = HttpMethods.PUT.rawValue
        
        do {
            guard let representation = movie.movieRepresentation else {
                completion(NSError())
                return
            }
            try CoreDataStack.shared.save()
            request.httpBody = try JSONEncoder().encode(representation)
        } catch {
            NSLog("Error encoding task: \(error)")
            completion(error)
            return
        }
        
        urlSesion(with: request) { (error) in
            if let error = error {
                completion(error)
                return
            }
            completion(nil)
        }
    }
    
    func getMoviesFromServer(completion: @escaping CompletionHandler = { _ in }) {
        
        let requestURL = firebaseUrl.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            if let error = error {
                NSLog("Error fetching tasks from Firebase: \(error)")
                completion(error)
                return
            }
            
            guard let data = data else {
                NSLog("No data returned from Firebase")
                completion(NSError())
                return
            }
            
            do {
                let movieRepresenations = Array(try JSONDecoder().decode([String : MovieRepresentation].self, from: data).values)
                try self.updateMovies(with: movieRepresenations)
                completion(nil)
            } catch {
                NSLog("Error decoding task representations from Firebase: \(error)")
                completion(error)
            }
        }.resume()
    }
    
    
    func updateWatched(movie: Movie, completion: @escaping CompletionHandler = { _ in }) {
        let uuid = movie.identifier!
        let requestURL = firebaseUrl.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = HttpMethods.PUT.rawValue
        request.setValue("true", forHTTPHeaderField: "hasWatched")
        do {
            guard let representation = movie.movieRepresentation else {
                completion(NSError())
                return
            }
            try CoreDataStack.shared.save()
            request.httpBody = try JSONEncoder().encode(representation)
        } catch {
            NSLog("Error encoding task: \(error)")
            completion(error)
            return
        }
        
        urlSesion(with: request) { (error) in
            if let error = error {
                completion(error)
                return
            }
            completion(nil)
        }
    }
    
    func deleteMovieFromServer(movie: Movie, completion: @escaping CompletionHandler = { _ in }) {
        
        guard let uuid = movie.identifier else {
            completion(NSError())
            return
        }
        
        let requestURL = firebaseUrl.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = HttpMethods.DELETE.rawValue
        urlSesion(with: request) { (error) in
            if let error = error {
                completion(error)
                return
            }
        }
    }
    
    func urlSesion(with request: URLRequest, completion: @escaping CompletionHandler) {
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                NSLog("Error: \(error)")
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
    }
    
    
    
    // MARK: - Private
    
    private func updateMovies(with representations: [MovieRepresentation]) throws {
        let tasksWithID = representations.filter { $0.identifier != nil }
        let identifiersToFetch = tasksWithID.compactMap { $0.identifier }
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, tasksWithID))
        var moviesToCreate = representationsByID
        
        let fetchRequest: NSFetchRequest<Movie> = Movie.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
        
        let context = CoreDataStack.shared.container.newBackgroundContext()
        
        context.performAndWait {
            do {
                let existingTasks = try context.fetch(fetchRequest)
                
                for movie in existingTasks {
                    guard let id = movie.identifier, let representation = representationsByID[id] else { continue }
                    self.update(movie: movie, with: representation)
                    moviesToCreate.removeValue(forKey: id)
                }
                
                for representation in moviesToCreate.values {
                    Movie(movieRepresentation: representation, context: context)
                }
            } catch {
                NSLog("Error fetching tasks for UUIDs: \(error)")
            }
        }
        
        try CoreDataStack.shared.save(context: context)
    }
    
    private func update(movie: Movie, with representation: MovieRepresentation) {
        movie.title = representation.title
        movie.hasWatched = representation.hasWatched ?? false
    }
}

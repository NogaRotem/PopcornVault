//
//  Controller.swift
//  PopcornVault
//
//  Created by Noga Rotem on 15/08/2024.
//

import Foundation

// A mediator between the views and MovieService
class Controller{
    
    // Gets movie details from server using MovieSevice
    func getMovie(input: String, page: Int) async throws -> [TMDBParser.MovieData]{
        let movies = try await MovieService.getMovie(query:input, page: page)
        return movies
    }
    
    // Gets key for trailer from server using MovieSevice
    func getTrailerKey(id: Int) async throws -> String{
        let key = try await MovieService.getTrailerKey(id: id)
        return key
    }
    
    // Gets most trending movie details from server using MovieSevice
    func getTrending() async throws -> [TMDBParser.MovieData]{
        let movies = try await MovieService.getTrending()
        return movies
    }
    
    func getEntertainers(movieID: Int) async throws -> TMDBParser.EntertainersResponse{
        let entertainers = try await MovieService.getEntertainers(movieID: movieID)
        return entertainers
    }
}

//
//  DataService.swift
//  PopcornVault
//
//  Created by Noga Rotem on 14/08/2024.
//

import Foundation
import Alamofire

struct MovieService{
    // get API key from config file
    static private let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String
    static private let headers: HTTPHeaders = [
        "accept": "application/json",
        "Authorization": apiKey ?? ""
    ]
    
    //for throwing in case of api_key = nil
    enum DataServiceError: Error {
        case NoAPIKey
        case failedResponseDecode
    }
    
    static func getTrending() async throws -> [TMDBParser.MovieData]{
        let url = "https://api.themoviedb.org/3/trending/movie/day"
        let parameters : [String: Any] = [:]
        do {
            let response = try await AF.request(url, method: .get, parameters: parameters, headers: headers).serializingData().value
            let trailers = try TMDBParser.parseMovie(json: response)
            return trailers
            
        }
    }
    
    static func getTrailerKey(id: Int) async throws -> String{
        let url = "https://api.themoviedb.org/3/movie/\(id)/videos"
        
        let parameters: [String: Any] = [:]
        
        do {
            let response = try await AF.request(url, method: .get, parameters: parameters, headers: headers).serializingData().value
            let videos = try TMDBParser.parseTrailer(json: response)
            
            for video in videos{
                if video.type == TMDBParser.TypeEnum.trailer { //Go through videos related to movie and look for the trailer
                    return video.key
                }
            }
            
            return "" // If no trailer was found
        }
    }
    
    static func getMovie(query: String, page: Int) async throws -> [TMDBParser.MovieData] {
        guard apiKey != nil else{
            throw DataServiceError.NoAPIKey  //todo: return an empty list
        }
        
        let url = "https://api.themoviedb.org/3/search/movie"
        
        let parameters: [String: Any] = [
            "query": query,
            "page": String(page)
        ]
        
        do {
            let response = try await AF.request(url, method: .get, parameters: parameters, headers: headers).serializingData().value
            let movies = try TMDBParser.parseMovie(json: response)
            return movies
        }
        
    }
    
    static func getEntertainers(movieID: Int) async throws -> TMDBParser.EntertainersResponse {
        let url = "https://api.themoviedb.org/3/movie/\(movieID)/credits"
        
        let parameters: [String: Any] = [:]
        
        do {
            let response = try await AF.request(url, method: .get, parameters: parameters, headers: headers).serializingData().value
            let entertainers = try TMDBParser.parseEntertainers(json: response)
            return entertainers
        }
    }
}

//structs for parsing
class TMDBParser{
 
    // MARK: - APIResponse
    struct MovieResponse: Codable {
        let page: Int?
        let results: [MovieData]
        let totalPages: Int?
        let totalResults: Int?

        enum CodingKeys: String, CodingKey {
            case page, results
            case totalPages = "total_pages"
            case totalResults = "total_results"
        }
    }


    // MARK: - Result
    struct MovieData: Codable, Hashable {
        let adult: Bool?
        let backdropPath: String?
        let genreIDS: [Int]?
        let id: Int
        let originalLanguage: String?
        let originalTitle: String?
        let overview: String?
        let popularity: Double?
        let posterPath: String?
        let releaseDate: String?
        let title: String?
        let video: Bool?
        let voteAverage: Double?
        let voteCount: Int?

        enum CodingKeys: String, CodingKey {
            case adult
            case backdropPath = "backdrop_path"
            case genreIDS = "genre_ids"
            case id
            case originalLanguage = "original_language"
            case originalTitle = "original_title"
            case overview, popularity
            case posterPath = "poster_path"
            case releaseDate = "release_date"
            case title, video
            case voteAverage = "vote_average"
            case voteCount = "vote_count"
        }
    }

 
    // MARK: - TrailerResponse
    struct TrailerResponse: Codable {
        let id: Int
        let results: [TrailerData]
    }

    // MARK: - Result
    struct TrailerData: Codable {
        let iso639_1: ISO639_1
        let iso3166_1: ISO3166_1
        let name, key: String
        let site: Site
        let size: Int
        let type: TypeEnum
        let official: Bool
        let publishedAt, id: String

        enum CodingKeys: String, CodingKey {
            case iso639_1 = "iso_639_1"
            case iso3166_1 = "iso_3166_1"
            case name, key, site, size, type, official
            case publishedAt = "published_at"
            case id
        }
    }

    enum ISO3166_1: String, Codable {
        case us = "US"
    }

    enum ISO639_1: String, Codable {
        case en = "en"
    }

    enum Site: String, Codable {
        case youTube = "YouTube"
    }

    enum TypeEnum: String, Codable {
        case behindTheScenes = "Behind the Scenes"
        case clip = "Clip"
        case featurette = "Featurette"
        case teaser = "Teaser"
        case trailer = "Trailer"
    }

    // MARK: - CastResponse
    struct EntertainersResponse: Codable {
        let id: Int
        let cast, crew: [EntertainerData]
    }

    // MARK: - Cast
    struct EntertainerData: Codable, Hashable {
        let adult: Bool
        let gender, id: Int
        let knownForDepartment, name, originalName: String
        let popularity: Double
        let profilePath: String?
        let castID: Int?
        let character: String?
        let creditID: String
        let order: Int?
        let department, job: String?

        enum CodingKeys: String, CodingKey {
            case adult, gender, id
            case knownForDepartment = "known_for_department"
            case name
            case originalName = "original_name"
            case popularity
            case profilePath = "profile_path"
            case castID = "cast_id"
            case character
            case creditID = "credit_id"
            case order, department, job
        }
    }


    static func parseMovie(json: Data) throws -> [MovieData] {
        do {
            let decoder = JSONDecoder()
            let movieResponse = try decoder.decode(MovieResponse.self, from: json)
            return movieResponse.results
        } catch {
            throw MovieService.DataServiceError.failedResponseDecode
        }
    }
    
    static func parseTrailer(json: Data) throws -> [TrailerData]{
        do {
            let decoder = JSONDecoder()
            let trailerResponse = try decoder.decode(TrailerResponse.self, from: json)
            return trailerResponse.results
        } catch {
            throw MovieService.DataServiceError.failedResponseDecode
        }
    }
    
    static func parseEntertainers(json: Data) throws -> EntertainersResponse{
        do {
            let decoder = JSONDecoder()
            let CastResponse = try decoder.decode(EntertainersResponse.self, from: json)
            return CastResponse
        } catch {
            throw MovieService.DataServiceError.failedResponseDecode
        }
    }

}

//  PopcornVaultApp.swift
//  PopcornVault
//
//  Created by Noga Rotem on 13/08/2024.

import SwiftUI
import AVKit
import Alamofire // for error handling
import Kingfisher//Image caching

// Movie details view. Open when uses clicks a movie in MainView
struct MovieView: View {
    @Environment(\.presentationMode) var presentationMode // Keeps track of view stack
    let movie: TMDBParser.MovieData
    let controller: Controller
    @State private var trailerKey = "" // key for trailer will be fetched from server if user clicks play button
    @State private var isPlayingVideo = false
    @State private var error = ""
    let imageCacher: ImageCacher
    private let imageURLPrefix = "https://image.tmdb.org/t/p/w500"
    @State var isCastandCrewFetched = false
    @State private var castAndCrew: TMDBParser.EntertainersResponse?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                
                // Conditionally display video player or image with play button
                    if isPlayingVideo && error == "" { // If video play button was clicked and no errors accured while fetching trailer key from server
                        VideoPlayer(videoKey: trailerKey) // trailer key fetched upon containing Vstack creation
                            .aspectRatio(16/9, contentMode: .fill) // YouTube ratio
                    } else { // If play not clicked or problem fetching video key - display movie backdrop
                            ZStack {
                                CachedImageView(imageCacher: imageCacher, urlPrefix: imageURLPrefix, urlID: (movie.backdropPath ?? ""))
                                    .aspectRatio(16/9, contentMode: .fill) // Set the image and trailer in same size
                                Button(action: { // play button on image will display trailer when clicked
                                    isPlayingVideo = true // Promt video replacing the image
                                }) {
                                    Image(systemName: "play.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.white)
                                        .padding()
                                }
                            }
                    }
                
                
                Text(movie.title ?? "No Movie Title").font(.title).bold()
                Text("Release Date: " + (movie.releaseDate ?? "No info"))
                
                ScrollView {
                    Text(movie.overview ?? "No overview")
                        .italic()
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 150)
                
                Text("Original Language: " + (movie.originalLanguage ?? "No info"))
                Text("Vote Average: \(movie.voteAverage ?? -1.0)")
                
                // Cast list ##################################################
                    if isCastandCrewFetched{ // Wait for cast and crew data to be fetched from server
                        Text("Cast").font(.title2).bold()
                        PersonListView(castAndCrew: castAndCrew!.cast, imageCacher: imageCacher)
                        
                        Text("Crew").font(.title2).bold()
                        PersonListView(castAndCrew: castAndCrew!.crew, imageCacher: imageCacher)

                    }
                }
                
            }
            .padding(.horizontal, 10)
            .onAppear {
                Task {
                    do {
                        trailerKey = try await controller.getTrailerKey(id: movie.id)
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            }
            .onAppear{
                Task{
                    print("in task ##########################")
                    do {
                        castAndCrew = try await controller.getEntertainers(movieID: movie.id)
                        isCastandCrewFetched = true
                    } catch {
                        self.error = error.localizedDescription
                        print("eror fetching cast ####################")
                    }
                }
            }
        }
    }


//  PopcornVaultApp.swift
//  PopcornVault
//
//  Created by Noga Rotem on 13/08/2024.

import SwiftUI
import Alamofire

protocol ScreenDisplay: View {
    func display()
}

// View of main page: Displays input textbox, recommanded movies bar and search result list. 
struct MainView: View {
    @State private var input = ""
    @State private var text = "No searches made"
    private var controller = Controller()
    @State private var isSearchMade = false
    @State private var isTrendingFetched = false
    @State private var searchedMovies: [TMDBParser.MovieData] = []
    @State private var trendingMovies: [TMDBParser.MovieData] = []
    @FocusState private var isFocused: Bool
    
    @State private var isLoading = false
    @State private var isFinished = false
    @State private var currentPage = 1
    var imageURLPrefix = "https://image.tmdb.org/t/p/w500"
    private let imageCacher = ImageCacher(cacheDirName: "PopcornVault", expirationTimeUnit: .days, amount: 1)

    var body: some View {
        NavigationView {
            ZStack {
                
                // Background Image ########################################################
                
                // Fetch today's most trending movie and display poster (darkened) as the app background
                if isTrendingFetched{
                    AsyncImage(url: URL(string: imageURLPrefix + (trendingMovies[0].posterPath ?? ""))) { image in
                        image.resizable()
                            .aspectRatio(9/19.5, contentMode: .fit)// iPhone 14 pro ratio
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .edgesIgnoringSafeArea(.all)
                            .overlay(Color.black.opacity(0.7).blendMode(.multiply))
                    } placeholder: {
                        Color.black
                    }
                }

                VStack {
                    
                    // SEARCH BAR ########################################################
                    
                    // Textbox for user input
                    TextField("Search Movie", text: $input)
                        .textFieldStyle(.roundedBorder)
                        .padding()
                        .frame(width: 400)
                        .focused($isFocused) // Moves cruisor to textbox (isFocused = true on appear of the containing VStack
                        .onSubmit {
                            Task {
                                await performSearch() // Once input is provided - Fetch data
                            }
                        }

                    // RECOMMENDED FOR YOU ########################################################
                    
                    // Display horizontal bar of most trending movies of current day
                    if isTrendingFetched { // Trending list is fetched upon containing VStack creation
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recommended for you")
                                .foregroundColor(Color.white)
                                .bold()
                            ScrollView(.horizontal) {
                                HStack(alignment: .bottom) {
                                    ForEach(trendingMovies, id: \.self) { movie in
                                        NavigationLink(destination: MovieView(movie: movie, controller: controller, imageCacher: imageCacher)) { // Click on movie VStack sends to view with details
                                            VStack {
                                                Text(movie.title ?? "")
                                                    .foregroundColor(Color.white)
                                                    .frame(width: 80)
                                                    .truncationMode(.tail) // Long names truncated with "..."
                                                    .lineLimit(1)

                                                // Display image from cache. If not cached - request sever
                                                CachedImageView(imageCacher: imageCacher, urlPrefix: imageURLPrefix, urlID: (movie.posterPath ?? "")).aspectRatio(contentMode: .fit)
                                                    .frame(width: 80)
                                            }
                                            .padding(10)
                                            .border(Color.white)
                                        }
                                    }
                                }
                                .background(Color.black)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .border(Color.white, width: 1)
                    }

                    Spacer()

                    // MOVIE LIST ########################################################
                    
                    // display "No search made". Once seache is made - display a list of movies with names containing the input
                    if isSearchMade {
                        List {
                            ForEach(searchedMovies, id: \.self) { movie in
                                NavigationLink(destination: MovieView(movie: movie, controller: controller, imageCacher: imageCacher)) { // HStack leads to movie detail MovieView
                                    HStack {
                                        // Display image from cache if exists or fetch from server
                                        CachedImageView(imageCacher: imageCacher, urlPrefix: imageURLPrefix, urlID: (movie.posterPath ?? "")).frame(width: 80, height: 80)

                                        Text(movie.title ?? "No Movie Title")
                                            .font(.subheadline)
                                            .lineLimit(1)
                                            .truncationMode(.tail)
                                    }
                                }
                            }
                            
                            // Show spinning circle at the end of list while new content is loading
                            if !isFinished && !isLoading { // Check if no data loading and end of data not reached
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                    .onAppear {
                                        Task {
                                            await loadMoreContent() // Once use reached end of list - load more content
                                        }
                                    }
                            }
                        }
                        .listStyle(PlainListStyle())
                    } else { // No list to show (no input / input returned no results)
                        Text(text)
                            .foregroundColor(.white)
                        Spacer()
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .onAppear { isFocused = true }
                .onAppear {
                    Task {
                        await loadTrendingMovies() // Get trending immediatley
                    }
                }
            }
        }
    }

    // Utilized controller to get a list of movies containing the unput from server
    private func performSearch() async {
        isFinished = false // In case it was set in prev input search
        do {
            let response = try await controller.getMovie(input: input, page: 1)
            searchedMovies = response
            currentPage = 1 // Bring page counter back to 1 in case it was incremented in prev input search
            if searchedMovies.isEmpty{ // If input turned in no results - show "no results"
                text = "No results"
            } else{
                isSearchMade = true // if input turned in results - set flag to promt creation of result list
            }
        } catch {
            displayError(error.localizedDescription)
        }
    }

    // Utilized controller to fetch the next page of movies containing the input from server
    private func loadMoreContent() async {
        isLoading = true // Prevents methods from being called while it is working
        do {
            currentPage += 1 // Get next page of data
            let response = try await controller.getMovie(input: input, page: currentPage)
            if response.isEmpty{ // If reached end of server's data
                isFinished = true // Prevent new calls to func
                isLoading = false // Function finished and can be called again (won't until isFinised = true by new input)
                return
            }
            searchedMovies.append(contentsOf: response) // Ad new movies to list
            isLoading = false
        } catch {
            displayError(error.localizedDescription)
            isLoading = false
        }
    }
    

    // Utilized controller to fetch today's most trending movies from server
    private func loadTrendingMovies() async {
        do {
            trendingMovies = try await controller.getTrending()
            isTrendingFetched = true // set flag to promt creation of "recommanded for you" bar
        } catch {
            displayError(error.localizedDescription)
        }
    }

    // Display errors as text on the screen
    private func displayError(_ text: String) {
        isSearchMade = false
        self.text = text
    }
}



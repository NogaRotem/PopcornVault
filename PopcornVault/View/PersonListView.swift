//
//  PersonView.swift
//  PopcornVault
//
//  Created by Mor on 22/08/2024.
//

import SwiftUI

struct PersonListView: View {
    @State var castAndCrew: [TMDBParser.EntertainerData]
    let imageCacher: ImageCacher
    private let imageURLPrefix = "https://image.tmdb.org/t/p/w500"


    var body: some View {
        ScrollView{
            VStack(alignment: .leading ,spacing: 0){
                ForEach(castAndCrew, id: \.self) { person in
                    HStack{
                        // Display image from cache if exists or fetch from server
                        CachedImageView(imageCacher: imageCacher, urlPrefix: imageURLPrefix, urlID: (person.profilePath ?? ""))
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60)
                            .padding(3)
                        
                        VStack(alignment: .leading, spacing: 10){
                            Text(person.name)
                                .bold()
                                .lineLimit(1)
                                .truncationMode(.tail)
                            
                            Text(person.character ?? "")
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                        .border(Color.gray)
                }
            }
        }.frame(height: 350)
            .border(Color.blue)
    }
}

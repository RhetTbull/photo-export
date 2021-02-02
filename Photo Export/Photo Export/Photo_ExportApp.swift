//
//  Photo_ExportApp.swift
//  Photo Export
//
//  Created by Jason Barrie Morley on 30/01/2021.
//

import Combine
import SwiftUI
import Photos


class Photo: Identifiable {

    let manager: Manager
    var cancellable: Cancellable?

    var id: String {
        asset.localIdentifier
    }

    var databaseUUID: String {
        return String(asset.localIdentifier.prefix(36))
    }

    let asset: PHAsset

    init(manager: Manager, asset: PHAsset) {
        self.manager = manager
        self.asset = asset
    }

    func export(to url: URL, completion: @escaping (Result<Bool, Error>) -> Void) -> Cancellable {

        // TODO: This is a hack.
        let cancellable = manager.image(for: self)
            .receive(on: DispatchQueue.global(qos: .background))
            .tryMap { data -> Data in
                let metadata = try self.manager.metadata(for: self.databaseUUID)
                guard let title = metadata.title else {
                    return data
                }
                return data.set(title: title)!
            }
            .tryMap { data in
                try data.write(to: url)
            }
            .sink(receiveCompletion: { result in
                switch result {
                case .finished:
                    completion(.success(true))
                case .failure(let error):
                    completion(.failure(error))
                }
            }, receiveValue: { _ in })

        self.cancellable = cancellable
        
        return cancellable
    }

}

@main
struct Photo_ExportApp: App {

    var manager = Manager()

    var body: some Scene {
        WindowGroup {
            ContentView(manager: manager)
                .preferredColorScheme(.dark)
        }
    }
}

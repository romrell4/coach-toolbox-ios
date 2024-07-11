//
//  DataWrapper.swift
//  National Champions
//
//  Created by Eric Romrell on 5/30/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import Foundation

enum Result<T> {
	case Success(_ result: T)
	case Error(_ message: String?)
}

struct DataWrapper: Codable {
	let players: [Player]
	let matches: [Match]
	
	static func load(from url: String = "https://romrell4.github.io/national-champions-ios/league_all_data.json", completionHandler: @escaping (Result<DataWrapper>) -> Void) {
		if let url = URL(string: url) {
			URLSession.shared.dataTask(with: url) { data, _, _ in
				DispatchQueue.main.async {
					do {
						if let data = data {
							do {
								completionHandler(.Success(try DataWrapper(data: data)))
							}
						} else {
							completionHandler(.Error("Unable to process data from \(url)"))
						}
					} catch {
						switch error as? MyError {
						case .unableToImport(let message):
							completionHandler(.Error(message))
						default:
							completionHandler(.Error("Error processing data from \(url): \(error)"))
						}
					}
				}
			}.resume()
		} else {
			completionHandler(.Error("Unable to connect to that URL"))
		}
	}
}

extension DataWrapper {
	init(data: Data) throws {
		//First try deserializing with the JSONDecoder. This will only succeed if the data was exported using the encoder
		if let allData = try? JSONDecoder().decode(DataWrapper.self, from: data) {
			allData.players.save()
			allData.matches.save()
			self = allData
		} else {
			let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: [[String: Any]]]

			//Deserialize players, then overwrite existing list
			dict?["players"]?.compactMap { Player(dict: $0) }.save()

			//Clear all matches, deserialize new matches, then insert each - which will update the players
			[Match]().save()
			try dict?["matches"]?.forEach {
				try Match(dict: $0)?.insert()
			}

			self.init(players: Player.loadAll(), matches: Match.loadAll())
		}
	}
}

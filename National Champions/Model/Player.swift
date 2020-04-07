//
//  Player.swift
//  National Champions
//
//  Created by Eric Romrell on 3/19/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import Foundation

private let DEFAULTS_KEY = "players"

struct Player: Codable, Equatable {
	let playerId: String
	var name: String
	var singlesRating: Double {
		didSet {
			previousSinglesRatings.append(singlesRating)
		}
	}
	var doublesRating: Double {
		didSet {
			previousDoublesRatings.append(doublesRating)
		}
	}
	var previousSinglesRatings: [Double]
	var previousDoublesRatings: [Double]
	
	func update() {
		var players = Player.loadAll()
		if let index = players.firstIndex(where: { $0.playerId == playerId }) {
			players[index] = self
			players.save()
		}
	}
	
	static func loadAll() -> [Player] {
		guard
			let data = UserDefaults.standard.data(forKey: DEFAULTS_KEY),
			let array = try? JSONDecoder().decode([Player].self, from: data)
			else { return [] }
		
		return array
	}
	
	static func loadFromUrl(url urlString: String, completionHandler: @escaping (Result<Player>) -> Void) {
		URL(string: urlString).get(completionHandler: completionHandler) { dictArray in
			let newPlayers = dictArray.compactMap { dict -> Player? in
				if let name = dict["name"] as? String,
					let singlesRating = dict["singles_rating"] as? Double,
					let doublesRating = dict["doubles_rating"] as? Double {
					
					return Player(
						playerId: UUID().uuidString,
						name: name,
						singlesRating: singlesRating,
						doublesRating: doublesRating,
						previousSinglesRatings: dict["previous_singles_ratings"] as? [Double] ?? [],
						previousDoublesRatings: dict["previous_doubles_ratings"] as? [Double] ?? []
					)
				} else {
					return nil
				}
			}
			
			//Combine old players with new players by name
			var allPlayers = Player.loadAll()
			for newPlayer in newPlayers {
				if let oldPlayerIndex = allPlayers.firstIndex(where: { $0.name == newPlayer.name }) {
					allPlayers[oldPlayerIndex] = newPlayer
				} else {
					allPlayers.append(newPlayer)
				}
			}
			allPlayers.save()
			return allPlayers
		}
	}
	
	static func == (lhs: Player, rhs: Player) -> Bool {
		return lhs.playerId == rhs.playerId
	}
}

extension Array where Element == Player {
	func save() {
		try? UserDefaults.standard.set(JSONEncoder().encode(self), forKey: DEFAULTS_KEY)
	}
}

//
//  Match.swift
//  Coach Toolbox
//
//  Created by Eric Romrell on 3/22/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import Foundation

private let DEFAULTS_KEY = "matches"
private let GAME_VALUE = 0.06

struct Match: Codable {
	let matchId: String
	let matchDate: Date
	let winners: [Player]
	let losers: [Player]
	let winnerSet1Score: Int?
	let loserSet1Score: Int?
	let winnerSet2Score: Int?
	let loserSet2Score: Int?
	let winnerSet3Score: Int?
	let loserSet3Score: Int?
	
	private var set1: MatchSet { MatchSet(winnerScore: winnerSet1Score, loserScore: loserSet1Score) }
	private var set2: MatchSet { MatchSet(winnerScore: winnerSet2Score, loserScore: loserSet2Score) }
	private var set3: MatchSet { MatchSet(winnerScore: winnerSet3Score, loserScore: loserSet3Score) }
	
	var scoreText: String {
		[set1.scoreText, set2.scoreText, set3.scoreText].compactMap { $0 }.joined(separator: ", ")
	}
	
	static func loadAll() -> [Match] {
		guard
			let data = UserDefaults.standard.data(forKey: DEFAULTS_KEY),
			let array = try? JSONDecoder().decode([Match].self, from: data)
			else { return [] }
		
		return array
	}
	
	var wasCompleted: Bool {
		if set1.wasCompleted, set2.wasCompleted {
			if set1.winnerWon == true && set2.winnerWon == true && !set3.wasPlayed {
				return true
			} else if set1.winnerWon != set2.winnerWon, set3.wasSet3Completed {
				return true
			}
		}
		return false
	}
	
	func computeRatingChanges() -> ([Double], [Double]) {
		let winnerTotalGames = [winnerSet1Score, winnerSet2Score, winnerSet3Score].compactMap { $0 }.reduce(0, { $0 + $1 })
		let loserTotalGames = [loserSet1Score, loserSet2Score, loserSet3Score].compactMap { $0 }.reduce(0, { $0 + $1 })
		return (
			computePlayerRatingChanges(for: winners, against: losers, gameDiff: winnerTotalGames - loserTotalGames),
			computePlayerRatingChanges(for: losers, against: winners, gameDiff: loserTotalGames - winnerTotalGames)
		)
	}
	
	private func computePlayerRatingChanges(for players: [Player], against opponents: [Player], gameDiff: Int) -> [Double] {
		let ratingDiff = Double(gameDiff) * GAME_VALUE
		if players.count == 1, opponents.count == 1 {
			let matchRating = opponents[0].singlesRating + ratingDiff
			let newRating = (players[0].previousSinglesRatings + [matchRating]).average()
			return [trunc(newRating)]
		} else if players.count == 2, opponents.count == 2 {
			let matchRating = opponents.map { $0.doublesRating }.sum() + ratingDiff
			let player1MatchRating = matchRating - players[1].doublesRating
			let player2MatchRating = matchRating - players[0].doublesRating
			let player1NewRating = (players[0].previousDoublesRatings + [player1MatchRating]).average()
			let player2NewRating = (players[1].previousDoublesRatings + [player2MatchRating]).average()
			return [trunc(player1NewRating), trunc(player2NewRating)]
		} else {
			fatalError("You can only be playing singles or doubles")
		}
	}
	
	private func trunc(_ value: Double) -> Double {
		//Round to the nearest thousands place, then truncate to the hundreds palce
		Double(Int(round(value * 1000) / 1000 * 100)) / 100.0
	}
	
	func save() {
		//TODO: Update players ratings and display changes
		//TODO: Update previous matches
		(Match.loadAll() + [self]).save()
	}
}
	
struct MatchSet {
	let winnerScore: Int?
	let loserScore: Int?
	
	var scoreText: String? {
		if let winnerScore = winnerScore, let loserScore = loserScore {
			return "\(winnerScore)-\(loserScore)"
		}
		return nil
	}
	
	var wasPlayed: Bool {
		return winnerScore != nil && loserScore != nil
	}
	
	var wasCompleted: Bool {
		let scores = [winnerScore, loserScore].compactMap { $0 }.sorted()
		if scores.count == 2 {
			return (scores[1] == 6 && scores[0] < 6) || (scores[1] == 7 && [5, 6].contains(scores[0]))
		}
		return false
	}
	
	var wasSet3Completed: Bool {
		if let winnerScore = winnerScore, let loserScore = loserScore {
			return (winnerScore == 7 && [5, 6].contains(loserScore)) || (winnerScore == 6 && loserScore < 6) || (winnerScore == 1 && loserScore == 0)
		}
		return false
	}
	
	var winnerWon: Bool? {
		if let winnerScore = winnerScore, let loserScore = loserScore {
			return winnerScore > loserScore
		}
		return nil
	}
}

extension Array where Element == Match {
	func save() {
		try? UserDefaults.standard.set(JSONEncoder().encode(self), forKey: DEFAULTS_KEY)
	}
}

extension Array where Element == Double {
	func sum() -> Double {
		reduce(0, { $0 + $1 })
	}
	
	func average() -> Double {
		sum() / Double(count)
	}
}

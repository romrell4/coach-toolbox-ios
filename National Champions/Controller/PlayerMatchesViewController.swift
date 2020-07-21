//
//  PlayerRatingsViewController.swift
//  National Champions
//
//  Created by Eric Romrell on 3/26/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

private let DATE_FORMATTER: DateFormatter = {
	let formatter = DateFormatter()
	formatter.dateStyle = .short
	formatter.timeStyle = .short
	return formatter
}()

class PlayerMatchesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MatchTableViewCellDelegate {

	@IBOutlet private weak var filterControl: UISegmentedControl!
	@IBOutlet private weak var tableView: UITableView!
	
	var player: Player!
	
	private var allMatches = [Match]() {
		didSet {
			filterAndReload()
		}
	}
	private var filteredMatches = [Match]()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.title = player.name
		
		allMatches = Match.loadAll().filter {
			$0.allPlayers.map { $0.playerId }.contains(player.playerId)
		}
		tableView.tableFooterView = UIView()
		tableView.reloadData()
    }
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? PlayerChartsViewController {
			vc.player = player
		} else if let vc = segue.destination as? PlayerCompanionshipsViewController {
			vc.player = player
		}
	}
	
	//UITableView
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		filteredMatches.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		
		if let cell = cell as? MatchTableViewCell {
			let match = filteredMatches[indexPath.row]
			cell.setMatch(filteredMatches[indexPath.row], forPlayer: match.allPlayers.first { $0.playerId == player.playerId }, delegate: self)
		}
		return cell
	}
	
	//MatchTableViewCell
	
	func displayCompRating(me: Player, comp: Player) {
		let compRatings: [Double] = Match.loadAll().compactMap {
			if $0.winners.hasPlayers(me, comp) {
				return $0.findRatings(for: me)?.1
			} else if $0.losers.hasPlayers(me, comp) {
				return $0.findRatings(for: me)?.1
			} else {
				return nil
			}
		}
		displayAlert(title: "Companionship Ratings", message: "\(me.name) and \(comp.name)\nAverage rating: \(compRatings.average().trunc())\nPlayed together \(compRatings.count) time\(compRatings.count == 1 ? "" : "s")")
	}
	
	//Listeners
	
	@IBAction func optionsTapped(_ sender: Any) {
		let alert = UIAlertController(title: "Select an Option", message: nil, preferredStyle: .actionSheet)
		alert.addAction(UIAlertAction(title: "Charts", style: .default) { (_) in
			self.performSegue(withIdentifier: "charts", sender: nil)
		})
		alert.addAction(UIAlertAction(title: "Companionships", style: .default) { (_) in
			self.performSegue(withIdentifier: "comps", sender: nil)
		})
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		self.present(alert, animated: true)
	}
	
	@IBAction func filterAndReload(_ sender: Any? = nil) {
		filteredMatches = allMatches.filter {
			switch self.filterControl.selectedSegmentIndex {
			case 1: return $0.isSingles
			case 2: return $0.isDoubles
			default: return true
			}
		}
		tableView.reloadData()
	}
}

fileprivate extension Array where Element == Player {
	func hasPlayers(_ players: Player...) -> Bool {
		return self.count == players.count && players.allSatisfy { self.contains($0) }
	}
}

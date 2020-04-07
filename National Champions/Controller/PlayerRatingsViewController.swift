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

class PlayerRatingsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

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
		
		allMatches = Match.loadAll().filter {
			$0.allPlayers.map { $0.playerId }.contains(player.playerId)
		}.sorted { lhs, rhs in
			lhs.matchDate > rhs.matchDate
		}
		tableView.tableFooterView = UIView()
		tableView.reloadData()
    }
	
	//UITableView
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		filteredMatches.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		let match = filteredMatches[indexPath.row]
		let matchPlayer = match.allPlayers.first { $0.playerId == player.playerId }
		cell.imageView?.image = match.isSingles ? #imageLiteral(resourceName: "Singles") : #imageLiteral(resourceName: "Doubles")
		cell.textLabel?.text = DATE_FORMATTER.string(from: match.matchDate)
		cell.detailTextLabel?.text = match.isSingles ? matchPlayer?.singlesRating.description : matchPlayer?.doublesRating.description
		return cell
	}
	
	//Listeners
	
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

//
//  MatchHistoryViewController.swift
//  National Champions
//
//  Created by Eric Romrell on 3/23/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

class MatchHistoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, EditMatchDelegate {
	
	@IBOutlet private weak var tableView: UITableView!
	@IBOutlet private weak var spinner: UIActivityIndicatorView!
	
	private var matches = [Match]() {
		didSet {
			self.tableView.reloadData()
		}
	}
	private let players = Player.loadAll()

    override func viewDidLoad() {
        super.viewDidLoad()
        
		tableView.tableFooterView = UIView()
    }
	
	override func viewWillAppear(_ animated: Bool) {
		reloadMatches()
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if let vc = segue.destination as? EditMatchViewController, let match = sender as? Match {
			vc.match = match
			vc.delegate = self
		}
	}
	
	//UITableView functions
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return matches.count
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		if let cell = cell as? MatchTableViewCell {
			cell.setMatch(matches[indexPath.row])
		}
		return cell
	}
	
	func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return UISwipeActionsConfiguration(actions: [
			UIContextualAction(style: .destructive, title: "Delete") { (_, _, _) in
				self.matches[indexPath.row].delete()
				self.reloadMatches()
			}
		])
	}
	
	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		return UISwipeActionsConfiguration(actions: [
			UIContextualAction(style: .normal, title: "Edit") { (_, _, _) in
				self.tableView.reloadRows(at: [indexPath], with: .automatic)
				self.performSegue(withIdentifier: "editMatch", sender: self.matches[indexPath.row])
			}
		])
	}
	
	//MARK: EditMatchDelegate
	
	func matchEdited() {
		reloadMatches()
	}
	
	//MARK: Listeners
	
	@IBAction func importTapped(_ sender: Any) {
		let alert = UIAlertController(title: "Export Matches", message: "How would you like to export your matches?", preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "Export CSV", style: .default, handler: { (_) in
			UIPasteboard.general.string = self.matches.toCSV()
			self.displayAlert(title: "Success", message: "The data has been copied to your clipboard. Feel free to paste it wherever.")
		}))
		alert.addAction(UIAlertAction(title: "Export JSON", style: .default, handler: { (_) in
			UIPasteboard.general.string = try? String(data: JSONEncoder().encode(self.matches), encoding: .utf8)
			self.displayAlert(title: "Success", message: "The data has been copied to your clipboard. Feel free to paste it wherever.")
		}))
		alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
		present(alert, animated: true)
	}
	
	//MARK: Private functions
	
	private func reloadMatches() {
		matches = Match.loadAll().sorted { (lhs, rhs) -> Bool in
			return lhs.matchDate > rhs.matchDate
		}
	}
}

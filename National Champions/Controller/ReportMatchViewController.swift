//
//  ReportMatchViewController.swift
//  National Champions
//
//  Created by Eric Romrell on 3/18/20.
//  Copyright © 2020 Eric Romrell. All rights reserved.
//

import UIKit

class ReportMatchViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
	
	@IBOutlet private weak var winner1TextField: UITextField!
	@IBOutlet private weak var winner2TextField: UITextField!
	@IBOutlet private weak var loser1TextField: UITextField!
	@IBOutlet private weak var loser2TextField: UITextField!
	@IBOutlet private weak var winnerSet1: UITextField!
	@IBOutlet private weak var loserSet1: UITextField!
	@IBOutlet private weak var winnerSet2: UITextField!
	@IBOutlet private weak var loserSet2: UITextField!
	@IBOutlet private weak var winnerSet3: UITextField!
	@IBOutlet private weak var loserSet3: UITextField!
	@IBOutlet private weak var explanationView: UITextView!
	
	private var playerTextFields: [UITextField] {
		[winner1TextField, winner2TextField, loser1TextField, loser2TextField]
	}
	private var scoreTextFields: [UITextField] {
		[winnerSet1, loserSet1, winnerSet2, loserSet2, winnerSet3, loserSet3]
	}
	private var allTextFields: [UITextField] {
		playerTextFields + scoreTextFields
	}
	
	private var players = [Player?]()
	private var winner1: Player? {
		didSet {
			winner1TextField.text = winner1?.name
		}
	}
	private var winner2: Player? {
		didSet {
			winner2TextField.text = winner2?.name
		}
	}
	private var loser1: Player? {
		didSet {
			loser1TextField.text = loser1?.name
		}
	}
	private var loser2: Player? {
		didSet {
			loser2TextField.text = loser2?.name
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.navigationItem.setTitle("Report a Match", subtitle: Bundle.main.fullVersionNumber)
		let titleTap = UITapGestureRecognizer(target: self, action: #selector(self.titleTapped(_:)))
		self.navigationItem.titleView?.isUserInteractionEnabled = true
		self.navigationItem.titleView?.addGestureRecognizer(titleTap)
		
		playerTextFields.forEach {
			$0.inputView = UIPickerView(delegate: self)
		}
		allTextFields.forEach {
			$0.delegate = self
		}
		
		scoreTextFields.forEach {
			$0.addTarget(self, action: #selector(textFieldDidChange(textField:)), for: .editingChanged)
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		reloadPlayers()
	}
	
	//UIPickerView delegate
	
	func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { players.count }
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		players[row]?.name
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		if !players.isEmpty {
			if winner1TextField.isFirstResponder {
				winner1 = players[row]
			} else if winner2TextField.isFirstResponder {
				winner2 = players[row]
			} else if loser1TextField.isFirstResponder {
				loser1 = players[row]
			} else if loser2TextField.isFirstResponder {
				loser2 = players[row]
			}
		}
		self.navigationItem.rightBarButtonItem?.isEnabled = getMatch() != nil
	}
	
	//UITextField delegate
	
	func textFieldDidBeginEditing(_ textField: UITextField) {
		if textField.text?.isEmpty != false {
			if textField == winner1TextField {
				winner1 = players[0]
			} else if textField == winner2TextField {
				winner2 = players[0]
			} else if textField == loser1TextField {
				loser1 = players[0]
			} else if textField == loser2TextField {
				loser2 = players[0]
			}
		}
		self.navigationItem.rightBarButtonItem?.isEnabled = getMatch() != nil
	}

	func textFieldDidEndEditing(_ textField: UITextField) {
		self.navigationItem.rightBarButtonItem?.isEnabled = getMatch() != nil
	}
	
	//Listeners
	
	@objc private func titleTapped(_ sender: Any) {
		if let url = URL(string: "https://national-champions-league.s3-us-west-2.amazonaws.com/index.html") {
			UIApplication.shared.open(url)
		}
	}
	
	@objc private func textFieldDidChange(textField: UITextField) {
		//Only force the responder to change if they just added a score. If they are correcting, don't switch the field
		if textField.text?.count == 1, let index = scoreTextFields.firstIndex(of: textField) {
			if let nextTextField = scoreTextFields[safe: index + 1] {
				nextTextField.becomeFirstResponder()
			} else {
				textField.resignFirstResponder()
			}
		}
	}
	
	@IBAction func viewTapped(_ sender: Any) {
		self.view.endEditing(true)
	}
	
	@IBAction func clear(_ sender: Any) {
		self.winner1 = nil
		self.winner2 = nil
		self.loser1 = nil
		self.loser2 = nil
		self.allTextFields.forEach {
			$0.text = nil
		}
		
		self.navigationItem.rightBarButtonItem?.isEnabled = false
		
		self.explanationView.text = nil
		view.endEditing(true)
	}
	
	@IBAction func saveMatch(_ sender: Any) {
		if let match = getMatch() {
			let save = {
				self.view.endEditing(true)
				self.explanationView.text = match.getChangeDescription()
				match.insert()
				self.reloadPlayers()
			}
			
			if !match.wasCompleted {
				let alert = UIAlertController(title: "Warning", message: "This match is incomplete. Are you sure you'd like to record it anyway?", preferredStyle: .alert)
				alert.addAction(UIAlertAction(title: "Save", style: .default) { (_) in
					save()
				})
				alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
				present(alert, animated: true)
			} else {
				save()
			}
			
			displayAlert(title: "Success", message: "Match was saved successfully")
		} else {
			displayAlert(title: "Error", message: "An error occurred while trying to save your match. Please make sure all fields are entered properly.")
		}
	}
	
	//Private functions
	
	private func reloadPlayers() {
		// Add a "nil" so that they can deselect a player
		let allPlayers = Player.loadAll()
		players = (allPlayers + [nil]).sorted { (lhs, rhs) -> Bool in
			if let lhs = lhs, let rhs = rhs {
				return lhs.name < rhs.name
			}
			return true
		}
		
		//If they haven't added any players yet, send them to the players screen
		if players.compactMap({ $0 }).isEmpty {
			self.tabBarController?.selectedIndex = 1
		}
		
		//Reload the players that are cached
		if let player = winner1 {
			winner1 = Player.find(player, playerList: allPlayers)
		}
		if let player = winner2 {
			winner2 = Player.find(player, playerList: allPlayers)
		}
		if let player = loser1 {
			loser1 = Player.find(player, playerList: allPlayers)
		}
		if let player = loser2 {
			loser2 = Player.find(player, playerList: allPlayers)
		}
	}
	
	private func getMatch() -> Match? {
		//They must either have 2 distinct players, or 4 distinct players
		if (Set([winner1, loser1].compactMap { $0?.playerId }).count == 2 && winner2 == nil && loser2 == nil) ||
			Set([winner1, winner2, loser1, loser2].compactMap { $0?.playerId }).count == 4 {
			return Match(
				matchId: UUID().uuidString,
				matchDate: Date(),
				winners: [winner1, winner2].compactMap { $0 },
				losers: [loser1, loser2].compactMap { $0 },
				scores: [
					self.winnerSet1.toInt(),
					self.loserSet1.toInt(),
					self.winnerSet2.toInt(),
					self.loserSet2.toInt(),
					self.winnerSet3.toInt(),
					self.loserSet3.toInt()
				]
			)
		}
		return nil
	}
}

extension UITextField {
	func toInt() -> Int? {
		if let text = self.text {
			return Int(text)
		}
		return nil
	}
}

extension UIPickerView {
	convenience init(delegate: UIPickerViewDelegate & UIPickerViewDataSource) {
		self.init()
		self.delegate = delegate
		self.dataSource = dataSource
	}
}

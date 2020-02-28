//
//  MyMovieCell.swift
//  MyMovies
//
//  Created by Kerby Jean on 2/28/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit


class MyMovieCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var watchedButton: UIButton!
    
    static var id: String {
        return String(describing: self)
    }
    
    var movie: Movie? {
        didSet{
            updateViews()
        }
    }
    
    @IBAction func watchedToggle(_ sender: UIButton) {
        movie!.hasWatched.toggle()
        let watched = movie?.hasWatched != movie?.hasWatched
        watched ? sender.setTitle("Unwatched", for: .normal) : sender.setTitle("Watched", for: .normal)
        do {
            try CoreDataStack.shared.save()
        } catch {
            NSLog("Error modifying movie: \(error)")
        }
    }
    
    func updateViews() {
        guard let movie = movie else { return }
        titleLabel.text = movie.title
        movie.hasWatched ? watchedButton.setTitle("Watched", for: .normal) : watchedButton.setTitle("Unwatched", for: .normal)
    }
}

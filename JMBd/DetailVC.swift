//
//  DetailVC.swift
//  JMBd
//
//  Created by Timple Soft on 05/12/16.
//  Copyright © 2016 TimpleSoft. All rights reserved.
//

import UIKit
import Kingfisher

class DetailVC: UIViewController {

    @IBOutlet weak var btnFavorite: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var lblTitle: UILabel!
    @IBOutlet weak var lblDirector: UILabel!
    @IBOutlet weak var lblCategory: UILabel!
    @IBOutlet weak var txtViewSummary: UITextView!
    
    let dataProvider = LocalCoreDataService()
    var movie : Movie?
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let movie = movie {
            
            self.title = movie.title
            
            if let image = movie.image {
                imageView.kf.setImage(with: ImageResource(downloadURL: URL(string: image)!))
            }
            
            lblTitle.text = movie.title
            lblCategory.text = movie.category
            lblDirector.text = movie.director
            txtViewSummary.text = movie.summary
            
            configureFavoriteButton()
            
        }
    }
    
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        txtViewSummary.scrollRangeToVisible(NSMakeRange(0, 0))
    }
    
    
    @IBAction func favoritePressed(_ sender: UIButton) {
        if let movie = self.movie {
            dataProvider.markUnmarkFavorite(movie: movie)
            configureFavoriteButton()
        }
    }
    
    func configureFavoriteButton() {
        if let movie = self.movie {
            if dataProvider.isMovieFavorite(movie: movie) {
                btnFavorite.setBackgroundImage(#imageLiteral(resourceName: "btn-on"), for: .normal)
                btnFavorite.setTitle("¡Quiero verla!", for: .normal)
            } else {
                btnFavorite.setBackgroundImage(#imageLiteral(resourceName: "btn-off"), for: .normal)
                btnFavorite.setTitle("No me interesa", for: .normal)
            }
        }
    }
    
}

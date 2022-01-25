//
//  ViewController.swift
//  ScanPaymentCard
//
//  Created by Caroline LaDouce on 1/23/22.
//

import UIKit

class MainViewController: UIViewController {
    
    
    let cardNumberLabel = UILabel()
    var cardNumberText: String = ""
    
    let scanCardButton = UIButton(type: .system)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        view.backgroundColor = .white
        
        view.addSubview(cardNumberLabel)
        view.addSubview(scanCardButton)

        setupCardNumberLabel()
        setupScanCardButton()
        
        self.view = view
    }
    
    
    func setupCardNumberLabel() {
        cardNumberLabel.text = cardNumberText
        cardNumberLabel.textAlignment = .center
        cardNumberLabel.font = UIFont.systemFont(ofSize: 18)
        cardNumberLabel.textColor = .systemGreen
        cardNumberLabel.frame = CGRect(x: 0, y: 0, width: cardNumberLabel.intrinsicContentSize.width, height: cardNumberLabel.intrinsicContentSize.height)
        
        cardNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([cardNumberLabel.topAnchor.constraint(equalTo: view.centerYAnchor, constant: view.frame.height / -8 )])
        
        cardNumberLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
    }
    
    
    func setupScanCardButton() {
        scanCardButton.setTitle("Scan Payment Card", for: .normal)
        
        scanCardButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scanCardButton.topAnchor.constraint(equalTo: cardNumberLabel.bottomAnchor, constant: view.frame.height / 24),
            scanCardButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        scanCardButton.addTarget(self, action: #selector(scanCardButtonPressed(_:)), for: .touchDown)
    }
    
    
    @objc func scanCardButtonPressed(_ sender: UIButton) {
        print("pressed")
        
        let paymentCardExtractionViewController = PaymentCardExtractionViewController(resultsHandler: { paymentCardNumber in
            
            print(paymentCardNumber)
            self.cardNumberLabel.text = paymentCardNumber
            self.dismiss(animated: true, completion: nil)
        })
        
        paymentCardExtractionViewController.modalPresentationStyle = .fullScreen
        self.present(paymentCardExtractionViewController, animated: true, completion: nil)
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}

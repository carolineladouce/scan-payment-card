# Scan Payment Card

This is my implementation of the [How to scan payment cards](https://anuragajwani.medium.com/how-to-scan-payment-cards-using-vision-framework-in-ios-9ab7394f7e94) tutorial by Anurag Ajwani (thanks Anurag!).  
This project is built programmatically using Swift, UIKit, AVFoundation, and Vision Framework.

## My Changes

Note: This project is currently designed to extract 16 digit payment card numbers. 
Credit and debit cards in the Visa and Mastercard network contain 16 digit card numbers. 
Amex cards contain 15 digits. 


When testing the project on my device, I found that the program was not detecting payment card numbers.

Through doing more digging and debugging, I confirmed that the program was able to:

- Detect a rectangle with the same aspect ratio as a payment card

- Draw a rectangle that outlines the detected rectangle

- Display the rectangle drawing to the screen to show the user that the rectangle is recognized as fitting the aspect ratio of a payment card and that the detected rectangle is tracked through the camera feed images 

- Extract and parse the text in the rectangle images


### The issue: 
Before explaining the issue, here is the full code of ```func extractPaymentCardNumber``` for reference:
```swift
   private func extractPaymentCardNumber(frame: CVImageBuffer, rectangle: VNRectangleObservation) -> String? {
        
        let cardPositionInImage = VNImageRectForNormalizedRect(rectangle.boundingBox, CVPixelBufferGetWidth(frame), CVPixelBufferGetHeight(frame))
        let ciImage = CIImage(cvImageBuffer: frame)
        let croppedImage = ciImage.cropped(to: cardPositionInImage)
        
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        
        let stillImageRequestHandler = VNImageRequestHandler(ciImage: croppedImage, options: [:])
        try? stillImageRequestHandler.perform([request])
        
        guard let texts = request.results as? [VNRecognizedTextObservation], texts.count > 0 else {
            // no text detected
            return nil
        }
        
        let digitsRecognized = texts
            .flatMap({ $0.topCandidates(10).map({ $0.string }) })
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .filter({ CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: $0)) })
        let _16digits = digitsRecognized.first(where: { $0.count == 16 })
        let has16Digits = _16digits != nil
        let _4digits = digitsRecognized.filter({ $0.count == 4 })
        let has4sections4digits = _4digits.count == 4
        
        let digits = _16digits ?? _4digits.joined()
        let digitsIsValid = (has16Digits || has4sections4digits) && self.checkDigits(digits)
        return digitsIsValid ? digits : nil
    }
```

Looking at the bottom ```func extractPaymentCardNumber```, 
when assigning the value of ```digitsRecognized``` the program was breaking apart the potential payment card number into multiple separate strings that were, in practice, too small for it to reliably join the strings back together into one 16 character string. 


Since the string that was being passed to func checkDigits was not a 16 character string, checkDigits immediately returned false and did not verify the checksum of the potential payment card number.

```swift
        let digitsRecognized = texts
            .flatMap({ $0.topCandidates(10).map({ $0.string }) })
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .filter({ CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: $0)) })
        let _16digits = digitsRecognized.first(where: { $0.count == 16 })
        let has16Digits = _16digits != nil
        let _4digits = digitsRecognized.filter({ $0.count == 4 })
        let has4sections4digits = _4digits.count == 4
        
        let digits = _16digits ?? _4digits.joined()
        let digitsIsValid = (has16Digits || has4sections4digits) && self.checkDigits(digits)
        return digitsIsValid ? digits : nil
```


### My solution:
16 digit card numbers can translate as a string containing 19 characters that include 16 integers and 3 whitespaces. 
So, I edited ```func extractPaymentCardNumber``` to check if a block of text in the detected rectangle image contains a string consisting of 19 characters. 
If the string contains 19 characters, it then removes the whitespace characters from the string. 
After removing the whitespace characters, it checks if the string contains 16 characters (potentially a 16 digit card number) and calls func checkDigits to perform a checksum on the 16 character string. 

```swift
        let textRecognized = texts
            .flatMap({ $0.topCandidates(10).map({ $0.string }) })
        var cardNumberString: String = ""
        var cardNumberStringNoSpaces: String = ""
        
        textRecognized.forEach { stringItemInTextRecognized in
            if stringItemInTextRecognized.count == 19 {
                cardNumberString = stringItemInTextRecognized
                cardNumberStringNoSpaces = cardNumberString.filter {!$0.isWhitespace}
            }
        }
        
        let cardNumberIsValid = (cardNumberStringNoSpaces.count == 16) && self.checkDigits(cardNumberStringNoSpaces)
        
        return cardNumberIsValid ? cardNumberStringNoSpaces : nil
```


## What I learned

- Standard payment card dimensions and card number formats

- Setting a minimum and maximum aspect ratio to a VNDetectRectanglesRequest() to detect rectangular-shaped objects with a specific aspect ratio

- Setting the aspect ratio with an error margin when detecting the payment card

- Extracting and parsing text from a rectangle image 

- Verifying a potential card number using Luhn’s algorithm (checksum)






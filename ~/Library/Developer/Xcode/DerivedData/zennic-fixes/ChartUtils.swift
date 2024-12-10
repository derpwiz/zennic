import Foundation
import Darwin

extension Double {
    /// Rounds the double value to the given number of decimal places
    public func roundedToPlaces(_ places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
    
    /// Rounds the double value to the nearest significant figure
    public func roundedToNextSignificant() -> Double {
        if self == 0 {
            return 0
        }
        
        let d = ceil(Darwin.log10(self < 0 ? -self : self))
        let pw = 1 - Int(d)
        let magnitude = Darwin.pow(10.0, Double(pw))
        return (self * magnitude).rounded() / magnitude
    }
    
    /// Returns string representation with specified decimal places
    public func formattedWithDecimalPlaces(_ places: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = places
        formatter.maximumFractionDigits = places
        
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
    
    /// The computed property to get the decimal places based on the value
    public var decimalPlaces: Int {
        if self == 0 {
            return 0
        }
        
        let i = self.roundedToNextSignificant()
        
        if i >= 1 {
            var count = 0
            var current = i
            
            while current >= 1.0 {
                current /= 10.0
                count += 1
            }
            
            return count
        } else {
            return Int(ceil(-Darwin.log10(i))) + 2
        }
    }
}

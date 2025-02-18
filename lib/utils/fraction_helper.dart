class FractionHelper {
  static double parseFraction(String value) {
    if (value.isEmpty) return 0;
    
    // Check if it contains a fraction
    if (value.contains('/')) {
      // Handle mixed numbers (e.g., "1 1/2")
      if (value.contains(' ')) {
        final parts = value.split(' ');
        final whole = double.parse(parts[0]);
        final fractionParts = parts[1].split('/');
        return whole + (double.parse(fractionParts[0]) / double.parse(fractionParts[1]));
      }
      // Handle simple fractions (e.g., "1/2")
      final parts = value.split('/');
      return double.parse(parts[0]) / double.parse(parts[1]);
    }
    
    // Handle plain numbers
    return double.parse(value);
  }

  static String formatFraction(double value) {
    if (value == 0) return '0';
    
    // Get the whole number part
    int whole = value.floor();
    double fraction = value - whole;
    
    // Common fractions to check (1/2, 1/4, 1/3, etc.)
    final Map<double, String> commonFractions = {
      1/2: '1/2',
      1/3: '1/3',
      2/3: '2/3',
      1/4: '1/4',
      3/4: '3/4',
      1/8: '1/8',
      3/8: '3/8',
      5/8: '5/8',
      7/8: '7/8',
    };
    
    // Find the closest common fraction
    String fractionStr = '';
    if (fraction > 0) {
      double minDiff = 1;
      commonFractions.forEach((key, value) {
        double diff = (fraction - key).abs();
        if (diff < minDiff) {
          minDiff = diff;
          fractionStr = value;
        }
      });
    }
    
    if (whole > 0 && fractionStr.isNotEmpty) {
      return '$whole $fractionStr"';
    } else if (whole > 0) {
      return '$whole"';
    } else if (fractionStr.isNotEmpty) {
      return '$fractionStr"';
    }
    
    return '$value"';
  }

  static bool isValidFraction(String value) {
    if (value.isEmpty) return true;
    
    try {
      parseFraction(value.replaceAll('"', ''));
      return true;
    } catch (e) {
      return false;
    }
  }
}

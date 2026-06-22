class ImpactCalculator {
  static double calculateCo2Saved(double plasticGrams) {
    return plasticGrams * 2.5 * 0.8;
  }

  static String formatWeight(double grams) {
    if (grams < 1000) return '${grams.toStringAsFixed(0)} g';
    return '${(grams / 1000).toStringAsFixed(2)} kg';
  }

  static String formatCo2(double co2Grams) {
    if (co2Grams < 1000) return '${co2Grams.toStringAsFixed(0)} g CO₂';
    return '${(co2Grams / 1000).toStringAsFixed(2)} kg CO₂';
  }

  static int estimateProductValue(String materialType, double weightGrams) {
    final rate = materialType == 'sachet_multilayer' ? 50.0 : 30.0;
    return (weightGrams * rate / 100).round();
  }
}

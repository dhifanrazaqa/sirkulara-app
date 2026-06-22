class VisualAnnotationModel {
  final String type; // arrow, circle, warning, highlight
  final double x; // relative x position (0.0 to 1.0)
  final double y; // relative y position (0.0 to 1.0)
  final String label; // tooltip or guide text

  const VisualAnnotationModel({
    required this.type,
    required this.x,
    required this.y,
    required this.label,
  });

  factory VisualAnnotationModel.fromMap(Map<String, dynamic> map) {
    return VisualAnnotationModel(
      type: map['type'] as String? ?? 'circle',
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      label: map['label'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'x': x,
      'y': y,
      'label': label,
    };
  }
}

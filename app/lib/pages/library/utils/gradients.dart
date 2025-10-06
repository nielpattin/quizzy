import "package:flutter/material.dart";

List<Color> gradientForIndex(int i) {
  final gradients = [
    [Colors.blue[400]!, Colors.purple[600]!],
    [Colors.green[400]!, Colors.teal[600]!],
    [Colors.orange[400]!, Colors.red[600]!],
    [Colors.pink[400]!, Colors.purple[700]!],
    [Colors.cyan[400]!, Colors.blue[700]!],
    [Colors.amber[400]!, Colors.orange[700]!],
    [Colors.lime[400]!, Colors.green[700]!],
    [Colors.indigo[400]!, Colors.purple[800]!],
    [Colors.deepOrange[400]!, Colors.brown[700]!],
    [Colors.teal[400]!, Colors.cyan[700]!],
    [Colors.purple[300]!, Colors.blue[400]!],
    [Colors.orange[300]!, Colors.brown[400]!],
    [Colors.blue[300]!, Colors.indigo[400]!],
    [Colors.deepOrange[400]!, Colors.brown[700]!],
    [Colors.blue[400]!, Colors.indigo[700]!],
    [Colors.pink[400]!, Colors.purple[700]!],
    [Colors.cyan[400]!, Colors.blue[800]!],
  ];
  return gradients[i % gradients.length];
}

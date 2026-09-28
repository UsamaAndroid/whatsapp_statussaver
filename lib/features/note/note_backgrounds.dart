import 'package:flutter/material.dart';

/// A note canvas background: either a solid [color] or a [gradient], plus a
/// [textColor] chosen to stay readable on top of it.
class NoteBackground {
  final Color? color;
  final Gradient? gradient;
  final Color textColor;

  const NoteBackground.solid(Color this.color, {this.textColor = Colors.white})
      : gradient = null;

  const NoteBackground.gradient(Gradient this.gradient,
      {this.textColor = Colors.white})
      : color = null;

  BoxDecoration get decoration =>
      BoxDecoration(color: color, gradient: gradient);

  static const List<NoteBackground> all = [
    // RedNote red
    NoteBackground.solid(Color(0xFFFF2442)),
    // Near-black
    NoteBackground.solid(Color(0xFF151515)),
    // Cream
    NoteBackground.solid(Color(0xFFF8F1E3), textColor: Color(0xFF4A3526)),
    // Mint
    NoteBackground.solid(Color(0xFFCDEFD9), textColor: Color(0xFF1B4D32)),
    // Navy
    NoteBackground.solid(Color(0xFF1B2A4E)),
    // Purple
    NoteBackground.solid(Color(0xFF6A3FC8)),
    // Pink
    NoteBackground.gradient(LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF6FA5), Color(0xFFFF2442)],
    )),
    // Dark teal
    NoteBackground.gradient(LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF0F3D3E), Color(0xFF071E22)],
    )),
    // Light beige
    NoteBackground.gradient(
      LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF6E9), Color(0xFFEAD9C2)],
      ),
      textColor: Color(0xFF3B2F25),
    ),
    // Orange → yellow
    NoteBackground.gradient(LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF7A18), Color(0xFFFFC837)],
    )),
  ];
}

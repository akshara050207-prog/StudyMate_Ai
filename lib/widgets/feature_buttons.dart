import 'package:flutter/material.dart';

class FeatureButtons extends StatelessWidget {
  final VoidCallback onNotes;
  final VoidCallback onExplain;
  final VoidCallback onProsCons;
  final VoidCallback onFlashcards;
  final VoidCallback onQuiz;
  final VoidCallback onInterview;
  final VoidCallback onKeyPoints;

  const FeatureButtons({
    super.key,
    required this.onNotes,
    required this.onExplain,
    required this.onProsCons,
    required this.onFlashcards,
    required this.onQuiz,
    required this.onInterview,
    required this.onKeyPoints,
  });

  Widget buildButton(String text, IconData icon, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          buildButton("Notes", Icons.menu_book, onNotes),
          buildButton("Explain", Icons.lightbulb, onExplain),
          buildButton("Pros & Cons", Icons.balance, onProsCons),
          buildButton("Flashcards", Icons.style, onFlashcards),
          buildButton("Quiz", Icons.quiz, onQuiz),
          buildButton("Interview", Icons.work, onInterview),
          buildButton("Key Points", Icons.star, onKeyPoints),
        ],
      ),
    );
  }
}
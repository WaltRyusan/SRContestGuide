import 'package:sr_contest_guide/importer.dart';

class FloatingButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color backgroundColor;

  FloatingButton({required this.onPressed, required this.icon, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: Icon(icon),
      backgroundColor: backgroundColor,
    );
  }
}
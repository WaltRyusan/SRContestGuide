import 'package:sr_contest_guide/importer.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("アプリについて"),
      ),
      body: const Center(
        child: Text("設定画面の内容は保留"),
      ),
    );
  }
}
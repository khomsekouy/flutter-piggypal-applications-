import 'package:flutter_piggypal_app/app/app.dart';
import 'package:flutter_piggypal_app/bootstrap.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}

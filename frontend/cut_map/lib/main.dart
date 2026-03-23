import 'package:cut_map/app.dart';
import 'package:cut_map/locator.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  setupLocator();

  runApp(const App());
}

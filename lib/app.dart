import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'ui/screens/root_scaffold.dart';

class MentalistApp extends StatelessWidget {
  const MentalistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mentalist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const RootScaffold(),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MainScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Future<void> Function()? onRefresh;

  const MainScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.drawer,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget = body;
    
    if (onRefresh != null) {
      bodyWidget = RefreshIndicator(
        onRefresh: onRefresh!,
        child: body,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: drawer,
      body: bodyWidget,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

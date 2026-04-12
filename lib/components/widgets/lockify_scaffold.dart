import 'package:flutter/material.dart';
import 'package:lockify/utils/colors.dart';

class LockifyScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final double appBarElevation;
  final bool centerTitle;
  final Widget? leading;
  final bool showAppBar;

  const LockifyScaffold({
    super.key,
    this.title,
    this.titleWidget,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.appBarElevation = 0,
    this.centerTitle = false,
    this.leading,
    this.showAppBar = true,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: backgroundColor ?? AppColors.backgroundGrey,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: AppColors.white,
              elevation: appBarElevation,
              centerTitle: centerTitle,
              leading: leading ?? (canPop
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null),
              title: titleWidget ?? (title != null
                  ? Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    )
                  : null),
              actions: actions,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

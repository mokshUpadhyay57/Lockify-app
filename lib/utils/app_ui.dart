import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppNavigation {
  AppNavigation._();

  static Future<T?> push<T extends Object?>(Route<T> route) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return Future<T?>.value();
    return navigator.push(route);
  }

  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    Route<T> route, {
    TO? result,
  }) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return Future<T?>.value();
    return navigator.pushReplacement(route, result: result);
  }

  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    Route<T> route,
    RoutePredicate predicate,
  ) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return Future<T?>.value();
    return navigator.pushAndRemoveUntil(route, predicate);
  }
}

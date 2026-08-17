import 'package:flutter/material.dart';

/// Clé de navigation globale, nécessaire pour naviguer depuis des callbacks
/// qui n'ont pas de `BuildContext` — typiquement les listeners FCM
/// (`onMessageOpenedApp`, `getInitialMessage`) qui peuvent se déclencher
/// avant qu'un écran ne soit affiché, ou en dehors de tout arbre de widgets
/// visible.
///
/// À passer à `MaterialApp(navigatorKey: appNavigatorKey)`.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

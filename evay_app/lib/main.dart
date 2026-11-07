import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';
import 'theme/locale_controller.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const EvayApp());
}

class EvayApp extends StatefulWidget {
  const EvayApp({super.key});

  @override
  State<EvayApp> createState() => _EvayAppState();
}

class _EvayAppState extends State<EvayApp> {
  final ThemeController _themeController = ThemeController();
  final LocaleController _localeController = LocaleController();
  late final Listenable _appListenable = Listenable.merge([
    _themeController,
    _localeController,
  ]);

  @override
  void dispose() {
    _localeController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EvayThemeScope(
      controller: _themeController,
      child: EvayLocaleScope(
        controller: _localeController,
        child: AnimatedBuilder(
          animation: _appListenable,
          builder: (context, _) {
            return MaterialApp(
              title: 'EVay Lanka',
              debugShowCheckedModeBanner: false,
              locale: _localeController.value,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              themeMode: _themeController.value,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              home: const AuthGate(),
            );
          },
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

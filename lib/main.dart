import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_csi/auth/login_widget.dart';
import 'package:mi_csi/base/mi_csi_toast.dart';
import 'package:mi_csi/languages/hungarian_language.dart';
import 'package:mi_csi/languages/languages.dart';
import 'package:mi_csi/widgets/main_widget.dart';
import 'package:mi_csi/widgets/stateless/loading_animation.dart';

import 'api/user.dart';
import 'auth/auth_sqflite_handler.dart';
import 'base/session.dart';

void main() {
  runApp(ProviderScope(
    child: Phoenix(
      child: const MyApp(),
    ),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Session session = Session();
  AuthSqfLiteHandler authSqfLiteHandler = AuthSqfLiteHandler();
  Widget mainWidget = const LoadingAnimation();
  Languages languages = LanguageHu();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    authSqfLiteHandler.retrieveUser().then((authUser) {
      if (authUser != null) {
        var body = <String, dynamic>{};
        body['username'] = authUser.email;
        body['password'] = authUser.password;
        session
            .post(
          '/api/login',
          body,
        )
            .then((res) {
          if (res.statusCode == 200) {
            session.updateCookie(res);
            session.get('/api/users/getAuthenticatedUser').then((innerRes) {
              if (innerRes.statusCode == 200) {
                session.updateCookie(innerRes);
                User user =
                    User.fromJson(jsonDecode(utf8.decode(innerRes.bodyBytes)));
                setState(() {
                  mainWidget = MainWidget(
                    session: session,
                    user: user,
                  );
                });
              }
            });
          } else {
            authSqfLiteHandler.deleteUsers();
            MiCsiToast.error(languages.automaticLoginErrorMessage);
            setState(() {
              mainWidget = const LoginPage();
            });
          }
        });
      } else {
        setState(() {
          mainWidget = const LoginPage();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return mainWidget;
  }
}

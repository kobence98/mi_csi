import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mi_csi/auth/registration_widget.dart';
import 'package:mi_csi/languages/hungarian_language.dart';
import 'package:mi_csi/languages/languages.dart';
import 'package:mi_csi/widgets/stateless/loading_animation.dart';

import '../api/user.dart';
import '../base/session.dart';
import '../design/main_background.dart';
import '../widgets/main_widget.dart';
import 'auth_sqflite_handler.dart';
import 'auth_user.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgottenPasswordEmailController = TextEditingController();
  Session session = Session();
  AuthSqfLiteHandler authSqfLiteHandler = AuthSqfLiteHandler();
  bool loading = false;
  Languages languages = LanguageHu();
  late bool _passwordVisible;

  @override
  void initState() {
    super.initState();
    _passwordVisible = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomPaint(
        painter: MainBackground(),
        child: SafeArea(
          child: loading
              ? const LoadingAnimation()
              : Center(
                  child: Container(
                    padding: EdgeInsets.all(
                        MediaQuery.of(context).size.height * 0.02),
                    width: 600,
                    height: 1000,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.only(left: 20.0),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                              color: Colors.white.withOpacity(0.7),
                            ),
                            child: TextField(
                              style: const TextStyle(color: Colors.black),
                              controller: _emailController,
                              cursorColor: Colors.black,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide.none),
                                hintText: languages.emailLabel,
                                hintStyle: TextStyle(
                                    color: Colors.black.withOpacity(0.5)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.only(left: 20.0),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                              color: Colors.white.withOpacity(0.7),
                            ),
                            child: TextField(
                              enableSuggestions: false,
                              autocorrect: false,
                              obscureText: !_passwordVisible,
                              style: const TextStyle(color: Colors.black),
                              controller: _passwordController,
                              cursorColor: Colors.black,
                              decoration: InputDecoration(
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    // Based on passwordVisible state choose the icon
                                    _passwordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    // Update the state i.e. toogle the state of passwordVisible variable
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                ),
                                focusedBorder: const OutlineInputBorder(
                                    borderSide: BorderSide.none),
                                hintText: languages.passwordLabel,
                                hintStyle: TextStyle(
                                    color: Colors.black.withOpacity(0.5)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: ButtonTheme(
                            height: 50,
                            minWidth: 300,
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.white),
                              ),
                              onPressed: onLoginPressed,
                              child: Text(
                                languages.loginLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: ButtonTheme(
                            height: 50,
                            minWidth: 300,
                            child: ElevatedButton(
                              onPressed: onRegistrationPressed,
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.white),
                              ),
                              child: Text(
                                languages.registrationLabel,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Center(
                          child: InkWell(
                            onTap: _onForgottenPasswordTap,
                            child: Text(
                              languages.forgottenPasswordLabel,
                              style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 15,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  //GOMBOK KATTINTÁSAI
  void onLoginPressed() {
    setState(() {
      loading = true;
    });
    var body = <String, dynamic>{};
    body['username'] = _emailController.text.split(' ').first;
    body['password'] = _passwordController.text;
    session
        .postLogin(
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
            if (user.active) {
              setState(() {
                loading = false;
              });
              authSqfLiteHandler.insertUser(AuthUser(
                  id: 0,
                  email: _emailController.text.split(' ').first,
                  password: _passwordController.text));
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        MainWidget(session: session, user: user)),
              );
            } else {
              setState(() {
                loading = false;
              });
              showDialog(
                  context: context,
                  useRootNavigator: false,
                  builder: (context) {
                    return StatefulBuilder(builder: (context, setInnerState) {
                      return loading
                          ? const LoadingAnimation()
                          : AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: Text(
                                languages.confirmationWarningMessage,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white),
                              ),
                              content: SizedBox(
                                height: 100,
                                child: Center(
                                  child: Text(
                                    languages.spamFolderTipMessage,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: Text(
                                    languages.cancelLabel,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    _onVerificationEmailResent(setInnerState);
                                  },
                                  child: Text(
                                    languages.requestNewVerificationEmailLabel,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                )
                              ],
                            );
                    });
                  });
            }
          }
        });
      } else if (res.statusCode == 401) {
        setState(() {
          loading = false;
        });
        Fluttertoast.showToast(
            msg: languages.wrongCredentialsErrorMessage,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 4,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        setState(() {
          loading = false;
        });
        Fluttertoast.showToast(
            msg: res.toString(),
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 4,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    });
  }

  void onRegistrationPressed() {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return RegistrationWidget(
        languages: languages,
      );
    }));
  }

  void _onForgottenPasswordTap() {
    showDialog(
        context: context,
        useRootNavigator: false,
        builder: (context) {
          return StatefulBuilder(builder: (context, setInnerState) {
            return loading
                ? const Center(
                    child: Image(
                        image: AssetImage("assets/images/loading_breath.gif")),
                  )
                : AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: Text(
                      languages.forgottenPasswordHintLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white),
                    ),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      Center(
                        child: Container(
                          padding: const EdgeInsets.only(left: 20.0),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                            color: Colors.white.withOpacity(0.7),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.black),
                            controller: _forgottenPasswordEmailController,
                            cursorColor: Colors.black,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide.none),
                              hintText: languages.emailLabel,
                              hintStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.5)),
                            ),
                          ),
                        ),
                      )
                    ]),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          languages.cancelLabel,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _onForgottenPasswordSendTap(setInnerState);
                        },
                        child: Text(
                          languages.sendLabel,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  );
          });
        });
  }

  void _onForgottenPasswordSendTap(setInnerState) {
    setInnerState(() {
      loading = true;
    });
    session.post(
        '/api/users/forgotPassword/${_forgottenPasswordEmailController.text}/${languages.countryCode}',
        <String, dynamic>{}).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          loading = false;
        });
        Navigator.of(context).pop();
        _forgottenPasswordEmailController.clear();
        Fluttertoast.showToast(
            msg: languages.forgottenPasswordSentMessage,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 4,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        setInnerState(() {
          loading = false;
        });
        Fluttertoast.showToast(
            msg: languages.forgottenPasswordErrorMessage,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 4,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    });
  }

  void _onVerificationEmailResent(StateSetter setInnerState) {
    setInnerState(() {
      loading = true;
    });
    session.postDomainJson(
        '/api/users/resendVerification/${_emailController.text.split(' ').first}',
        <String, String?>{}).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          loading = false;
        });
        Navigator.of(context).pop();
        _forgottenPasswordEmailController.clear();
        Fluttertoast.showToast(
            msg: languages.verificationEmailResentMessage,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 4,
            backgroundColor: Colors.green,
            textColor: Colors.white,
            fontSize: 16.0);
      } else {
        setInnerState(() {
          loading = false;
        });
        Fluttertoast.showToast(
            msg: languages.globalErrorMessage,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 4,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    });
  }
}

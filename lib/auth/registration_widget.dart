import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_csi/languages/languages.dart';
import 'package:mi_csi/widgets/stateless/loading_animation.dart';
import '../base/profanity_checker.dart';
import '../base/session.dart';
import 'auth_sqflite_handler.dart';

class RegistrationWidget extends StatefulWidget {
  final Languages languages;

  const RegistrationWidget({super.key, required this.languages});

  @override
  _RegistrationWidgetState createState() => _RegistrationWidgetState();
}

class _RegistrationWidgetState extends State<RegistrationWidget> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _regPassAgainController = TextEditingController();
  final _regNameController = TextEditingController();
  final _regCompanyNameController = TextEditingController();
  final _regCompanyDescriptionController = TextEditingController();
  Session session = Session();
  AuthSqfLiteHandler authSqfLiteHandler = AuthSqfLiteHandler();
  XFile? image;
  bool loading = false;
  List<String> countryCodes = [];
  String? _chosenCountryCode;
  bool isPolicyAccepted = false;
  late bool _regPasswordVisible;
  late bool _regPassAgainVisible;
  late Languages languages;

  @override
  void initState() {
    super.initState();
    _regPasswordVisible = false;
    _regPassAgainVisible = false;
    languages = widget.languages;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: loading
            ? const LoadingAnimation()
            : Container(
                padding: const EdgeInsets.all(10),
                color: Colors.black,
                child: ListView(
                  children: [
                    Center(
                      child: Text(
                        languages.registrationLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 25),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: Colors.black,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
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
                                  style: const TextStyle(color: Colors.black),
                                  controller: _regEmailController,
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
                                  style: const TextStyle(color: Colors.black),
                                  controller: _regPasswordController,
                                  cursorColor: Colors.black,
                                  obscureText: !_regPasswordVisible,
                                  decoration: InputDecoration(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        // Based on passwordVisible state choose the icon
                                        _regPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        // Update the state i.e. toogle the state of passwordVisible variable
                                        setState(() {
                                          _regPasswordVisible = !_regPasswordVisible;
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
                                  style: const TextStyle(color: Colors.black),
                                  controller: _regPassAgainController,
                                  cursorColor: Colors.black,
                                  obscureText: !_regPassAgainVisible,
                                  decoration: InputDecoration(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        // Based on passwordVisible state choose the icon
                                        _regPassAgainVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                        color: Colors.black,
                                      ),
                                      onPressed: () {
                                        // Update the state i.e. toogle the state of passwordVisible variable
                                        setState(() {
                                          _regPassAgainVisible = !_regPassAgainVisible;
                                        });
                                      },
                                    ),
                                    focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide.none),
                                    hintText: languages.passAgainLabel,
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
                                  style: const TextStyle(color: Colors.black),
                                  maxLength: 30,
                                  controller: _regNameController,
                                  cursorColor: Colors.black,
                                  decoration: InputDecoration(
                                    focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide.none),
                                    counterText: '',
                                    hintText: languages.nameLabel + languages.maxThirtyLengthLabel,
                                    hintStyle: TextStyle(
                                        color: Colors.black.withOpacity(0.5)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Container(
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(1),
                              child: Container(
                                decoration: const BoxDecoration(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                  color: Colors.black,
                                ),
                                child: ListTile(
                                  leading: Switch(
                                    value: isPolicyAccepted,
                                    onChanged: (value) {
                                      setState(() {
                                        isPolicyAccepted = value;
                                      });
                                    },
                                    activeTrackColor: Colors.grey,
                                    activeColor: Colors.grey.shade600,
                                    inactiveTrackColor: Colors.white,
                                  ),
                                  title: Container(
                                    child: Center(
                                      child: RichText(
                                        text: TextSpan(
                                          children: <TextSpan>[
                                            TextSpan(
                                                text:
                                                    languages.acceptPolicyLabel,
                                                style: const TextStyle(
                                                    color: Colors.white)),
                                            TextSpan(
                                                text: languages.userPolicyLabel,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white),
                                                recognizer:
                                                    TapGestureRecognizer()
                                                      ..onTap = () =>
                                                          _onPrivacyPolicyTap()),
                                            const TextSpan(
                                                text: '!',
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            languages.closeLabel,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            onRegistrationActivatePressed(setState);
                          },
                          child: Text(
                            languages.registrationLabel,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
      ),
    );
  }

  void onRegistrationActivatePressed(setInnerState) {
    if (ProfanityChecker.alert('${_regNameController.text} ${_regCompanyDescriptionController.text} ${_regCompanyNameController.text}')) {
      Fluttertoast.showToast(
          msg: languages.profanityWarningMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 4,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    else if (!isPolicyAccepted) {
      Fluttertoast.showToast(
          msg: languages.acceptPolicyWarningMessage,
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 4,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    else {
      if (_regPasswordController.text == _regPassAgainController.text) {
        if (_regEmailController.text.split(' ').first.isNotEmpty &&
            _regPasswordController.text.isNotEmpty) {
          dynamic body = <String, String?>{
            'email': _regEmailController.text.split(' ').first,
            'password': _regPasswordController.text,
            'name': _regNameController.text,
          };
          setState(() {
            loading = true;
          });
          session
              .postDomainJson(
            '/api/users',
            body,
          )
              .then((response) {
            if (response.statusCode == 200) {
                setState(() {
                  loading = false;
                });
                _emailController.clear();
                _passwordController.clear();
                _regEmailController.clear();
                _regPasswordController.clear();
                _regPassAgainController.clear();
                _regNameController.clear();
                _regCompanyNameController.clear();
                _regCompanyDescriptionController.clear();
                Navigator.of(context).pop();
                Fluttertoast.showToast(
                    msg: languages.successfulRegistrationMessage,
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 4,
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                    fontSize: 16.0);
            } else if (response.statusCode == 400) {
              setInnerState(() {
                loading = false;
              });
              Fluttertoast.showToast(
                  msg: languages.wrongEmailFormatWarningMessage,
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 4,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
            } else if (response.statusCode == 500) {
              setInnerState(() {
                loading = false;
              });
              if (response.body != null &&
                  json.decode(response.body)['message'] != null &&
                  json.decode(response.body)['message'] ==
                      'Email is already in use!') {
                Fluttertoast.showToast(
                    msg: languages.emailIsAlreadyInUseWarningMessage,
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 4,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0);
              } else {
                Fluttertoast.showToast(
                    msg: languages.globalErrorMessage,
                    toastLength: Toast.LENGTH_LONG,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 4,
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                    fontSize: 16.0);
              }
            } else {
              setInnerState(() {
                loading = false;
              });
              Fluttertoast.showToast(
                  msg: response.toString(),
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 4,
                  backgroundColor: Colors.red,
                  textColor: Colors.white,
                  fontSize: 16.0);
            }
          });
        } else {
          Fluttertoast.showToast(
              msg: languages.fillAllFieldsProperlyWarningMessage,
              toastLength: Toast.LENGTH_LONG,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 4,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              fontSize: 16.0);
        }
      } else {
        setInnerState(() {
          loading = false;
        });
        Fluttertoast.showToast(
            msg: languages.passwordsAreNotIdenticalWarningMessage,
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 4,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0);
      }
    }
  }

  void _onPrivacyPolicyTap() {
    showDialog(
        context: context,
        useRootNavigator: false,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(
              languages.userPolicyTitle,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: Text(languages.userPolicyText),
                    ),
                  ),
                )
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  languages.backLabel,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _regPassAgainController.dispose();
    _regNameController.dispose();
    _regCompanyNameController.dispose();
    _regCompanyDescriptionController.dispose();
    super.dispose();
  }
}

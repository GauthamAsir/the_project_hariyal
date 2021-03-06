import 'dart:async';
import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geocoder/geocoder.dart';
import 'package:location/location.dart';
import 'package:the_project_hariyal/screens/customer/home.dart';
import 'package:the_project_hariyal/screens/customer/models/user_model.dart';
import 'package:the_project_hariyal/utils.dart';

class Signup extends StatefulWidget {
  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  String _pinCode, _state, _cityDistrict;
  double _latitude, _longitude;
  var currentLocation;

  Location location = new Location();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = new TextEditingController();

  bool _nameValidated = false,
      _emailValidated = false,
      _phoneValidated = false,
      _isOpen = false;
  StreamSubscription<QuerySnapshot> phoneStream;
  StreamSubscription<QuerySnapshot> emailStream;

  void fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
  }

  void signUp() {
    if (!_nameValidated) {
      Utils().toast(context, 'Enter a valid name',
          bgColor: Colors.red, textColor: Colors.white);
      return;
    }

    if (!_emailValidated) {
      Utils().toast(context, 'Enter a valid e-mail',
          bgColor: Colors.red, textColor: Colors.white);
      return;
    }

    if (!_emailValidated) {
      Utils().toast(context, 'Enter a valid password',
          bgColor: Colors.red, textColor: Colors.white);
      return;
    }

    _showDialog(text: 'Please wait');

    phoneStream = Firestore.instance
        .collection('customers')
        .where('phoneNumber', isEqualTo: _phoneController.text)
        .snapshots()
        .listen((data) {
      if (data.documentChanges.length <= 0) {
        emailStream = Firestore.instance
            .collection('customers')
            .where('email', isEqualTo: _emailController.text)
            .snapshots()
            .listen((data) {
          if (data.documents.length <= 0) {
            _hideDialog();
            _showDialog(text: 'Requesting Otp');

            FirebaseAuth _auth = FirebaseAuth.instance;

            _auth.verifyPhoneNumber(
                phoneNumber: '+91' + _phoneController.text,
                timeout: Duration(seconds: 60),
                verificationCompleted: (AuthCredential credential) async {
                  Navigator.of(context).pop();

                  AuthResult result =
                      await _auth.signInWithCredential(credential);

                  FirebaseUser user = result.user;

                  if (user != null) {
                    uploadUserInfo(user.uid);
                  } else {
                    Utils().toast(context, 'Failed to SignUp',
                        bgColor: Utils().randomGenerator());
                    print("Error: Failed to SignUp");
                  }
                },
                verificationFailed: (AuthException exception) {
                  _hideDialog();
                  Utils().toast(context, exception.message,
                      bgColor: Colors.red[800], textColor: Colors.white);
                  print(exception);
                },
                codeSent: (String verificationId, [int forceResendingToken]) {
                  _hideDialog();
                  showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Enter the code"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              TextField(
                                controller: _codeController,
                                maxLength: 6,
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  WhitelistingTextInputFormatter.digitsOnly
                                ],
                              ),
                            ],
                          ),
                          actions: <Widget>[
                            FlatButton(
                              child: Text("Confirm"),
                              textColor: Colors.white,
                              color: Colors.blue,
                              onPressed: () async {
                                if (_codeController.text.length != 6) {
                                  Utils().toast(context, 'Enter valid code');
                                  return;
                                }
                                _showDialog(text: "Verifying Otp");
                                final code = _codeController.text.trim();
                                AuthCredential credential =
                                    PhoneAuthProvider.getCredential(
                                        verificationId: verificationId,
                                        smsCode: code);

                                AuthResult result = await _auth
                                    .signInWithCredential(credential);

                                FirebaseUser user = result.user;

                                if (user != null) {
                                  Navigator.pop(context);
                                  uploadUserInfo(user.uid);
                                } else {
                                  _hideDialog();
                                  print("Error: Failed to SignUp");
                                  Utils().toast(context, 'Failed to SignUp',
                                      bgColor: Utils().randomGenerator());
                                }
                              },
                            )
                          ],
                        );
                      });
                },
                codeAutoRetrievalTimeout: null);
          } else {
            _hideDialog();
            Utils().toast(context, 'E-mail exists',
                bgColor: Utils().randomGenerator());
          }
        });
      } else {
        _hideDialog();
        Utils().toast(context, 'Phone number exists',
            bgColor: Utils().randomGenerator());
      }
    });
  }

  Future uploadUserInfo(String uid) async {
    _hideDialog();
    _showDialog(text: 'Registering User');

    phoneStream.cancel();
    emailStream.cancel();

    Map<String, dynamic> _loc = new HashMap();
    _loc['lat'] = _latitude;
    _loc['long'] = _longitude;
    _loc['pinCode'] = _pinCode;
    _loc['state'] = _state;
    _loc['cityDistrict'] = _cityDistrict;

    final _fireStore = Firestore.instance;

    UserModel userModel = new UserModel(
      name: _nameController.text,
      email: _emailController.text,
      phoneNumber: _phoneController.text,
      location: _loc,
    );

    await _fireStore
        .collection('customers')
        .document(uid)
        .setData(userModel.toMap());

    _hideDialog();
    Utils().toast(context, 'User created', bgColor: Utils().randomGenerator());
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => Home(uid, userModel)));
  }

  void checkLocationEnabled() async {
    bool serviceStatus = await location.serviceEnabled();

    if (!serviceStatus) {
      Utils().toast(context, 'Enable Location to SignUp',
          bgColor: Utils().randomGenerator());
      Navigator.pop(context);
      return;
    }

    getUserLocation();
  }

  @override
  void initState() {
    checkLocationEnabled();

    _nameController.addListener(() {
      if (_nameController.text.length <= 0) {
        setState(() {
          _nameValidated = false;
        });
      } else {
        setState(() {
          _nameValidated = true;
        });
      }
    });

    _emailController.addListener(() {
      if (_emailController.text.length <= 0) {
        setState(() {
          _emailValidated = false;
        });
      } else if (!EmailValidator.validate(_emailController.text.trim())) {
        setState(() {
          _emailValidated = false;
        });
      } else {
        setState(() {
          _emailValidated = true;
        });
      }
    });

    _phoneController.addListener(() {
      if (_phoneController.text.length != 10) {
        setState(() {
          _phoneValidated = false;
        });
      } else {
        setState(() {
          _phoneValidated = true;
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<bool> _showDialog({String text}) async {
    setState(() {
      _isOpen = true;
    });

    return (await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () {},
        child: AlertDialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          title: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24),
                color: Colors.black12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 10,
                    ),
                    Text(
                      text != null && text.isNotEmpty ? text : 'Loading',
                      textScaleFactor: 1.2,
                      style: TextStyle(color: Colors.white),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    ));
  }

  void _hideDialog() {
    if (_isOpen) {
      Navigator.of(context).pop(true);
      setState(() {
        _isOpen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: <Widget>[
                    Positioned(
                      left: 20.0,
                      top: 15.0,
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(20.0)),
                        width: 70.0,
                        height: 20.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 32.0),
                      child: Text(
                        "Sign Up",
                        style: TextStyle(
                            fontSize: 30.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30.0),
                Card(
                  margin: EdgeInsets.only(left: 30, right: 30, top: 30),
                  elevation: 6,
                  shadowColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40))),
                  child: TextFormField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    onFieldSubmitted: (_) {
                      fieldFocusChange(
                          context, _nameFocusNode, _emailFocusNode);
                    },
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person_outline),
                        suffixIcon: Icon(
                          _nameValidated ? Icons.check_circle : null,
                          color: Colors.green[800],
                        ),
                        hintText: "Name",
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(40.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 16.0)),
                  ),
                ),
                Card(
                  margin: EdgeInsets.only(left: 30, right: 30, top: 30),
                  elevation: 6,
                  shadowColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40))),
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    onFieldSubmitted: (_) {
                      fieldFocusChange(
                          context, _emailFocusNode, _phoneFocusNode);
                    },
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.alternate_email),
                        suffixIcon: Icon(
                          _emailValidated ? Icons.check_circle : null,
                          color: Colors.green[800],
                        ),
                        hintText: "E-mail",
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(40.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 16.0)),
                  ),
                ),
                Card(
                  margin: EdgeInsets.only(left: 30, right: 30, top: 30),
                  elevation: 6,
                  shadowColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(40))),
                  child: TextFormField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    onFieldSubmitted: (_) {
                      signUp();
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      WhitelistingTextInputFormatter.digitsOnly
                    ],
                    decoration: InputDecoration(
                        prefixIcon: Icon(Icons.phone),
                        suffixIcon: Icon(
                          _phoneValidated ? Icons.check_circle : null,
                          color: Colors.green[800],
                        ),
                        hintText: "Phone Number",
                        hintStyle: TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(40.0)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 16.0)),
                  ),
                ),
                const SizedBox(height: 80.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: RaisedButton(
                    padding: const EdgeInsets.fromLTRB(40.0, 16.0, 30.0, 16.0),
                    color: Colors.yellow,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30.0),
                            bottomLeft: Radius.circular(30.0))),
                    onPressed: signUp,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          "Request Otp",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 17.0),
                        ),
                        const SizedBox(width: 40.0),
                        Icon(
                          FontAwesomeIcons.arrowRight,
                          size: 18.0,
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("Already have an account?"),
                    FlatButton(
                      child: Text(
                        "Log In",
                        style: TextStyle(fontSize: 16),
                      ),
                      textColor: Colors.indigo,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  getUserLocation() async {
    LocationData myLocation;
    String error;
    try {
      myLocation = await location.getLocation();
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        error = 'please grant permission';
        print(error);
        Navigator.pop(context);
        return;
      }
      if (e.code == 'PERMISSION_DENIED_NEVER_ASK') {
        error = 'permission denied- please enable it from app settings';
        print(error);
        Navigator.pop(context);
        return;
      }
      Utils().toast(context, e.code,
          bgColor: Colors.red[800], textColor: Colors.white);
      myLocation = null;
      Navigator.pop(context);
    }

    currentLocation = myLocation;
    final coordinates =
        new Coordinates(myLocation.latitude, myLocation.longitude);
    var addresses =
        await Geocoder.local.findAddressesFromCoordinates(coordinates);
    var first = addresses.first;
    setState(() {
      _latitude = myLocation.latitude;
      _longitude = myLocation.longitude;
      _pinCode = first.postalCode;
      _state = first.adminArea;
      _cityDistrict =
          first.locality == null ? first.subAdminArea : first.locality;
    });
  }
}

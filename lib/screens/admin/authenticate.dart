import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:the_project_hariyal/services/auth_services.dart';

import 'admin_home.dart';

class AdminAuthenticate extends StatefulWidget {
  @override
  _AdminAuthenticateState createState() => _AdminAuthenticateState();
}

class _AdminAuthenticateState extends State<AdminAuthenticate> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
        color: Colors.grey.shade700, fontSize: 30, fontWeight: FontWeight.bold);
    final contentStyle = TextStyle(
        color: Colors.grey, fontSize: 18, fontWeight: FontWeight.normal);
    return SafeArea(
      child: Scaffold(
        body: loading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 70),
                    child: Center(child: Text('//TODO Logo')),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 9, horizontal: 27),
                    child: Text(
                      'Login',
                      style: titleStyle,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 9, horizontal: 27),
                    child: Text(
                      'Hi Admin !',
                      style: contentStyle,
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 27, vertical: 9),
                    child: TextField(
                      controller: emailController,
                      maxLines: 1,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'email',
                        isDense: true,
                        labelStyle: TextStyle(
                          color: Colors.red.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                        contentPadding: EdgeInsets.all(18),
                        border: InputBorder.none,
                        fillColor: Colors.grey.shade200,
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        prefix: Icon(
                          MdiIcons.emailOutline,
                          color: Colors.red.shade300,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 27, vertical: 9),
                    child: TextField(
                      controller: passwordController,
                      maxLines: 1,
                      keyboardType: TextInputType.visiblePassword,
                      decoration: InputDecoration(
                        labelText: 'password',
                        isDense: true,
                        labelStyle: TextStyle(
                          color: Colors.red.shade300,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 1.0,
                        ),
                        contentPadding: EdgeInsets.all(18),
                        border: InputBorder.none,
                        fillColor: Colors.grey.shade200,
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        prefix: Icon(
                          MdiIcons.lockOutline,
                          color: Colors.red.shade300,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: RaisedButton(
                      padding: EdgeInsets.symmetric(horizontal: 30),
                      elevation: 0,
                      onPressed: () {
                        login();
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                      color: Colors.red.shade300,
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: FlatButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Customer ?',
                        style: TextStyle(color: Colors.red.shade300),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  login() async {
    handleState();
    if (await AuthServices()
            .adminLogin(emailController.text, passwordController.text) ==
        true) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
        return AdminHome();
      }));
    } else {
      handleState();
    }
  }

  handleState() {
    setState(() {
      loading = !loading;
    });
  }
}

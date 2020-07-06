import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ExtraIdentifier extends StatefulWidget {
  final identifier;

  const ExtraIdentifier({Key key, this.identifier}) : super(key: key);

  @override
  _ExtraIdentifierState createState() => _ExtraIdentifierState();
}

class _ExtraIdentifierState extends State<ExtraIdentifier> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: Firestore.instance
          .collection('extras')
          .document('${widget.identifier}')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Tweak Categories'),
              centerTitle: true,
              actions: <Widget>[
                Center(
                  child: IconButton(
                    icon: Icon(MdiIcons.plusOutline),
                    onPressed: () {
                      if (snapshot.data.data == null) {
                        addCategoryDialouge([]);
                      } else {
                        addCategoryDialouge(
                            snapshot.data.data['${widget.identifier}_array']);
                      }
                    },
                  ),
                )
              ],
            ),
            body: ListView.builder(
              itemCount: snapshot.data.data == null
                  ? 0
                  : snapshot.data.data['${widget.identifier}_array'].length,
              itemBuilder: (BuildContext context, int index) {
                return Container(
                  margin: EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    color: Colors.grey.shade100,
                  ),
                  child: Dismissible(
                    background: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: Colors.red,
                      ),
                      child: ListTile(
                        leading: Icon(
                          MdiIcons.deleteOutline,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    secondaryBackground: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(9),
                        color: Colors.blue,
                      ),
                      child: ListTile(
                        trailing: Icon(
                          MdiIcons.pencilOutline,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.endToStart) {
                        final textController = TextEditingController();
                        textController.text = snapshot
                            .data.data['${widget.identifier}_array'][index];
                        return await showDialog(
                          context: context,
                          barrierDismissible: false,
                          child: SimpleDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9),
                            ),
                            children: <Widget>[
                              Column(
                                children: <Widget>[
                                  Container(
                                    margin: EdgeInsets.all(9),
                                    alignment: Alignment.center,
                                    child: Text('Edit Category'),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 27, vertical: 9),
                                    child: TextField(
                                      controller: textController,
                                      maxLines: 1,
                                      keyboardType: TextInputType.text,
                                      decoration: InputDecoration(
                                        labelText: 'Full name',
                                        isDense: true,
                                        labelStyle: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1.0,
                                        ),
                                        contentPadding: EdgeInsets.all(12),
                                        border: InputBorder.none,
                                        fillColor: Colors.grey.shade200,
                                        filled: true,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                        disabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          borderSide: BorderSide(
                                              color: Colors.grey.shade300),
                                        ),
                                        prefix: Icon(
                                          MdiIcons.accountOutline,
                                          color: Colors.red.shade300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  FlatButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                  ),
                                  FlatButton(
                                    child: Text('update'),
                                    onPressed: () {
                                      if (textController.text.length > 0) {
                                        Firestore.instance
                                            .collection('extras')
                                            .document('${widget.identifier}')
                                            .updateData(
                                          {
                                            '${widget.identifier}_array':
                                                FieldValue.arrayRemove(
                                              [
                                                snapshot.data.data[
                                                        '${widget.identifier}_array']
                                                    [index],
                                              ],
                                            )
                                          },
                                        );
                                        Firestore.instance
                                            .collection('extras')
                                            .document('${widget.identifier}')
                                            .setData(
                                          {
                                            '${widget.identifier}_array':
                                                FieldValue.arrayUnion(
                                              [
                                                textController.text
                                                    .toLowerCase()
                                              ],
                                            )
                                          },
                                          merge: true,
                                        );

                                        Navigator.of(context).pop(false);
                                      } else {
                                        Navigator.of(context).pop(false);
                                        Fluttertoast.showToast(
                                            msg:
                                                'Invalid Arguments or field is alreay present');
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      } else {
                        return await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              elevation: 9,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              title: Text("Confirm"),
                              content: Text(
                                  "Are you sure you wish to delete this ${widget.identifier}?"),
                              actions: <Widget>[
                                FlatButton(
                                  onPressed: () async {
                                    Firestore.instance
                                        .collection('extras')
                                        .document('${widget.identifier}')
                                        .updateData(
                                      {
                                        '${widget.identifier}_array':
                                            FieldValue.arrayRemove(
                                          [
                                            snapshot.data.data[
                                                    '${widget.identifier}_array']
                                                [index]
                                          ],
                                        ),
                                      },
                                    );
                                    Navigator.of(context).pop(true);
                                  },
                                  child: Text("DELETE"),
                                ),
                                FlatButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text("CANCEL"),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    key: UniqueKey(),
                    child: ListTile(
                      title: Center(
                        child: Text(snapshot
                            .data.data['${widget.identifier}_array'][index]),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  addCategoryDialouge(List list) async {
    final name = TextEditingController();
    return showDialog(
      context: context,
      child: SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
        ),
        title: Center(child: Text('Add ${widget.identifier}')),
        children: <Widget>[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 27, vertical: 9),
            child: TextField(
              controller: name,
              maxLines: 1,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: '${widget.identifier} name',
                isDense: true,
                labelStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
                contentPadding: EdgeInsets.all(12),
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
              ),
            ),
          ),
          Center(
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(9),
              ),
              elevation: 0,
              color: Colors.red.shade300,
              child: Text('Confirm'),
              onPressed: () {
                if (name.text.length > 0 &&
                    !list.contains(name.text.toLowerCase())) {
                  Firestore.instance
                      .collection('extras')
                      .document('${widget.identifier}')
                      .setData({
                    '${widget.identifier}_array':
                        FieldValue.arrayUnion([name.text.toLowerCase()])
                  }, merge: true);
                  Navigator.pop(context);
                } else {
                  Fluttertoast.showToast(
                      msg: 'Invalid Arguments or field is alreay present');
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
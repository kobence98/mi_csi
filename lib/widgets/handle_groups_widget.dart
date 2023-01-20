import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mi_csi/base/mi_csi_toast.dart';
import 'package:mi_csi/widgets/stateless/loading_animation.dart';

import '../api/own_group.dart';
import '../api/user.dart';
import '../base/session.dart';

class HandleGroupsWidget extends StatefulWidget {
  final Session session;
  final User user;

  const HandleGroupsWidget(
      {Key? key, required this.session, required this.user})
      : super(key: key);

  @override
  State<HandleGroupsWidget> createState() => _HandleGroupsWidgetState();
}

class _HandleGroupsWidgetState extends State<HandleGroupsWidget> {
  late Session session;
  bool loading = true;
  bool innerLoading = true;
  TextEditingController groupNameController = TextEditingController();
  List<OwnGroup> ownGroups = [];
  List<OwnGroup> allGroupList = [];
  TextEditingController _invitationCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    session = widget.session;
    session.get('/api/groups/own').then((response) {
      if (response.statusCode == 200) {
        session.updateCookie(response);
        Iterable l = json.decode(utf8.decode(response.bodyBytes));
        ownGroups =
            List<OwnGroup>.from(l.map((model) => OwnGroup.fromJson(model)));
        setState(() {
          loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
          ),
          backgroundColor: Colors.black,
          body: loading
              ? const LoadingAnimation()
              : Container(
                  color: Colors.black,
                  child: ListView.builder(
                    itemCount: ownGroups.length + 2,
                    itemBuilder: (context, i) {
                      if (i == ownGroups.length) {
                        return InkWell(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            height: 50,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white),
                            child: const Center(
                              child: Icon(Icons.login),
                            ),
                          ),
                          onTap: () {
                            _onJoinNewGroup();
                          },
                        );
                      } else if (i == ownGroups.length + 1) {
                        return InkWell(
                          child: Container(
                            height: 50,
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white),
                            child: const Center(
                              child: Icon(Icons.add),
                            ),
                          ),
                          onTap: () {
                            _onCreateNewGroup();
                          },
                        );
                      } else {
                        return InkWell(
                          onTap: () {
                            _onSetActualGroup(i);
                          },
                          child: Container(
                            height: 50,
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: ownGroups.elementAt(i).actual
                                    ? Colors.green
                                    : Colors.white),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width - 100,
                                  child: Center(
                                    child: Text(
                                      ownGroups.elementAt(i).name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20),
                                    ),
                                  ),
                                ),
                                ownGroups.elementAt(i).isCreator
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            child: const Icon(Icons.copy),
                                            onTap: () {
                                              _onCopyGroupCode(
                                                  ownGroups.elementAt(i));
                                            },
                                          ),
                                          const SizedBox(
                                            width: 15,
                                          ),
                                          InkWell(
                                            child: const Icon(Icons.logout),
                                            onTap: () {
                                              _onLeaveGroup(
                                                  ownGroups.elementAt(i));
                                            },
                                          ),
                                        ],
                                      )
                                    : InkWell(
                                        child: const Icon(Icons.logout),
                                        onTap: () {
                                          _onLeaveGroup(ownGroups.elementAt(i));
                                        },
                                      ),
                              ],
                            ),
                          ),
                        );
                      }
                    },
                  ),
                )),
    );
  }

  void _onJoinNewGroup() {
    innerLoading = true;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            if (innerLoading) {
              _getGroups(setInnerState);
            }
            return AlertDialog(
              title: const Text(
                  "Válaszd ki a csoportot amelyikbe be akarsz lépni!"),
              content:
                  innerLoading ? const LoadingAnimation() : _showGroupList(),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Mégse",
                      style: TextStyle(color: Colors.black)),
                ),
                TextButton(
                  onPressed: () {
                    _onJoinWithCode(setInnerState);
                  },
                  child: const Text("Hozzáadás kóddal",
                      style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onLeaveGroup(OwnGroup selectedGroup) {
    var body = <String, dynamic>{};
    body['groupId'] = selectedGroup.id;
    session.postJson('/api/groups/leave', body).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          ownGroups.remove(selectedGroup);
          if (ownGroups.isEmpty) {
            widget.user.hasNoGroups = true;
          }
        });
        MiCsiToast.info('Sikeres kilépés!');
      } else {
        MiCsiToast.error('Valami hiba történt!');
      }
    });
  }

  void _onCreateNewGroup() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Csoport létrehozása"),
          content: _addGroupTextField(),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Mégse", style: TextStyle(color: Colors.black)),
            ),
            TextButton(
              onPressed: () {
                _onCreateNewGroupPressed();
              },
              child: const Text("Létrehozás",
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  void _getGroups(setInnerState) {
    session.get('/api/groups').then((response) {
      if (response.statusCode == 200) {
        session.updateCookie(response);
        Iterable l = json.decode(utf8.decode(response.bodyBytes));
        allGroupList =
            List<OwnGroup>.from(l.map((model) => OwnGroup.fromJson(model)));
      } else {
        MiCsiToast.error('Valami hiba történt!');
      }
      setInnerState(() {
        innerLoading = false;
      });
    });
  }

  Widget _showGroupList() {
    return Container(
      height: 200,
      width: 500,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: Colors.black),
      child: ListView.builder(
        itemCount: allGroupList.length,
        itemBuilder: (context, i) {
          return Container(
            margin: const EdgeInsets.all(5),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10), color: Colors.white),
            child: InkWell(
              child: Center(
                child: Text(allGroupList.elementAt(i).name),
              ),
              onTap: () {
                _onJoinSelectedNewGroup(allGroupList.elementAt(i));
              },
            ),
          );
        },
      ),
    );
  }

  void _onJoinSelectedNewGroup(OwnGroup selectedGroup) {
    var body = <String, dynamic>{};
    body['groupId'] = selectedGroup.id;
    session.postJson('/api/groups/join', body).then((response) {
      Navigator.of(context).pop();
      setState(() {
        if (response.statusCode == 200) {
          ownGroups.add(selectedGroup);
          widget.user.hasNoGroups = false;
          MiCsiToast.info('Sikeres belépés!');
        } else {
          MiCsiToast.error('Valami hiba történt!');
        }
      });
    });
  }

  Widget _addGroupTextField() {
    return TextField(
      style: const TextStyle(color: Colors.black),
      controller: groupNameController,
      cursorColor: Colors.black,
      decoration: InputDecoration(
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide.none),
        hintText: 'Csoport neve',
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
      ),
    );
  }

  void _onCreateNewGroupPressed() {
    var body = <String, dynamic>{};
    body['name'] = groupNameController.text;
    session.postJson('/api/groups', body).then((response) {
      Navigator.of(context).pop();
      setState(() {
        if (response.statusCode == 200) {
          ownGroups.add(OwnGroup(
              id: json.decode(utf8.decode(response.bodyBytes)),
              name: groupNameController.text,
              actual: false,
              isCreator: true));
          widget.user.hasNoGroups = false;
          MiCsiToast.info('Sikeres létrehozás!');
        } else {
          MiCsiToast.error('Valami hiba történt!');
        }
        groupNameController.clear();
      });
    });
  }

  void _onSetActualGroup(int index) {
    if (ownGroups.elementAt(index).actual) {
      MiCsiToast.error('Már ez van kiválasztva aktuálisnak!');
    } else {
      var body = <String, dynamic>{};
      body['selectedGroupId'] = ownGroups.elementAt(index).id;
      session.postJson('/api/groups/selectActual', body).then((response) {
        if (response.statusCode == 200) {
          setState(() {
            widget.user.actualGroupId = ownGroups.elementAt(index).id;
            for (var element in ownGroups) {
              element.actual = false;
            }
            ownGroups.elementAt(index).actual = true;
          });
          MiCsiToast.info('Sikeres kiválasztás!');
        } else {
          MiCsiToast.error('Valami hiba történt!');
        }
      });
    }
  }

  void _onJoinWithCode(setInnerState) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerInnerState) {
            return AlertDialog(
              backgroundColor: Colors.grey.shade900,
              title: const Text(
                "Írd be a kódot, amit a társad küldött!",
                style: TextStyle(color: Colors.white),
              ),
              content: innerLoading
                  ? const LoadingAnimation()
                  : Container(
                      padding: const EdgeInsets.only(left: 20.0),
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(10),
                        ),
                        color: Colors.white.withOpacity(0.7),
                      ),
                      child: TextField(
                        style: const TextStyle(color: Colors.black),
                        controller: _invitationCodeController,
                        cursorColor: Colors.black,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide.none),
                          hintText: 'Kód',
                          hintStyle:
                              TextStyle(color: Colors.black.withOpacity(0.5)),
                        ),
                      ),
                    ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _invitationCodeController.clear();
                  },
                  child: const Text("Mégse",
                      style: TextStyle(color: Colors.white)),
                ),
                TextButton(
                  onPressed: () {
                    _addListWithInvitationCode(
                        setInnerState, setInnerInnerState);
                  },
                  child: const Text("Listához adás",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addListWithInvitationCode(setInnerState, setInnerInnerState) {
    setInnerInnerState(() {
      innerLoading = true;
    });
    session.postJson(
        '/api/groupInvitations/joinWithCode/${_invitationCodeController.text}',
        {}).then((response) {
      if (response.statusCode == 200) {
        Navigator.pop(context);
        setInnerState(() {});
        _invitationCodeController.clear();
        MiCsiToast.info('Sikeres hozzáadás!');
      } else {
        setInnerInnerState(() {
          innerLoading = false;
        });
        MiCsiToast.error('Valami hiba történt!');
      }
    });
  }

  void _onCopyGroupCode(OwnGroup group) {
    session
        .get('/api/groupInvitations/getCode/groups/${group.id}')
        .then((response) {
      if (response.statusCode == 200) {
        String code = json.decode(utf8.decode(response.bodyBytes))['code'];
        Clipboard.setData(ClipboardData(text: code))
            .whenComplete(() => MiCsiToast.info('Sikeres másolás: $code'));
        MiCsiToast.info('Sikeres hozzáadás!');
      } else {
        MiCsiToast.error('Valami hiba történt!');
      }
    });
  }
}

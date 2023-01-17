import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:mi_csi/auth/auth_sqflite_handler.dart';
import 'package:mi_csi/base/mi_csi_toast.dart';
import 'package:mi_csi/widgets/create_new_program_idea_widget.dart';

import '../../api/chosen_group_data.dart';
import '../../api/user.dart';
import '../../base/session.dart';
import '../handle_groups_widget.dart';
import '../program_cards_widget.dart';

class MainWidgetDrawer extends StatelessWidget {
  final Session session;
  final User user;
  final Function refreshState;
  final AuthSqfLiteHandler authSqfLiteHandler = AuthSqfLiteHandler();

  MainWidgetDrawer(
      {super.key,
      required this.session,
      required this.user,
      required this.refreshState});

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
                color: Colors.green,
                image: DecorationImage(
                    fit: BoxFit.fitWidth,
                    image:
                    AssetImage('assets/images/free_time_activities.jpeg'))),
            child: Text(
              '',
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Program hozzáadása'),
            onTap: () {
              if (user.hasNoGroups) {
                MiCsiToast.error(
                    'Szerezz először társakat a \'Csoportok kezelése\' menüponton keresztül!');
              } else {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => CreateNewProgramIdeaWidget(
                      session: session,
                      user: user,
                    )));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Csoportok kezelése'),
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                  builder: (context) => HandleGroupsWidget(
                    session: session,
                    user: user,
                  )))
                  .whenComplete(() {
                refreshState();

              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.credit_card_rounded),
            title: const Text('Kártyagyűjtemény megtekintése'),
            onTap: () {
              if(user.actualGroupId == null){
                MiCsiToast.error('Kérlek előbb válaszd ki a csoportot, a fenti menüponton keresztül!');
              }
              else{
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ProgramCardsWidget(session: session, user: user,)));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: const Text('Kijelentkezés'),
            onTap: () {
              session.post(
                '/api/logout',
                <String, dynamic>{},
              ).then((res) {
                if (res.statusCode == 200) {
                  session.updateCookie(res);
                  authSqfLiteHandler.deleteUsers();
                  Phoenix.rebirth(context);
                }
              });
            },
          ),
        ],
      ),
    ));
  }
}

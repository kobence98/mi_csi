import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:mi_csi/base/session.dart';
import 'package:mi_csi/enums/program_type.dart';
import 'package:mi_csi/widgets/draw_random_card.dart';
import 'package:mi_csi/widgets/handle_groups_widget.dart';
import 'package:mi_csi/widgets/stateless/loading_animation.dart';
import 'package:mi_csi/widgets/stateless/main_widget_drawer.dart';

import '../api/chosen_group_data.dart';
import '../api/own_group.dart';
import '../api/user.dart';
import '../base/mi_csi_toast.dart';
import 'draw_card_widget.dart';

class MainWidget extends StatefulWidget {
  final Session session;
  final User user;

  const MainWidget({Key? key, required this.session, required this.user})
      : super(key: key);

  @override
  State<MainWidget> createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  late bool _loadGroupsLoading;
  late bool _loadChosenGroupDataLoading;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<OwnGroup> ownGroups = [];
  late Session session;
  ChosenGroupData? _chosenGroupData;
  late bool _sendDataLoading;

  @override
  void initState() {
    super.initState();
    session = widget.session;
    _loadGroupsLoading = true;
    _loadChosenGroupDataLoading = true;
    _sendDataLoading = false;
  }

  @override
  Widget build(BuildContext context) {
    Widget mainWidget;
    if (_sendDataLoading) {
      mainWidget = const LoadingAnimation();
    } else if (widget.user.hasNoGroups) {
      mainWidget = hasNoGroupsWidget();
    } else if (widget.user.actualGroupId == null) {
      mainWidget = _choseFromYourGroupsWidget();
    } else {
      if (_loadChosenGroupDataLoading) {
        _loadChosenGroupData();
      }
      mainWidget = _loadChosenGroupDataLoading
          ? const LoadingAnimation()
          : (_chosenGroupData == null ||
                  _chosenGroupData!.actualProgramIdea == null
              ? _noActualProgramIdeaWidget()
              : _actualProgramIdeaWidget());
    }
    return SafeArea(
        child: Scaffold(
            key: _scaffoldKey,
            endDrawer: MainWidgetDrawer(
              session: widget.session,
              user: widget.user,
              refreshState: () {
                setState(() {
                  _loadGroupsLoading = true;
                  _loadChosenGroupDataLoading = true;
                  _sendDataLoading = false;
                });
                Navigator.of(context).pop();
              },
            ),
            body: Container(
              color: Colors.black,
              height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  Container(
                    color: Colors.black,
                    height: MediaQuery.of(context).size.height,
                    child: mainWidget,
                  ),
                  Container(
                    height: 70,
                    padding: const EdgeInsets.only(right: 10),
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      child: const Icon(
                        Icons.menu,
                        size: 30,
                        color: Colors.white,
                      ),
                      onTap: () => _scaffoldKey.currentState!.openEndDrawer(),
                    ),
                  ),
                ],
              ),
            )));
  }

  void _openMap(LatLng latLng, String name, String placeName) async {
    final availableMaps = await MapLauncher.installedMaps;
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Scaffold(
            body: SingleChildScrollView(
              child: Wrap(
                children: <Widget>[
                  for (var map in availableMaps)
                    ListTile(
                      onTap: () => map.showMarker(
                        coords: Coords(latLng.latitude, latLng.longitude),
                        title: name,
                        description: placeName,
                      ),
                      title: Text(map.mapName),
                      leading: SvgPicture.asset(
                        map.icon,
                        height: 30.0,
                        width: 30.0,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _choseFromYourGroupsWidget() {
    if (_loadGroupsLoading) {
      _loadOwnGroups();
    }
    return _loadGroupsLoading
        ? const LoadingAnimation()
        : Container(
            color: Colors.black,
            padding: const EdgeInsets.only(
                top: 100, bottom: 100, left: 30, right: 30),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              child: ListView.builder(
                itemCount: ownGroups.length + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: Colors.white,
                      child: const Center(
                        child: Text(
                          'Válassz a csoportjaid közül!',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 30,
                              color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  } else {
                    i = i - 1;
                    return InkWell(
                      child: Container(
                        height: 50,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.black),
                        child: SizedBox(
                          child: Center(
                            child: Text(
                              ownGroups.elementAt(i).name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20),
                            ),
                          ),
                        ),
                      ),
                      onTap: () {
                        _selectGroup(i);
                      },
                    );
                  }
                },
              ),
            ),
          );
  }

  void _loadOwnGroups() {
    session.get('/api/groups/own').then((response) {
      if (response.statusCode == 200) {
        session.updateCookie(response);
        Iterable l = json.decode(utf8.decode(response.bodyBytes));
        ownGroups =
            List<OwnGroup>.from(l.map((model) => OwnGroup.fromJson(model)));
        setState(() {
          _loadGroupsLoading = false;
        });
      }
    });
  }

  void _selectGroup(int index) {
    var body = <String, dynamic>{};
    body['selectedGroupId'] = ownGroups.elementAt(index).id;
    session.postJson('/api/groups/selectActual', body).then((response) {
      if (response.statusCode == 200) {
        setState(() {
          widget.user.actualGroupId = ownGroups.elementAt(index).id;
          _loadGroupsLoading = true;
          ownGroups.clear();
        });
        MiCsiToast.info('Sikeres kiválasztás!');
      } else {
        MiCsiToast.error('Valami hiba történt!');
      }
    });
  }

  Widget hasNoGroupsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Center(
            child: Text(
              'Nem vagy tagja egyetlen csoportnak sem!',
              style: TextStyle(color: Colors.white, fontSize: 30),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            height: 50,
          ),
          Center(
            child: InkWell(
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(
                        builder: (context) => HandleGroupsWidget(
                            session: session, user: widget.user)))
                    .whenComplete(() {
                  setState(() {
                    _loadGroupsLoading = true;
                  });
                });
              },
              child: Container(
                height: 40,
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text(
                    'Csoportok megtekintése',
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  void _loadChosenGroupData() {
    session
        .get('/api/programIdeas/group/${widget.user.actualGroupId}')
        .then((response) {
      if (response.statusCode == 200) {
        session.updateCookie(response);
        _chosenGroupData = ChosenGroupData.fromJson(
            json.decode(utf8.decode(response.bodyBytes)));
        setState(() {
          _loadChosenGroupDataLoading = false;
        });
      }
    });
  }

  Widget _noActualProgramIdeaWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.group,
                  color: Colors.white,
                ),
                const SizedBox(
                  width: 20,
                ),
                Center(
                  child: Text(
                    _chosenGroupData!.groupName,
                    style: const TextStyle(color: Colors.white, fontSize: 30),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                const Icon(
                  Icons.group,
                  color: Colors.white,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (context) =>
                          DrawCardWidget(session: session, user: widget.user)))
                  .whenComplete(() {
                setState(() {
                  _loadGroupsLoading = true;
                  _loadChosenGroupDataLoading = true;
                });
              });
            },
            child: Container(
              height: (MediaQuery.of(context).size.height - 70) / 2,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                  opacity: 0.25,
                  fit: BoxFit.fitHeight,
                  image: AssetImage(
                    "assets/images/draw_card.jpg",
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  'Húzok a másik paklijából egy programot!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 50,
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (context) => DrawRandomCardWidget(
                          session: session, user: widget.user)))
                  .whenComplete(() {
                setState(() {
                  _loadGroupsLoading = true;
                  _loadChosenGroupDataLoading = true;
                });
              });
            },
            child: Container(
              height: (MediaQuery.of(context).size.height - 70) / 2,
              width: MediaQuery.of(context).size.width,
              decoration: const BoxDecoration(
                color: Colors.white,
                image: DecorationImage(
                  opacity: 0.15,
                  fit: BoxFit.fitHeight,
                  image: AssetImage(
                    "assets/images/roulette.jpg",
                  ),
                ),
              ),
              child: const Center(
                child: Text(
                  'Sorsolok egy programot a közösekből!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 50,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actualProgramIdeaWidget() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.only(top: 100, left: 30, right: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            height: MediaQuery.of(context).size.height - 300,
            decoration: _chosenGroupData!.actualProgramIdea!.pictureId == null
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    image: DecorationImage(
                      opacity: 0.3,
                      fit: BoxFit.fill,
                      image: NetworkImage(
                        "${widget.session.domainName}/api/images/${_chosenGroupData!.actualProgramIdea!.pictureId}",
                        headers: widget.session.headers,
                      ),
                    ),
                  ),
            child: ListView(
              children: [
                Center(
                  child: Text(
                    _chosenGroupData!.actualProgramIdea!.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 40,
                        color: Colors.black),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Program típusa',
                        style: TextStyle(fontSize: 30, color: Colors.white),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _chosenGroupData!
                                .actualProgramIdea!.programType.icon,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                              _chosenGroupData!
                                  .actualProgramIdea!.programType.hunName,
                              style: const TextStyle(color: Colors.white)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Program helyszíne',
                        style: TextStyle(fontSize: 30, color: Colors.white),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.pin_drop_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 110,
                            child: Text(
                                _chosenGroupData!.actualProgramIdea!.place ==
                                        null
                                    ? 'Nincs megadva'
                                    : _chosenGroupData!
                                        .actualProgramIdea!.place!,
                                style: const TextStyle(color: Colors.white)),
                          )
                        ],
                      ),
                      SizedBox(
                          height: _chosenGroupData!
                                      .actualProgramIdea!.coordinates ==
                                  null
                              ? 0
                              : 10),
                      _chosenGroupData!.actualProgramIdea!.coordinates == null
                          ? Container()
                          : InkWell(
                              child: const Text(
                                'Megnyitás térképen',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic),
                              ),
                              onTap: () {
                                _openMap(
                                    _chosenGroupData!
                                        .actualProgramIdea!.coordinates!,
                                    _chosenGroupData!.actualProgramIdea!.name,
                                    _chosenGroupData!
                                        .actualProgramIdea!.place!);
                              },
                            )
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            height: 100,
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                    onPressed: () {
                      _onCancelActualProgram();
                    },
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.white)),
                    child: const Text(
                      'Másik választása',
                      style: TextStyle(color: Colors.black),
                    )),
                ElevatedButton(
                    onPressed: () {
                      _onDoneActualProgram();
                    },
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.white)),
                    child: const Text(
                      'Megcsináltuk!',
                      style: TextStyle(color: Colors.black),
                    ))
              ],
            ),
          )
        ],
      ),
    );
  }

  void _onCancelActualProgram() async {
    setState(() {
      _sendDataLoading = true;
    });
    dynamic response = await session.postJson(
        '/api/programIdeas/${_chosenGroupData!.actualProgramIdea!.id}/removeActual',
        <String, String>{});
    if (response.statusCode == 200) {
      MiCsiToast.info('Sikeres visszavonás!');
    } else {
      MiCsiToast.error('Valami hiba történt!');
    }
    setState(() {
      _loadGroupsLoading = true;
      _loadChosenGroupDataLoading = true;
      _sendDataLoading = false;
    });
  }

  void _onDoneActualProgram() async {
    setState(() {
      _sendDataLoading = true;
    });
    dynamic response = await session.postJson(
        '/api/programIdeas/${_chosenGroupData!.actualProgramIdea!.id}/done',
        <String, String>{});
    if (response.statusCode == 200) {
      MiCsiToast.info('Ügyesek vagytok! Remélem jól éreztétek magatokat!:)');
    } else {
      MiCsiToast.error('Valami hiba történt!');
    }
    setState(() {
      _loadGroupsLoading = true;
      _loadChosenGroupDataLoading = true;
      _sendDataLoading = false;
    });
  }
}

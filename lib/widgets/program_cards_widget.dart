import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_flip_card/controllers/flip_card_controllers.dart';
import 'package:flutter_flip_card/flipcard/flip_card.dart';
import 'package:flutter_flip_card/modal/flip_side.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:mi_csi/base/mi_csi_toast.dart';
import 'package:mi_csi/enums/program_type.dart';
import 'package:mi_csi/widgets/stateless/loading_animation.dart';

import '../api/program_idea.dart';
import '../api/user.dart';
import '../base/session.dart';

class ProgramCardsWidget extends StatefulWidget {
  final Session session;
  final User user;

  const ProgramCardsWidget(
      {Key? key, required this.session, required this.user})
      : super(key: key);

  @override
  State<ProgramCardsWidget> createState() => _ProgramCardsWidgetState();
}

class _ProgramCardsWidgetState extends State<ProgramCardsWidget> {
  List<ProgramIdea> programIdeas = [];
  late Session session;
  late bool _loading;
  List<FlipCardController> flipCardControllers = [];

  @override
  void initState() {
    session = widget.session;
    _loading = true;
    session
        .get('/api/programIdeas/group/${widget.user.actualGroupId}/deck')
        .then((response) {
      if (response.statusCode == 200) {
        session.updateCookie(response);
        Iterable l = json.decode(utf8.decode(response.bodyBytes));
        programIdeas = List<ProgramIdea>.from(
            l.map((model) => ProgramIdea.fromJson(model)));
        programIdeas.shuffle();
        for (var element in programIdeas) {
          flipCardControllers.add(FlipCardController());
        }
        setState(() {
          _loading = false;
        });
      } else {
        MiCsiToast.error(
            'Valami hiba történt, kérlek ellenőrizd az internetkapcsolatot!');
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          InkWell(
            child: const Icon(
              Icons.info,
              color: Colors.white,
            ),
            onTap: () {
              MiCsiToast.info(
                  'A csillaggal jelölt kártyák a sajátjaid, ezeket rájuk kattintva fel tudod fordítani.');
            },
          ),
          const SizedBox(
            width: 10,
          ),
        ],
      ),
      body: _loading
          ? const LoadingAnimation()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20),
              itemCount: programIdeas.length ~/ 2 + (programIdeas.length % 2),
              itemBuilder: (context, i) {
                return SizedBox(
                  height: 300,
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    children: [
                      Flexible(
                        flex: 1,
                        child: _flipCard(programIdeas.elementAt(i * 2)),
                      ),
                      Flexible(
                        flex: 1,
                        child: (programIdeas.length % 2 == 1) &&
                                i == programIdeas.length ~/ 2
                            ? SizedBox(
                                height: MediaQuery.of(context).size.height,
                                width: MediaQuery.of(context).size.width,
                              )
                            : _flipCard(programIdeas.elementAt(i * 2 + 1)),
                      ),
                    ],
                  ),
                );
              },
            ),
    ));
  }

  Widget _flipCard(ProgramIdea idea) {
    Widget frontSide = Stack(
      children: [
        idea.pictureId == null
            ? Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black.withOpacity(0.03),
                ),
                child: Center(
                  child: Icon(
                    idea.programType.icon,
                    color: Colors.white,
                    size: MediaQuery.of(context).size.width / 4,
                  ),
                ),
              )
            : Container(),
        Container(
            margin: const EdgeInsets.all(10),
            padding: const EdgeInsets.all(10),
            decoration: idea.pictureId == null
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.black),
                  )
                : BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      opacity: 0.1,
                      fit: BoxFit.fill,
                      image: NetworkImage(
                        "${widget.session.domainName}/api/images/${idea.pictureId}",
                        headers: widget.session.headers,
                      ),
                    ),
                    border: Border.all(color: Colors.black),
                  ),
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      idea.programType.icon,
                      color: Colors.black,
                    ),
                    InkWell(
                      child: Icon(
                        idea.userId == widget.user.userId
                            ? Icons.star
                            : Icons.supervisor_account_rounded,
                        color: Colors.yellow.shade700,
                      ),
                      onTap: () {
                        MiCsiToast.info(idea.userId == widget.user.userId
                            ? 'Ezt a programot te hoztad létre!'
                            : 'Ezt a programot ${idea.userName} hozta létre!');
                      },
                    ),
                    Icon(
                      idea.programType.icon,
                      color: Colors.black,
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    idea.name,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      idea.programType.icon,
                      color: Colors.black,
                    ),
                    InkWell(
                      child: idea.usedTimes != 0
                          ? const Icon(
                              Icons.check,
                              color: Colors.green,
                            )
                          : const Icon(
                              Icons.not_interested_rounded,
                              color: Colors.red,
                            ),
                      onTap: () {
                        MiCsiToast.info(idea.usedTimes == 0
                            ? 'Ezt a programot még nem csináltátok meg!'
                            : 'Ezt a programot már megcsináltátok! :)');
                      },
                    ),
                    Icon(
                      idea.programType.icon,
                      color: Colors.black,
                    ),
                  ],
                ),
              ],
            ))
      ],
    );

    Widget backSide = Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(10),
          child: idea.pictureId == null
              ? Center(
                  child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black,
                  ),
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: Center(
                    child: Icon(
                      idea.programType.icon,
                      color: Colors.white,
                      size: MediaQuery.of(context).size.width / 4,
                    ),
                  ),
                ))
              : Center(
                  child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    width: MediaQuery.of(context).size.width,
                    child: Image.network(
                      "${widget.session.domainName}/api/images/${idea.pictureId}",
                      headers: widget.session.headers,
                      fit: BoxFit.fill,
                    ),
                  ),
                )),
        ),
        idea.userId == widget.user.userId
            ? Container(
                margin: const EdgeInsets.all(20),
                child: const Icon(
                  Icons.star,
                  color: Colors.yellow,
                ),
              )
            : Container(),
      ],
    );

    int index = programIdeas.indexWhere((element) => element.id == idea.id);

    return InkWell(
      child: FlipCard(
        rotateSide: RotateSide.right,
        axis: FlipAxis.vertical,
        controller: flipCardControllers.elementAt(index),
        frontWidget: idea.usedTimes == 0 ? backSide : frontSide,
        backWidget: idea.usedTimes == 0 ? frontSide : backSide,
      ),
      onTap: () {
        if (idea.usedTimes != 0 ||
            (idea.usedTimes == 0 &&
                !flipCardControllers.elementAt(index).state!.isFront)) {
          _openMoreDetailsWidget(idea);
        } else if (idea.usedTimes == 0 &&
            idea.userId == widget.user.userId &&
            flipCardControllers.elementAt(index).state!.isFront) {
          flipCardControllers.elementAt(index).flipcard();
        } else {
          MiCsiToast.info('Ezt a programot még nem csináltátok meg! :)');
        }
      },
    );
  }

  _openMoreDetailsWidget(ProgramIdea idea) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: Center(
              child: Text(
                idea.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    color: Colors.white),
              ),
            ),
            content: Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.all(3),
              height: 300,
              width: MediaQuery.of(context).size.width,
              child: ListView(
                children: [
                  Center(
                    child: Text(
                      idea.name,
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
                              idea.programType.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(idea.programType.hunName,
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
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                width: MediaQuery.of(context).size.width - 164,
                                child: Text(
                                    idea.place == null
                                        ? 'Nincs megadva'
                                        : idea.place!,
                                    style:
                                        const TextStyle(color: Colors.white)),
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: idea.coordinates == null ? 0 : 10),
                        idea.coordinates == null
                            ? Container()
                            : InkWell(
                                child: const Text(
                                  'Megnyitás térképen',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontStyle: FontStyle.italic),
                                ),
                                onTap: () {
                                  _openMap(idea.coordinates!, idea.name,
                                      idea.place!);
                                },
                              )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: idea.userId == widget.user.userId ? 5 : 0,
                  ),
                  idea.userId == widget.user.userId
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: (MediaQuery.of(context).size.width) / 3 - 10,
                              child: ElevatedButton(
                                  style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              Colors.black)),
                                  onPressed: () {
                                    _onDeleteIdeaPressed(idea.id);
                                  },
                                  child: const Text('Törlés')),
                            ),
                            SizedBox(
                              width: (MediaQuery.of(context).size.width) / 3 - 10,
                              child: ElevatedButton(
                                  style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(
                                              Colors.black)),
                                  onPressed: () {
                                    _onPutBackIdeaPressed(idea.id);
                                  },
                                  child:
                                      const Text('Visszahelyezés a pakliba')),
                            ),
                          ],
                        )
                      : Container(),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
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

  void _onDeleteIdeaPressed(int id) {
    setState(() {
      _loading = true;
    });
    session.delete('/api/programIdeas/$id').then((response) {
      if (response.statusCode == 200) {
        programIdeas.removeWhere((element) => element.id == id);
        setState(() {
          _loading = false;
        });
        Navigator.of(context).pop();
        MiCsiToast.info('Sikeres törlés!');
      } else {
        setState(() {
          _loading = false;
        });
        Navigator.of(context).pop();
        MiCsiToast.error('Valami hiba történt, kérlek próbáld újra!');
      }
    });
  }

  void _onPutBackIdeaPressed(int id) {
    setState(() {
      _loading = true;
    });
    session
        .postJson('/api/programIdeas/$id/placeBackToDeck', {}).then((response) {
      if (response.statusCode == 200) {
        programIdeas.firstWhere((element) => element.id == id).usedTimes = 0;
        setState(() {
          _loading = false;
        });
        Navigator.of(context).pop();
        MiCsiToast.info('Sikeres visszahelyezés!');
      } else {
        setState(() {
          _loading = false;
        });
        Navigator.of(context).pop();
        MiCsiToast.error('Valami hiba történt, kérlek próbáld újra!');
      }
    });
  }
}

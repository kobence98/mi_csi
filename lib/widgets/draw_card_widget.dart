import 'dart:convert';

import 'package:google_maps_flutter_platform_interface/src/types/location.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flip_card/controllers/flip_card_controllers.dart';
import 'package:flutter_flip_card/flipcard/flip_card.dart';
import 'package:flutter_flip_card/modal/flip_side.dart';
import 'package:flutter_svg/svg.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:mi_csi/api/program_idea.dart';
import 'package:mi_csi/base/session.dart';
import 'package:mi_csi/enums/program_type.dart';
import 'package:mi_csi/widgets/stateless/loading_animation.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';

import '../api/user.dart';
import '../base/mi_csi_toast.dart';

class DrawCardWidget extends StatefulWidget {
  final Session session;
  final User user;

  const DrawCardWidget({Key? key, required this.session, required this.user})
      : super(key: key);

  @override
  State<DrawCardWidget> createState() => _DrawCardWidgetState();
}

class _DrawCardWidgetState extends State<DrawCardWidget>
    with TickerProviderStateMixin {
  bool _loading = true;
  List<ProgramIdea> programIdeas = [];
  late Session session;
  int _focusedIndex = 0;
  bool selected = false;
  ProgramIdea? _selectedIdea;
  List<FlipCardController> flipCardControllers = [];
  late Animation<Color?> _colorAnimation;
  late AnimationController _colorController;

  @override
  void initState() {
    super.initState();
    _colorController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _colorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.grey,
    ).animate(_colorController)
      ..addListener(() {
        setState(() {});
      });
    session = widget.session;
    session
        .get('/api/programIdeas/group/${widget.user.actualGroupId}/notOwn')
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
      }
    });
  }

  void _onItemFocus(int index) {
    setState(() {
      _focusedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: selected
            ? FloatingActionButton(
          backgroundColor: Colors.black,
                onPressed: () {
                  _openChosenDialog();
                },
                child: const Icon(Icons.save),
              )
            : null,
        appBar: AppBar(
          leading: InkWell(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(
              Icons.arrow_back,
              color: Colors.black,
            ),
          ),
          backgroundColor: _colorAnimation.value,
        ),
        body: Container(
          color: _colorAnimation.value,
          child: _loading
              ? const LoadingAnimation()
              : ScrollSnapList(
                  scrollDirection: Axis.horizontal,
                  selectedItemAnchor: SelectedItemAnchor.MIDDLE,
                  onItemFocus: _onItemFocus,
                  itemSize: 200,
                  initialIndex: 0,
                  scrollPhysics: selected
                      ? const NeverScrollableScrollPhysics()
                      : const ScrollPhysics(),
                  dynamicItemSize: true,
                  itemBuilder: (context, i) {
                    ProgramIdea idea = programIdeas.elementAt(i);
                    Widget frontSide = Container(
                      color: _colorAnimation.value,
                      child: Container(
                        decoration: idea.pictureId == null
                            ? BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white,
                                border: Border.all(color: Colors.black),
                              )
                            : BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white,
                                image: DecorationImage(
                                  opacity: 0.3,
                                  fit: BoxFit.fill,
                                  image: NetworkImage(
                                    "${widget.session.domainName}/api/images/${idea.pictureId}",
                                    headers: widget.session.headers,
                                  ),
                                ),
                              ),
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: Center(
                          child: Text(
                            idea.name,
                            style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width / 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );

                    Widget backSide = Container(
                      color: _colorAnimation.value,
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
                              child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: NetworkImage(
                                    "${widget.session.domainName}/api/images/${idea.pictureId}",
                                    headers: widget.session.headers,
                                  ),
                                ),
                              ),
                              height: MediaQuery.of(context).size.height,
                              width: MediaQuery.of(context).size.width,
                            )),
                    );
                    // _askForConfirm(idea, flipCardController);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        GestureDetector(
                          child: AnimatedSize(
                            duration: const Duration(seconds: 1),
                            child: Container(
                              height: _selectedIdea == idea ? 390 : 300,
                              width: _selectedIdea == idea ? 260 : 200,
                              color: Colors.white,
                              child: FlipCard(
                                rotateSide: RotateSide.right,
                                animationDuration: const Duration(seconds: 1),
                                axis: FlipAxis.vertical,
                                controller: flipCardControllers.elementAt(i),
                                frontWidget: backSide,
                                backWidget: frontSide,
                              ),
                            ),
                          ),
                          onTap: () {
                            if (!selected) {
                              flipCardControllers
                                  .elementAt(i)
                                  .flipcard()
                                  .whenComplete(() {
                                setState(() {
                                  selected = true;
                                  _selectedIdea = idea;
                                  _colorController.forward();
                                });
                              });
                            }
                          },
                        ),
                      ],
                    );
                  },
                  itemCount: programIdeas.length,
                  reverse: false,
                ),
        ),
      ),
    );
  }

  void _askForConfirm(ProgramIdea idea, FlipCardController flipCardController) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const Text('Biztosan ezt a kártyát választod?'),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Mégse')),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  //TODO itt valami nagyon nem stimmel, de valahogy azt kéne, hogy ez kiemelődik és utána hívódik meg az api és csak leokézni lehet

                  setState(() {});
                  // _openChosenDialog(idea);
                },
                child: const Text('Igen!'),
              )
            ],
          );
        });
  }

  void _openChosenDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.black,
            title: Center(
              child: Text(
                _selectedIdea!.name,
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
                      _selectedIdea!.name,
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
                              _selectedIdea!.programType.icon,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text(
                                _selectedIdea!.programType.hunName,
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
                              width: MediaQuery.of(context).size.width - 164,
                              child: Text(
                                  _selectedIdea!.place ==
                                      null
                                      ? 'Nincs megadva'
                                      : _selectedIdea!.place!,
                                  style: const TextStyle(color: Colors.white)),
                            )
                          ],
                        ),
                        SizedBox(
                            height: _selectedIdea!.coordinates ==
                                null
                                ? 0
                                : 10),
                        _selectedIdea!.coordinates == null
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
                                _selectedIdea!.coordinates!,
                                _selectedIdea!.name,

                                _selectedIdea!.place!);
                          },
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  setState(() {
                    _loading = true;
                  });
                  dynamic response = await session.postJson(
                      '/api/programIdeas/${_selectedIdea!.id}/setActual',
                      <String, String>{});
                  if (response.statusCode == 200) {
                    _loading = false;
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                    MiCsiToast.info('Sikeres kiválasztás!');
                  } else {
                    setState(() {
                      _loading = false;
                    });
                    MiCsiToast.error('Valami hiba történt!');
                  }
                },
                child:
                    const Text('Mentés', style: TextStyle(color: Colors.white)),
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
}

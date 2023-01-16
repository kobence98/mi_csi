import 'dart:convert';
import 'dart:typed_data';

import 'package:address_search_field/address_search_field.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mi_csi/base/mi_csi_toast.dart';
import 'package:mi_csi/base/session.dart';
import 'package:mi_csi/widgets/address_search_dialog.dart'
    as custom_address_search;
import 'package:mi_csi/widgets/stateless/loading_animation.dart';

import '../api/own_group.dart';
import '../api/user.dart';
import '../enums/program_type.dart';

class CreateNewProgramIdeaWidget extends StatefulWidget {
  final Session session;
  final User user;

  const CreateNewProgramIdeaWidget(
      {Key? key, required this.session, required this.user})
      : super(key: key);

  @override
  State<CreateNewProgramIdeaWidget> createState() =>
      _CreateNewProgramIdeaWidgetState();
}

class _CreateNewProgramIdeaWidgetState
    extends State<CreateNewProgramIdeaWidget> {
  final TextEditingController searchFieldController = TextEditingController();
  final TextEditingController _titleTextController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  late ProgramType _chosenType;
  late OwnGroup _chosenGroup;
  GeoMethods geoMethods = GeoMethods(
    googleApiKey: 'AIzaSyDsH8UXHos_FicrDoizXYKzTZLVVvDQLsI',
    language: 'hu',
    countryCode: 'hu',
    countryCodes: ['hu', 'at'],
    country: 'Hungary',
  );
  Address? destinationAddress;
  late bool _titleIsEmpty;
  late Session session;
  List<OwnGroup> ownGroups = [];
  bool loading = true;
  CroppedFile? image;

  @override
  void initState() {
    super.initState();
    session = widget.session;
    _chosenType = ProgramType.OTHER;
    session.get('/api/groups/own').then((response) {
      if (response.statusCode == 200) {
        setState(() {
          session.updateCookie(response);
          Iterable l = json.decode(utf8.decode(response.bodyBytes));
          ownGroups =
              List<OwnGroup>.from(l.map((model) => OwnGroup.fromJson(model)));
          loading = false;
          _chosenGroup = widget.user.actualGroupId == null
              ? ownGroups.first
              : ownGroups
                  .firstWhere((group) => group.id == widget.user.actualGroupId);
        });
      }
    });
    _titleTextController.text = 'Kattints ide az esemény nevének beírásához';
    _titleIsEmpty = true;
    _titleFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_titleFocusNode.hasFocus && _titleTextController.text.isEmpty) {
      setState(() {
        _titleTextController.text =
            'Kattints ide az esemény nevének beírásához';
        _titleIsEmpty = true;
      });
    }
    if (_titleFocusNode.hasFocus) {
      setState(() {
        if (_titleIsEmpty) {
          _titleTextController.clear();
        }
        _titleIsEmpty = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: loading
          ? const LoadingAnimation()
          : Container(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ListView(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        const Center(
                          child: Text(
                            'Esemény neve',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Center(
                          child: EditableText(
                            style: TextStyle(
                                color:
                                    _titleIsEmpty ? Colors.grey : Colors.black,
                                fontSize: 15),
                            textAlign: TextAlign.center,
                            controller: _titleTextController,
                            focusNode: _titleFocusNode,
                            cursorColor: Colors.black,
                            backgroundCursorColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        const Center(
                          child: Text(
                            'Helyszín',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        InkWell(
                          child: Container(
                            child: Center(
                              child: Text(
                                destinationAddress == null
                                    ? 'Kattints ide a cím hozzáadásához!'
                                    : destinationAddress!.reference!,
                                style: TextStyle(
                                    color: destinationAddress == null
                                        ? Colors.grey
                                        : Colors.black,
                                    fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          onTap: () => showDialog(
                              context: context,
                              builder: (BuildContext context) =>
                                  custom_address_search.AddressSearchDialog(
                                      geoMethods: geoMethods,
                                      texts: const custom_address_search
                                              .AddressDialogTexts(
                                          noResultsText:
                                              'Nincs a keresésnek megfelelő találat'),
                                      style: const custom_address_search
                                              .AddressDialogStyle(
                                          color: Colors.black),
                                      controller: searchFieldController,
                                      onDone: (Address address) {
                                        setState(() {
                                          destinationAddress = address;
                                        });
                                      })),
                        ),
                        SizedBox(
                          height: destinationAddress == null ? 0 : 10,
                        ),
                        destinationAddress == null
                            ? Container()
                            : (destinationAddress!.coords == null
                                ? const Center(
                                    child: Text(
                                      'Koordináták: Nem a listából választottál címet',
                                      style: TextStyle(
                                          color: Colors.black, fontSize: 15),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      'Koordináták: ${destinationAddress!.coords!.latitude.toString()}, ${destinationAddress!.coords!.longitude.toString()}',
                                      style: const TextStyle(
                                          color: Colors.black, fontSize: 15),
                                    ),
                                  )),
                        SizedBox(
                          height: destinationAddress == null ? 0 : 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        const Center(
                          child: Text(
                            'Esemény típusa',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Center(
                          child: DropdownButton<ProgramType>(
                            isExpanded: true,
                            focusColor: Colors.white,
                            value: _chosenType,
                            style: const TextStyle(color: Colors.black),
                            iconEnabledColor: Colors.black,
                            dropdownColor: Colors.white,
                            items: ProgramType.values
                                .map<DropdownMenuItem<ProgramType>>(
                                    (ProgramType type) {
                              return DropdownMenuItem<ProgramType>(
                                value: type,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      type.icon,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      type.hunName.toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            hint: const Text(
                              'Válassz esemény típust!',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                            onChanged: (ProgramType? type) {
                              setState(() {
                                _chosenType = type!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        const Center(
                          child: Text(
                            'Csoport',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Center(
                          child: DropdownButton<OwnGroup>(
                            isExpanded: true,
                            focusColor: Colors.white,
                            value: _chosenGroup,
                            style: const TextStyle(color: Colors.black),
                            iconEnabledColor: Colors.black,
                            dropdownColor: Colors.white,
                            items: ownGroups.map<DropdownMenuItem<OwnGroup>>(
                                (OwnGroup group) {
                              return DropdownMenuItem<OwnGroup>(
                                value: group,
                                child: Text(
                                  group.name,
                                  style: const TextStyle(color: Colors.black),
                                ),
                              );
                            }).toList(),
                            hint: const Text(
                              'Válassz a csoportjaid közül!',
                              style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500),
                            ),
                            onChanged: (OwnGroup? group) {
                              setState(() {
                                _chosenGroup = group!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        const Center(
                          child: Text(
                            'Kép',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: image == null
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              child: Container(
                                child: Center(
                                  child: Text(
                                    image == null
                                        ? 'Kattints ide a kép hozzáadásához!'
                                        : image!.path.split('/').last,
                                    style: TextStyle(
                                        color: destinationAddress == null
                                            ? Colors.grey
                                            : Colors.black,
                                        fontSize: 15),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              onTap: () async {
                                final ImagePicker picker = ImagePicker();
                                // Pick an image
                                XFile? pickedImage = await picker.pickImage(
                                    source: ImageSource.gallery);
                                image = await ImageCropper.platform.cropImage(
                                  aspectRatio: const CropAspectRatio(
                                      ratioX: 2, ratioY: 3),
                                  sourcePath: pickedImage!.path,
                                  maxWidth: 1080,
                                  maxHeight: 1080,
                                  uiSettings: [
                                    AndroidUiSettings(
                                        toolbarTitle: 'Cropper',
                                        toolbarColor: Colors.deepOrange,
                                        toolbarWidgetColor: Colors.white,
                                        initAspectRatio:
                                            CropAspectRatioPreset.original,
                                        lockAspectRatio: false),
                                    IOSUiSettings(
                                      title: 'Cropper',
                                    ),
                                    WebUiSettings(
                                      context: context,
                                    ),
                                  ],
                                );
                                if (image != null) {
                                  MemoryImage preview =
                                      MemoryImage(await image!.readAsBytes());
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('Előnézet'),
                                          content: Container(
                                            height: 300,
                                            width: 200,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                  image: preview),
                                            ),
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  setState(() {
                                                    image = null;
                                                  });
                                                },
                                                child: const Text('Mégse')),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                setState(() {});
                                              },
                                              child: const Text('Mentés'),
                                            )
                                          ],
                                        );
                                      });
                                }
                              },
                            ),
                            SizedBox(
                              height: image == null ? 0 : 10,
                            ),
                            image == null
                                ? Container()
                                : InkWell(
                                    child: const Icon(Icons.close),
                                    onTap: () {
                                      setState(() {
                                        image = null;
                                      });
                                    },
                                  ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  InkWell(
                    onTap: () {
                      _saveIdea();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey),
                      child: const Center(
                        child: Text(
                          'MENTÉS',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 25,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  )
                ],
              )),
    ));
  }

  void _saveIdea() async {
    if (_titleIsEmpty) {
      MiCsiToast.error('A program nevét kötelező megadni!');
    } else {
      setState(() {
        loading = true;
      });
      Uint8List? multipartImage =
          image == null ? null : await image!.readAsBytes();
      var body = <String, String>{};
      body['name'] = _titleTextController.text;
      body['programType'] = _chosenType.name;
      body['groupId'] = _chosenGroup.id.toString();
      if(destinationAddress != null){
        body['place'] = destinationAddress!.reference!;
      }
      if(destinationAddress != null && destinationAddress!.coords != null){
        body['latitude'] = destinationAddress!.coords!.latitude.toString();
        body['longitude'] = destinationAddress!.coords!.longitude.toString();
      }
      dynamic response = await (multipartImage == null
          ? session.postJson('/api/programIdeas', body)
          : session.sendMultipart(
              '/api/programIdeas/withImage', body, multipartImage));
      if (response.statusCode == 200) {
        Navigator.of(context).pop();
        loading = false;
        MiCsiToast.info('Sikeres mentés!');
      } else {
        setState(() {
          loading = false;
        });
        MiCsiToast.error('Valami hiba történt!');
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _titleFocusNode.removeListener(_onFocusChange);
    _titleTextController.dispose();
    searchFieldController.dispose();
    _titleFocusNode.dispose();
  }
}

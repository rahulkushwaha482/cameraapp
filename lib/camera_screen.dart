import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:camera_app/trimmer_view.dart';
import 'package:camera_app/video_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key}) : super(key: key);

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isRecording = false;

  //late CameraController _cameraController;
  late AnimationController controller;
  int seconds = 10;
  final _maxSeconds = 10;
  int _currentSecond = 0;
  late Timer _timer;
  late XFile _video;

  late CameraController _controller;
  late List<CameraDescription> _availableCameras;

  @override
  void initState() {
    super.initState();

    checkPermission();

    _getAvailableCameras();

    controller = AnimationController(
      /// [AnimationController]s can be created with `vsync: this` because of
      /// [TickerProviderStateMixin].
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat(reverse: false);
  }

  checkPermission() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.camera,
      Permission.videos,
    ].request();

    if (statuses[Permission.storage] != null) {
      //check each permission status after.
      print(statuses[Permission.storage]);
    }

    if (statuses[Permission.camera] != null) {
      //check each permission status after.
      print(statuses[Permission.camera]);
    }
  }

  // get available cameras
  Future<void> _getAvailableCameras() async {
    WidgetsFlutterBinding.ensureInitialized();
    _availableCameras = await availableCameras();
    _initCamera(_availableCameras.first);
  }

  Future<void> _initCamera(CameraDescription description) async {
    _controller =
        CameraController(description, ResolutionPreset.max, enableAudio: true);
    try {
      await _controller.initialize();
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    controller.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _toggleCameraLens() {
    // get current lens direction (front / rear)
    final lensDirection = _controller.description.lensDirection;
    CameraDescription newDescription;
    if (lensDirection == CameraLensDirection.front) {
      newDescription = _availableCameras.firstWhere((description) =>
          description.lensDirection == CameraLensDirection.back);
    } else {
      newDescription = _availableCameras.firstWhere((description) =>
          description.lensDirection == CameraLensDirection.front);
    }

    if (newDescription != null) {
      _initCamera(newDescription);
    } else {
      // print('Asked camera not available');
    }
  }

  // _changeCamera() async {
  //   final cameras = await availableCameras();
  //   final front = cameras.firstWhere(
  //           (camera) => camera.lensDirection == CameraLensDirection.back);
  //   _cameraController = CameraController(front, ResolutionPreset.max);
  // }

  _recordVideo() async {
    if (_isRecording) {
      _stopRecording();
    } else {
      await _controller.prepareForVideoRecording();
      await _controller.startVideoRecording();
      setState(() => _isRecording = true);
      _startTimer();
    }
  }

  _stopRecording() async {
    final file = await _controller.stopVideoRecording();
    final fileNew = File(file.path);
    setState(() => _isRecording = false);
    final route = MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => TrimmerView(fileNew),
    );
    Navigator.push(context, route);
  }

  void _startTimer() {
    final duration = Duration(seconds: 1);
    _timer = Timer.periodic(duration, (Timer timer) {
      setState(() {
        _currentSecond = timer.tick;
        if (timer.tick >= _maxSeconds) {
          timer.cancel();
          _stopRecording();
          _currentSecond = 0;
        }
      });
    });
  }

  _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowCompression: false,
    );
    if (result != null) {
      File file = File(result.files.single.path!);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return TrimmerView(file);
        }),
      );
    }

    //   final ImagePicker _picker = ImagePicker();
    //   XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    //   if (video != null) {
    //     setState(() {
    //       _video = video;
    //       final route = MaterialPageRoute(
    //         fullscreenDialog: true,
    //         builder: (_) => VideoPage(filePath: _video.path,file:video),
    //       );
    //       Navigator.push(context, route);

    //     });
    //   }
    // } catch (error) {
    //   print(error);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: <Widget>[
          CameraPreview(_controller),
          Positioned(
            top: 50,
            bottom: 750,
            right: 0,
            left: 0,
            child: LinearProgressIndicator(
              minHeight: 10.0,
              value: _currentSecond / 10,
              backgroundColor: Colors.greenAccent,
              semanticsLabel: 'Linear progress indicator',
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 120.0,
              padding: EdgeInsets.all(20.0),
              color: Color.fromRGBO(00, 00, 00, 0.7),
              child: Stack(
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                        onTap: () {
                          _toggleCameraLens();
                          // if (!_toggleCamera) {
                          //   onCameraSelected(widget.cameras[1]);
                          //   setState(() {
                          //     _toggleCamera = true;
                          //   });
                          // } else {
                          //   onCameraSelected(widget.cameras[0]);
                          //   setState(() {
                          //     _toggleCamera = false;
                          //   });
                          // }
                        },
                        child: Container(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.cameraswitch,
                              color: Colors.yellow,
                            )),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 60,
                    child: GestureDetector(
                      onTap: () async {
                        await _pickVideo();
                      },
                      child: Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(4.0),
                          child: Image.asset(
                            'assets/gallery.jpeg',
                            scale: 1,
                          )),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: 80,
                      width: 80,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                            strokeWidth: 5,
                            value: _currentSecond / 10,
                          ),
                          Center(
                            child: FloatingActionButton(
                              backgroundColor: Colors.red,
                              child: Icon(
                                  _isRecording ? Icons.stop : Icons.circle),
                              onPressed: () => _recordVideo(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                        padding: const EdgeInsets.all(2.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          onPressed: () {},
                          child: const Text(
                            'NEXT',
                            style: TextStyle(color: Colors.black),
                          ),
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // return Stack(
    //   clipBehavior: Clip.none,
    //   fit: StackFit.passthrough,
    //   children: [
    //     Positioned.fill(
    //       child:  AspectRatio(
    //           aspectRatio: _cameraController.value.aspectRatio,
    //           child:     CameraPreview(_cameraController),),
    //     ),
    //
    //     Positioned(
    //         top: 50,
    //         child:   LinearProgressIndicator(
    //           minHeight: 10.0,
    //           value: controller.value,
    //           backgroundColor: Colors.greenAccent,
    //           semanticsLabel: 'Linear progress indicator',
    //
    //       ),
    //     ),
    //
    //     //
    //     // Row(
    //     //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //     //   children: [
    //     //     Padding(
    //     //       padding: const EdgeInsets.all(25),
    //     //       child: FloatingActionButton(
    //     //         child: Icon(Icons.cameraswitch_rounded),
    //     //         onPressed: () => {},
    //     //       ),
    //     //     ),
    //     //     Padding(
    //     //       padding: const EdgeInsets.all(25),
    //     //       child: FloatingActionButton(
    //     //         backgroundColor: Colors.red,
    //     //         child: Icon(_isRecording ? Icons.stop : Icons.circle),
    //     //         onPressed: () => _recordVideo(),
    //     //       ),
    //     //     ),
    //     //     Padding(
    //     //       padding: const EdgeInsets.all(25),
    //     //       child: Container(),
    //     //     ),
    //     //   ],
    //     // ),
    //   ],
    // );
  }
}

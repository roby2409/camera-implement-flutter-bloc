import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_photos/blocs/camera/camera_bloc.dart';
import 'package:my_photos/keys.dart';
import 'package:my_photos/widgets/error.dart';

class CameraScreen extends StatefulWidget {
  final int amoutTakeWillBe;
  const CameraScreen({Key? key, required this.amoutTakeWillBe})
      : super(key: key);
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance?.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ignore: close_sinks
    final bloc = BlocProvider.of<CameraBloc>(context);

    // App state changed before we got the chance to initialize.
    if (!bloc.isInitialized()) return;

    if (state == AppLifecycleState.inactive)
      bloc.add(CameraStopped());
    else if (state == AppLifecycleState.resumed) bloc.add(CameraInitialized());
  }

  @override
  Widget build(BuildContext context) {
    int amount = widget.amoutTakeWillBe;
    return BlocConsumer<CameraBloc, CameraState>(
        listener: (_, state) {
          if (state is CameraCaptureSuccess) {
            Navigator.of(context).pop(amount > 1 ? state.pathMoreThanOnce : state.path);
          } else if (state is CameraCaptureFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.error),
            ));
          }
        },
        builder: (_, state) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                  title: Text("camera is set to take $amount photo" +
                      (amount > 1 ? "'s" : ""))),
              body: state is CameraReady || state is CameraCaptureInProgress
                  ? Column(children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: BlocProvider.of<CameraBloc>(context)
                              .getController()
                              .value
                              .aspectRatio,
                          child: CameraPreview(
                              BlocProvider.of<CameraBloc>(context)
                                  .getController()),
                        ),
                      ),
                    ])
                  : state is CameraFailure
                      ? Error(
                          key: MyPhotosKeys.errorScreen, message: state.error)
                      : Container(
                          alignment: Alignment.center,
                          key: MyPhotosKeys.emptyContainerScreen,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'no state camera',
                                style: TextStyle(color: Colors.white),
                              ),
                              ElevatedButton(
                                  onPressed: () {
                                    BlocProvider.of<CameraBloc>(context)
                                        .add(CameraInitialized());
                                  },
                                  child: Text('initialize camera'))
                            ],
                          ),
                        ),
              floatingActionButton: state is CameraReady
                  ? FloatingActionButton(
                      child: Icon(Icons.camera_alt),
                      onPressed: () => BlocProvider.of<CameraBloc>(context).add(
                          CameraCaptured(
                              amountPicture: widget.amoutTakeWillBe)),
                    )
                  : state is CameraCaptureInProgress
                      ? Container(child: LinearProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.secondary),
                        value: state.progressValue,
                      ),
)
                      : Container(),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerFloat,
            ));
  }
}

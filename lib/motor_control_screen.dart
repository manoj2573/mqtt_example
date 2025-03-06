import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'mqtt_service.dart';

class MotorControlScreen extends StatefulWidget {
  final String registrationNumber;

  const MotorControlScreen({super.key, required this.registrationNumber});

  @override
  _MotorControlScreenState createState() => _MotorControlScreenState();
}

class _MotorControlScreenState extends State<MotorControlScreen> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  bool motorOn = false;
  String lastActionTime = "";
  bool isWaitingForResponse = false;

  @override
  void initState() {
    super.initState();
    setupMqtt();

    _controller = VideoPlayerController.asset('assets/motorFan.mp4');
    _initializeVideoPlayerFuture = _controller.initialize();
    _controller.setLooping(true);
  }

  Future<void> setupMqtt() async {
    await MqttService.setupMqttClient(widget.registrationNumber);

    MqttService.setMessageHandler((message) {
      if (message['action'] == 'motorOn') {
        updateMotorState(true);
      } else if (message['action'] == 'motorOff') {
        updateMotorState(false);
      } else if (message['action'] == 'status') {
        handleStatusMessage(message);
      }
    });
  }

  void updateMotorState(bool state) {
    setState(() {
      motorOn = state;
      isWaitingForResponse = false;
      lastActionTime = DateFormat("yyyy-MM-dd HH:mm:ss").format(DateTime.now());

      if (motorOn) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  void handleStatusMessage(Map<String, dynamic> message) {
    bool status = message['motorStatus'] == 'on';
    updateMotorState(status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("Received motor status: ${status ? 'ON' : 'OFF'}")),
    );
  }

  void sendMotorCommand(bool state) {
    setState(() {
      isWaitingForResponse = true;
    });

    MqttService.publishMotorAction(widget.registrationNumber, state);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FutureBuilder(
          future: _initializeVideoPlayerFuture,
          builder: (context, snapshot) {
            return snapshot.connectionState == ConnectionState.done
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : Center(child: CircularProgressIndicator());
          },
        ),
        ElevatedButton(
          onPressed: isWaitingForResponse ? null : () => sendMotorCommand(true),
          child: isWaitingForResponse && motorOn
              ? Text("Waiting for response...")
              : Text("Turn Motor ON"),
        ),
        ElevatedButton(
          onPressed:
              isWaitingForResponse ? null : () => sendMotorCommand(false),
          child: isWaitingForResponse && !motorOn
              ? Text("Waiting for response...")
              : Text("Turn Motor OFF"),
        ),
        Text("Last Action: $lastActionTime"),
      ],
    );
  }
}

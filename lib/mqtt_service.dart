import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';

class MqttService {
  static late MqttServerClient client;
  static bool isConnected = false;
  static Function(Map<String, dynamic>)? messageHandler;

  static Future<void> setupMqttClient(String registrationNumber) async {
    client = MqttServerClient.withPort(
      'anqg66n1fr3hi-ats.iot.eu-north-1.amazonaws.com',
      'flutter_client',
      8883,
    );

    client.keepAlivePeriod = 20;
    client.logging(on: true);

    final connMessage = MqttConnectMessage()
        .withClientIdentifier('flutter_client')
        .startClean()
        .withWillTopic('$registrationNumber/status')
        .withWillMessage('offline')
        .withWillQos(MqttQos.atMostOnce);

    client.connectionMessage = connMessage;

    final context = await getSecurityContext();
    client.secure = true;
    client.securityContext = context;

    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;

    try {
      await client.connect();
      if (client.connectionStatus!.state == MqttConnectionState.connected) {
        isConnected = true;
        print('✅ Connected to MQTT');
        subscribeToTopic(
            "$registrationNumber/mobile"); // ✅ Listen for responses
      } else {
        print('❌ Failed to connect to MQTT');
      }
    } catch (e) {
      print('❌ Error connecting to AWS IoT: $e');
    }

    listenForMessages();
  }

  static Future<SecurityContext> getSecurityContext() async {
    SecurityContext context = SecurityContext.defaultContext;

    final rootCA = await rootBundle.load('assets/root-CA.crt');
    context.setTrustedCertificatesBytes(rootCA.buffer.asUint8List());

    final clientCert = await rootBundle.load('assets/pem.crt');
    final privateKey = await rootBundle.load('assets/private.pem.key');

    context.useCertificateChainBytes(clientCert.buffer.asUint8List());
    context.usePrivateKeyBytes(privateKey.buffer.asUint8List());

    return context;
  }

  static void onConnected() {
    print('✅ Connected to MQTT Broker.');
  }

  static void onDisconnected() {
    isConnected = false;
    print('❌ Disconnected from MQTT Broker.');
  }

  static void subscribeToTopic(String topic) {
    if (isConnected) {
      client.subscribe(topic, MqttQos.atMostOnce);
      print("📡 Subscribed to topic: $topic");
    } else {
      print("⚠️ Cannot subscribe, MQTT not connected.");
    }
  }

  static void publishMotorAction(String registrationNumber, bool motorOn) {
    if (!isConnected) {
      print("⚠️ MQTT Not Connected. Cannot publish message.");
      return;
    }

    final message = {
      'action': motorOn ? 'motorOn' : 'motorOff', // ✅ Clear action names
      'timestamp': DateTime.now().toIso8601String(),
    };

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(message));

    final topic = "$registrationNumber/device";
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    print("📤 Published to $topic: ${jsonEncode(message)}");

    // ✅ After publishing, wait for a response on the mobile topic
    subscribeToTopic("$registrationNumber/mobile");
  }

  static void setMessageHandler(Function(Map<String, dynamic>) handler) {
    messageHandler = handler;
  }

  static void listenForMessages() {
    client.updates!.listen((List<MqttReceivedMessage<MqttMessage>> event) {
      final recMess = event[0].payload as MqttPublishMessage;
      final message =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print("📩 Received MQTT Message: $message");

      try {
        final dynamic decodedMessage = jsonDecode(message);
        if (decodedMessage is Map<String, dynamic>) {
          print("✅ Decoded JSON Message: $decodedMessage");
          if (messageHandler != null) {
            messageHandler!(decodedMessage); // ✅ Pass response to UI
          }
        } else {
          print(
              "❌ Decoded message is not a valid JSON object: $decodedMessage");
        }
      } catch (e) {
        print("❌ Error decoding JSON message: $e");
      }
    });
  }

  static void publishStatusRequest(String registrationNumber) {
    if (!isConnected) {
      print("⚠️ MQTT Not Connected. Cannot publish message.");
      return;
    }

    final message = {
      'action': 'status', // ✅ Status request message
      'timestamp': DateTime.now().toIso8601String(),
    };

    final builder = MqttClientPayloadBuilder();
    builder.addString(jsonEncode(message));

    final topic = "$registrationNumber/device";
    client.publishMessage(topic, MqttQos.atMostOnce, builder.payload!);
    print("📤 Published status request to $topic: ${jsonEncode(message)}");

    // ✅ After publishing, wait for a response
    subscribeToTopic("$registrationNumber/mobile");
  }
}

import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:dio/dio.dart';
import 'package:background_location/background_location.dart';
import 'dart:math';

BaseOptions options = BaseOptions(
  baseUrl: "http://ebookstore-drf-api.herokuapp.com/api/district",
  connectTimeout: 5000,
  receiveTimeout: 5000,
);
Dio dio = Dio(options);

void backgroundFetchHeadlessTask(HeadlessTask task) async {
  var taskId = task.taskId;
  bool isTimeout = task.timeout;

  if (isTimeout) {
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    BackgroundLocation.stopLocationService();
  }

  if (taskId == 'my_background_task') {
    print(taskId);
    print('[BackgroundFetch] Headless event received.');

    BackgroundLocation.setAndroidConfiguration(60000);
    BackgroundLocation.startLocationService();
    BackgroundLocation.getLocationUpdates((location) {
      print(
          '[${DateTime.now()}] Location ==> ${location.longitude} -- ${location.latitude}');
    });
  }
  BackgroundFetch.finish(taskId);
}

void main() {
  runApp(MyApp());
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    var status = await BackgroundFetch.configure(
        BackgroundFetchConfig(
            minimumFetchInterval: 15,
            forceAlarmManager: false,
            stopOnTerminate: false,
            startOnBoot: true,
            enableHeadless: true,
            requiresBatteryNotLow: false,
            requiresCharging: false,
            requiresStorageNotLow: false,
            requiresDeviceIdle: false,
            requiredNetworkType: NetworkType.NONE),
        _onBackgroundFetch,
        _onBackgroundFetchTimeout);
    print('[BackgroundFetch] configure success: $status');
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: "my_background_task",
        delay: 1000,
        periodic: false,
        stopOnTerminate: false,
        enableHeadless: true));
  }

  void _onBackgroundFetchTimeout(String taskId) {
    print("[BackgroundFetch] TIMEOUT: $taskId");
    BackgroundFetch.finish(taskId);
  }

  void _onBackgroundFetch(String taskId) async {
    if (taskId == "your_task_id") {
      print("[BackgroundFetch] Event received");
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }

  double calculateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_launcher_icons/android.dart';
import 'package:flutter_launcher_icons/constants.dart';
import 'package:flutter_launcher_icons/custom_exceptions.dart';
import 'package:flutter_launcher_icons/ios.dart';
import 'package:flutter_launcher_icons/main.dart';
import 'package:flutter_launcher_icons/utils.dart';
import 'package:flutter_launcher_icons/xml_templates.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';

// Initialise notification setting for Android
const AndroidNotificationChannel androidNotificationChannel = AndroidNotificationChannel(
    'notification_channel_android',
    'Notification Channel',
    importance: Importance.high,
    playSound: true
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// Initialize Firebase app when a notification is receive in the background
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Message: ${message.messageId}');
}

void main() async {
  //
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
  ?.createNotificationChannel(androidNotificationChannel);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  //
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Local Notification'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // Handle foreground notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android     = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                androidNotificationChannel.id,
                androidNotificationChannel.name,
                channelDescription: androidNotificationChannel.description,
                color: Colors.blue,
                playSound: true,
                icon: 'images/instagramclonelogo.jpg',
              ),
            )
        );
      }
    });
  }

  void scheduleNotification() async {

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Warsaw'));

    var androidPlatformNotificationSetup = AndroidNotificationDetails(
        '7997',
        '7997',
        //'Channel for Alarm notification',
        icon: 'instagramclonelogo',
        sound: RawResourceAndroidNotificationSound('a_long_cold_sting'),
        largeIcon: DrawableResourceAndroidBitmap('instagramclonelogo'),
    );
    var iOSPlatformNotificationSetup = IOSNotificationDetails(
      sound: 'a_long_cold_sting.wav',
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    var platformChannelSpecifics = NotificationDetails(android: androidPlatformNotificationSetup, iOS: iOSPlatformNotificationSetup);
    await flutterLocalNotificationsPlugin.zonedSchedule(
        0,
        'Instagram',
        "Someone liked your page",
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
        platformChannelSpecifics,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: const Text(
          'Push blue button below to show local notification after 5 seconds with custom sound.',
          textAlign: TextAlign.center,
        )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: scheduleNotification,
        tooltip: 'Increment',
        child: const Icon(Icons.notification_important_outlined),
      ),
    );
  }
}

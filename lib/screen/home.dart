import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  final String _gitUrl = 'https://github.com/Alanbalza/chaka.git';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset('assets/UP.jpg', width: 300, height: 300),
            const SizedBox(height: 10),
            const Text(
              'Ingeniería en Software 9B \n 221229 - Alan David Balbuena Zavala \n Programación para móviles II',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),
            GestureDetector(
              onTap: () async {
                if (await canLaunchUrl(Uri.parse(_gitUrl))) {
                  await launchUrl(Uri.parse(_gitUrl));
                } else {
                  throw 'Could not launch $_gitUrl';
                }
              },
              child: const Text(
                'GitHub',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

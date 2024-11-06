import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class PaginaImpostazioni extends StatelessWidget {
  const PaginaImpostazioni({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.info_rounded, color: Colors.red),
              title: const Text('Versione app: 1.0'),
              onLongPress: () {
                Clipboard.setData(const ClipboardData(text: '1.0'));
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.code_rounded, color: Colors.red),
              title: const Text('Codice sorgente'),
              onTap: () => launchURL(Uri(
                scheme: 'https',
                host: 'github.com',
                path: '/SimonGitto/appmobile',
              )),
              onLongPress: () {
                Clipboard.setData(const ClipboardData(text: 'https://github.com/SimonGitto/appmobile'));
              },
            ),
            ExpansionTile(
              leading: const Icon(Icons.people_alt_rounded, color: Colors.red),
              title: const Text('Sviluppatori'),
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: GestureDetector(
                      child: const Icon(Icons.link),
                      onTap: () => launchURL(Uri(
                        scheme: 'https',
                        host: 'github.com',
                        path: '/Darpet23',
                      )),
                      onLongPress: () {
                        Clipboard.setData(const ClipboardData(text: 'https://github.com/Darpet23'));
                      },
                    ),
                    title: const Text('Dario Petruccelli'),
                    onLongPress: () {
                      Clipboard.setData(const ClipboardData(text: 'Dario Petruccelli'));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: GestureDetector(
                      child: const Icon(Icons.link),
                      onTap: () => launchURL(Uri(
                        scheme: 'https',
                        host: 'github.com',
                        path: '/SimonGitto',
                      )),
                      onLongPress: () {
                        Clipboard.setData(const ClipboardData(text: 'https://github.com/SimonGitto'));
                      },
                    ),
                    title: const Text('Simone Infantino'),
                    onLongPress: () {
                      Clipboard.setData(const ClipboardData(text: 'Simone Infantino'));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> launchURL(Uri url) async {
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }
}

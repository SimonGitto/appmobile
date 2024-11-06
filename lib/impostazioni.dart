import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class PaginaImpostazioni extends StatelessWidget {
  const PaginaImpostazioni({super.key});

  @override
  void initState(){
    checkAndRequestPermission;
  }

  Future<void> launchURL(Uri url) async {
    if (!await launchUrl(url)) {
      throw 'Could not launch $url';
    }
  }

  void _showScannerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.red, width: 4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    final qrText = barcode.rawValue ?? "No Data found in QR";
                    print(qrText);
                    Clipboard.setData(ClipboardData(text: qrText));
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> checkAndRequestPermission() async {
    if (await Permission.camera.isDenied){
      await Permission.camera.request();
    }
  }

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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                  Icons.qr_code_rounded,
                  color: Colors.red
              ),
              title: const Text('Scansiona un codice QR'),
              onTap: () {
                _showScannerDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }




}

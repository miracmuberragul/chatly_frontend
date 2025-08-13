import 'dart:convert';

import 'package:flutter/material.dart';

/// Displays a tapped chat image in full-screen with pinch-zoom support.
/// Accepts both base64 data URIs and regular HTTP/HTTPS URLs.
class FullImageView extends StatelessWidget {
  final String imageUrl;
  const FullImageView({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget img;
    if (imageUrl.startsWith('data:image')) {
      final bytes = base64Decode(imageUrl.split(',').last);
      img = Image.memory(bytes, fit: BoxFit.contain);
    } else {
      img = Image.network(imageUrl, fit: BoxFit.contain);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: img,
        ),
      ),
    );
  }
}

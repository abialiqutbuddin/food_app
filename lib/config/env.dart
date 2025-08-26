import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

/// Four environments (demo uses local assets instead of network)
enum Env { demo, dev, qa, prod }

/// Choose active environment (hook up to flavors later if you want)
const Env kEnv = Env.demo;

// DEMO loaders: use a flat key, not the URL path.
Future<dynamic> demoLoadJsonByKey(String key) async {
  final path = 'assets/demo_responses/$key.json';
  final text = await rootBundle.loadString(path);
  return jsonDecode(text);
}

Future<Uint8List> demoLoadBytesByKey(String keyWithExt) async {
  final data = await rootBundle.load('assets/demo_responses/$keyWithExt');
  return data.buffer.asUint8List();
}
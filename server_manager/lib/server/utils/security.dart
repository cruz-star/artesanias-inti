import 'package:crypto/crypto.dart';
import 'dart:convert';

String hashPassword(String password) {
  return sha256.convert(utf8.encode(password)).toString();
}

String generateToken() {
  return DateTime.now().millisecondsSinceEpoch.toString() +
      sha256.convert(utf8.encode(DateTime.now().toString())).toString();
}

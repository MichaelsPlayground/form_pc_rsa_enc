import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:pointycastle/export.dart' as pc;
import 'package:basic_utils/basic_utils.dart';

// based on https://flutter.de/artikel/flutter-formulare.html
// https://github.com/coodoo-io/flutter-samples
// edited to null safety
// access to form data

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyFormPage(title: 'RSA OAEP SHA1 encryption'),
    );
  }
}

class MyFormPage extends StatefulWidget {
  MyFormPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyFormPageState createState() => _MyFormPageState();
}

class _MyFormPageState extends State<MyFormPage> {
  @override
  void initState() {
    super.initState();
    descriptionController.text = txtDescription;
  }

  final _formKey = GlobalKey<FormState>();
  TextEditingController descriptionController = TextEditingController();

  // the following controller has a default value
  TextEditingController plaintextController = TextEditingController(
      text: 'The quick brown fox jumps over the lazy dog');
  TextEditingController publicKeyController = TextEditingController();
  TextEditingController emailEditingController = TextEditingController();
  TextEditingController numberEditingController = TextEditingController();
  TextEditingController keyController = TextEditingController();
  TextEditingController outputController = TextEditingController();
  TextEditingController inputController = TextEditingController();

  String dropdownValue = 'RSA OAEP SHA1 encryption';
  String txtDescription = 'RSA OAEP SHA1 encryption.'
      '\nDer Schlüssel wird aus dem Speicher geladen.';

  static Future<ClipboardData?> getData(String format) async {
    final Map<String, dynamic>? result =
    await SystemChannels.platform.invokeMethod(
      'Clipboard.getData',
      format,
    );
    if (result == null) return null;
    return ClipboardData(text: result['text'] as String?);
  }

  String _returnJsonDeseri(String data) {
    final parsedJson = jsonDecode(data);
    String iterations = '0';
    if (parsedJson?['iterations'] != null) {
      iterations = parsedJson?['iterations'];
    }
    ;
    String result = 'algorithm: ' +
        parsedJson['algorithm'] +
        '\n'
            'iterations: ' +
        iterations;

    return result;
  }

  String _returnJson(String data) {
    var parts = data.split(':');
    var algorithm = parts[0];
    var iterations = parts[1];
    var plaintext = parts[2];
    var salt = parts[3];
    var nonce = parts[4];
    var ciphertext = parts[5];
    var gcmTag = parts[6];
/* test null safety
    Encryption encryption = Encryption(
        algorithm: algorithm,
        iterations: null,
        salt: salt,
        nonce: nonce,
        ciphertext: ciphertext,
        gcmTag: gcmTag);

 */

    Encryption encryption = Encryption(
        algorithm: algorithm,
        iterations: iterations,
        salt: salt,
        nonce: nonce,
        ciphertext: ciphertext,
        gcmTag: gcmTag);

    String encryptionResult = jsonEncode(encryption);
    String exportData = '{"algorithm":"' +
        algorithm +
        '","iterations":"' +
        iterations +
        '","plaintext":"' +
        plaintext +
        '","salt":"' +
        salt +
        '","nonce":"' +
        nonce +
        '","ciphertext":"' +
        ciphertext +
        '","gcmTag":"' +
        gcmTag +
        '"}';

    User user = User(algorithm, plaintext);
    String jsonUser = jsonEncode(user);

    final jsonData = '{ "name": "Pizza da Mario", "cuisine": "Italian" }';
    final parsedJson = jsonDecode(jsonData);
    print('${parsedJson.runtimeType} : $parsedJson');

    /*
    List decodedList = JSON.decode('["Flutter", true]');

    var exportData = JSON.encode({
    'framework': "Flutter",
    'tags': ['flutter', 'snippets'],
    'versions': '0.0.20',
    'task': 13511,
    });
*/
    //String exportData = '{"framework":"Flutter","tags":["flutter","snippets"],"versions":"0.0.20","task":13511}';
    //outputController.text = exportData;
    //return exportData;

    // {"algorithm":"AES-256 GCM PBKDF2","iterations":"10000","salt":"0IVpqIziJ4OtrhVKehdgLHpukOuOSPrlX202Wc4voRQ=","nonce":"0HKptx5YN0+zIjLw","ciphertext":"zBZLulzazLa5NfmNX74LUDb8WHQnnW4qdh2hiCOaqauSVzNc9rTnMFct7g==","gcmTag":"Wi9iyNJ+Wl08Gaid1l5EjQ=="}

    return encryptionResult;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: SingleChildScrollView(
            child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      //SizedBox(height: 20),
                      TextFormField(
                        controller: descriptionController,
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                        enabled: false,
                        // false = disabled, true = enabled
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Beschreibung',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: plaintextController,
                        keyboardType: TextInputType.text,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'Klartext',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte Daten eingeben';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.grey,
                                textStyle: TextStyle(color: Colors.white)),
                            onPressed: () {
                              plaintextController.text = '';
                            },
                            child: Text('Feld löschen'),
                          ),
                          SizedBox(width: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.blue,
                                textStyle: TextStyle(color: Colors.white)),
                            onPressed: () async {
                              final data =
                              await Clipboard.getData(Clipboard.kTextPlain);
                              plaintextController.text = data!.text!;
                            },
                            child: Text('aus Zwischenablage einfügen'),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: keyController,
                        enabled: true,
                        // false = disabled, true = enabled
                        maxLines: 5,
                        maxLength: 2000,
                        style: TextStyle(
                          fontSize: 15,
                        ),
                        keyboardType: TextInputType.multiline,
                        decoration: InputDecoration(
                          labelText:
                          'Privater Schlüssel für RSA in PKCS#8 encoded PEM',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte Daten eingeben';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.grey,
                                textStyle: TextStyle(color: Colors.white)),
                            onPressed: () {
                              keyController.text = '';
                            },
                            child: Text('Feld löschen'),
                          ),
                          SizedBox(width: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.blue,
                                textStyle: TextStyle(color: Colors.white)),
                            onPressed: () {
                              //keyController.text = _loadKey();
                              keyController.text = loadRsaPrivateKeyPem();
                              publicKeyController.text = loadRsaPublicKeyPem();
                              //readData2();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Daten wurden gelesen')),
                              );
                              // Wenn alle Validatoren der Felder des Formulars g¸ltig sind.
                            },
                            child: Text('Datei laden'),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: publicKeyController,
                        obscureText: false,
                        // true zeigt Sternchen
                        maxLines: 5,
                        maxLength: 2000,
                        decoration: InputDecoration(
                          labelText: 'PublicKey',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bitte Daten eingeben';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.grey,
                                textStyle: TextStyle(color: Colors.white)),
                            onPressed: () {
                              // reset() setzt alle Felder wieder auf den Initalwert zurück.
                              _formKey.currentState!.reset();
                            },
                            child: Text('Formulardaten löschen'),
                          ),
                          SizedBox(width: 25),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.blue,
                                textStyle: TextStyle(color: Colors.white)),
                            onPressed: () {


                              // Wenn alle Validatoren der Felder des Formulars g¸ltig sind.
                              if (_formKey.currentState!.validate()) {
                                print(
                                    "Formular ist gültig und kann verarbeitet werden");
                                String plaintext = plaintextController.text;

                                // If the form is valid, display a snackbar. In the real world,
                                // you'd often call a server or save the information in a database.
                                RSAPublicKey rsaPublicKey =
                                CryptoUtils.rsaPublicKeyFromPem(
                                    publicKeyController.text)
                                as RSAPublicKey;
                                String encryption = rsaEncryptionOaepSha1(
                                    rsaPublicKey,
                                    createUint8ListFromString(
                                        plaintextController.text));
                                RSAPrivateKey rsaPrivateKey =
                                CryptoUtils.rsaPrivateKeyFromPem(
                                    keyController.text);
                                String decryption = rsaDecryptionOaepSha1(
                                    rsaPrivateKey, encryption);

                                outputController.text = 'Plaintext ist: ' +
                                    plaintext +
                                    '\n' +
                                    'Ciphertext ist: ' +
                                    '\n' +
                                    encryption +
                                    '\n' +
                                    'Decryptedtext ist: ' +
                                    decryption;
                                /*
                                String _formdata = 'AES-256 GCM PBKDF2' +
                                    ':' +
                                    '10000' +
                                    ':' +
                                    plaintext +
                                    ':' +
                                    '0IVpqIziJ4OtrhVKehdgLHpukOuOSPrlX202Wc4voRQ=:0HKptx5YN0+zIjLw:zBZLulzazLa5NfmNX74LUDb8WHQnnW4qdh2hiCOaqauSVzNc9rTnMFct7g==:Wi9iyNJ+Wl08Gaid1l5EjQ==';
                                //'output is (Base64) salt : (Base64) nonce : (Base64) ciphertext : (Base64) gcmTag';
                                outputController.text = _returnJson(_formdata);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(_formdata)),
                                );
                                                */

                              } else {
                                print("Formular ist nicht gültig");
                              }
                            },
                            child: Text('verschlüsseln'),
                          )
                        ],
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: outputController,
                        maxLines: 20,
                        maxLength: 500,
                        decoration: InputDecoration(
                          labelText: 'Ausgabe',
                          hintText: 'Ausgabe',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.grey,
                                textStyle: TextStyle(color: Colors.white)),
                            onPressed: () {
                              outputController.text = '';
                            },
                            child: Text('Feld löschen'),
                          ),
                          SizedBox(width: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.blue,
                                textStyle: TextStyle(color: Colors.white)),
                            onPressed: () async {
                              final data =
                              ClipboardData(text: outputController.text);
                              await Clipboard.setData(data);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Copied to clipboard!'),
                                ),
                              );
                            },
                            child: Text('in Zwischenablage kopieren'),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: inputController,
                        maxLines: 5,
                        maxLength: 500,
                        decoration: InputDecoration(
                          labelText: 'Eingabe',
                          hintText: 'Eingabe',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.grey,
                                textStyle: TextStyle(color: Colors.white)),
                            onPressed: () {
                              outputController.text = '';
                            },
                            child: Text('Feld löschen'),
                          ),
                          SizedBox(width: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.blue,
                                textStyle: TextStyle(color: Colors.white)),
                            onPressed: () async {
                              final data =
                              ClipboardData(text: outputController.text);
                              await Clipboard.setData(data);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Copied to clipboard!'),
                                ),
                              );
                            },
                            child: Text('in'),
                          ),
                          SizedBox(width: 15),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                primary: Colors.green,
                                textStyle: TextStyle(color: Colors.white)),
                            onPressed: () {
                              String jsonData = outputController.text;

                              inputController.text =
                                  _returnJsonDeseri(jsonData);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  duration: const Duration(milliseconds: 400),
                                  content: Text(jsonData),
                                ),
                              );
                            },
                            child: Text('JSON seri'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ))));
  }

  String rsaEncryptionOaepSha1(
      RSAPublicKey publicKey, Uint8List dataToEncrypt) {
    final encryptor = pc.OAEPEncoding(pc.RSAEngine())
      ..init(
          true, pc.PublicKeyParameter<RSAPublicKey>(publicKey)); // true=encrypt
    return base64Encoding(_processInBlocks(encryptor, dataToEncrypt));
  }

  String rsaDecryptionOaepSha1(
      RSAPrivateKey privateKey, String ciphertextBase64) {
    final decryptor = pc.OAEPEncoding(pc.RSAEngine())
      ..init(false,
          pc.PrivateKeyParameter<RSAPrivateKey>(privateKey)); // false=decrypt
    return new String.fromCharCodes(
        _processInBlocks(decryptor, base64Decoding(ciphertextBase64)));
  }

  Uint8List _processInBlocks(pc.AsymmetricBlockCipher engine, Uint8List input) {
    final numBlocks = input.length ~/ engine.inputBlockSize +
        ((input.length % engine.inputBlockSize != 0) ? 1 : 0);
    final output = Uint8List(numBlocks * engine.outputBlockSize);
    var inputOffset = 0;
    var outputOffset = 0;
    while (inputOffset < input.length) {
      final chunkSize = (inputOffset + engine.inputBlockSize <= input.length)
          ? engine.inputBlockSize
          : input.length - inputOffset;
      outputOffset += engine.processBlock(
          input, inputOffset, chunkSize, output, outputOffset);
      inputOffset += chunkSize;
    }
    return (output.length == outputOffset)
        ? output
        : output.sublist(0, outputOffset);
  }

  Uint8List createUint8ListFromString(String s) {
    var ret = new Uint8List(s.length);
    for (var i = 0; i < s.length; i++) {
      ret[i] = s.codeUnitAt(i);
    }
    return ret;
  }

  String base64Encoding(Uint8List input) {
    return base64.encode(input);
  }

  Uint8List base64Decoding(String input) {
    return base64.decode(input);
  }

  String loadRsaPublicKeyPem() {
    return ('''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA8EmWJUZ/Osz4vXtUU2S+
0M4BP9+s423gjMjoX+qP1iCnlcRcFWxthQGN2CWSMZwR/vY9V0un/nsIxhZSWOH9
iKzqUtZD4jt35jqOTeJ3PCSr48JirVDNLet7hRT37Ovfu5iieMN7ZNpkjeIG/CfT
/QQl7R+kO/EnTmL3QjLKQNV/HhEbHS2/44x7PPoHqSqkOvl8GW0qtL39gTLWgAe8
01/w5PmcQ38CKG0oT2gdJmJqIxNmAEHkatYGHcMDtXRBpOhOSdraFj6SmPyHEmLB
ishaq7Jm8NPPNK9QcEQ3q+ERa5M6eM72PpF93g2p5cjKgyzzfoIV09Zb/LJ2aW2g
QwIDAQAB
-----END PUBLIC KEY-----''');
  }

  String loadRsaPrivateKeyPem() {
    return ('''-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDwSZYlRn86zPi9
e1RTZL7QzgE/36zjbeCMyOhf6o/WIKeVxFwVbG2FAY3YJZIxnBH+9j1XS6f+ewjG
FlJY4f2IrOpS1kPiO3fmOo5N4nc8JKvjwmKtUM0t63uFFPfs69+7mKJ4w3tk2mSN
4gb8J9P9BCXtH6Q78SdOYvdCMspA1X8eERsdLb/jjHs8+gepKqQ6+XwZbSq0vf2B
MtaAB7zTX/Dk+ZxDfwIobShPaB0mYmojE2YAQeRq1gYdwwO1dEGk6E5J2toWPpKY
/IcSYsGKyFqrsmbw0880r1BwRDer4RFrkzp4zvY+kX3eDanlyMqDLPN+ghXT1lv8
snZpbaBDAgMBAAECggEBAIVxmHzjBc11/73bPB2EGaSEg5UhdzZm0wncmZCLB453
XBqEjk8nhDsVfdzIIMSEVEowHijYz1c4pMq9osXR26eHwCp47AI73H5zjowadPVl
uEAot/xgn1IdMN/boURmSj44qiI/DcwYrTdOi2qGA+jD4PwrUl4nsxiJRZ/x7PjL
hMzRbvDxQ4/Q4ThYXwoEGiIBBK/iB3Z5eR7lFa8E5yAaxM2QP9PENBr/OqkGXLWV
qA/YTxs3gAvkUjMhlScOi7PMwRX9HsrAeLKbLuC1KJv1p2THUtZbOHqrAF/uwHaj
ygUblFaa/BTckTN7PKSVIhp7OihbD04bSRrh+nOilcECgYEA/8atV5DmNxFrxF1P
ODDjdJPNb9pzNrDF03TiFBZWS4Q+2JazyLGjZzhg5Vv9RJ7VcIjPAbMy2Cy5BUff
EFE+8ryKVWfdpPxpPYOwHCJSw4Bqqdj0Pmp/xw928ebrnUoCzdkUqYYpRWx0T7YV
RoA9RiBfQiVHhuJBSDPYJPoP34kCgYEA8H9wLE5L8raUn4NYYRuUVMa+1k4Q1N3X
Bixm5cccc/Ja4LVvrnWqmFOmfFgpVd8BcTGaPSsqfA4j/oEQp7tmjZqggVFqiM2m
J2YEv18cY/5kiDUVYR7VWSkpqVOkgiX3lK3UkIngnVMGGFnoIBlfBFF9uo02rZpC
5o5zebaDImsCgYAE9d5wv0+nq7/STBj4NwKCRUeLrsnjOqRriG3GA/TifAsX+jw8
XS2VF+PRLuqHhSkQiKazGr2Wsa9Y6d7qmxjEbmGkbGJBC+AioEYvFX9TaU8oQhvi
hgA6ZRNid58EKuZJBbe/3ek4/nR3A0oAVwZZMNGIH972P7cSZmb/uJXMOQKBgQCs
FaQAL+4sN/TUxrkAkylqF+QJmEZ26l2nrzHZjMWROYNJcsn8/XkaEhD4vGSnazCu
/B0vU6nMppmezF9Mhc112YSrw8QFK5GOc3NGNBoueqMYy1MG8Xcbm1aSMKVv8xba
rh+BZQbxy6x61CpCfaT9hAoA6HaNdeoU6y05lBz1DQKBgAbYiIk56QZHeoZKiZxy
4eicQS0sVKKRb24ZUd+04cNSTfeIuuXZrYJ48Jbr0fzjIM3EfHvLgh9rAZ+aHe/L
84Ig17KiExe+qyYHjut/SC0wODDtzM/jtrpqyYa5JoEpPIaUSgPuTH/WhO3cDsx6
3PIW4/CddNs8mCSBOqTnoaxh
-----END PRIVATE KEY-----''');
  }
}

class Encryption {
  Encryption({
    required this.algorithm,
    this.iterations,
    this.salt,
    this.nonce,
    required this.ciphertext,
    this.gcmTag,
  });

  final String algorithm;
  final String? iterations;
  final String? salt;
  final String? nonce;
  final String ciphertext;
  final String? gcmTag;

  Map toJson() => {
    'algorithm': algorithm,
    'iterations': iterations,
    'salt': salt,
    'nonce': nonce,
    'ciphertext': ciphertext,
    'gcmTag': gcmTag,
  };
}

class User {
  String name;
  String age;

  User(this.name, this.age);

  Map toJson() => {
    'name': name,
    'age': age,
  };
}

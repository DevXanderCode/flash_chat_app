import 'package:flutter/material.dart';
import 'package:flash_chat_app/utilities/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User loggedInUser;
  late String messageText;

  Future<void> sendMessage() async {
    return _firestore
        .collection('messages')
        .add({
          'text': messageText,
          'sender': loggedInUser.email,
        })
        .then((value) => print('message sent'))
        .catchError((error) => print('Failed sending message $error'));
  }

  void getMessages() async {
    final messages = await _firestore.collection('messages').get();
    messages.docs.forEach((doc) => print(doc.data()));
  }

  void messageStream() async {
    await for (var snapshot in _firestore.collection('messages').snapshots()) {
      snapshot.docs.forEach((message) => print(message.data()['text']));
    }
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    // getMessages();
    // messageStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: null,
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                //  implement Logout functionality
                _auth.signOut();
                Navigator.pop(context);
              },
            ),
          ],
          title: const Text('⚡️Chat'),
          backgroundColor: Colors.lightBlueAccent,
        ),
        body: SafeArea(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('messages').snapshots(),
              builder: (context, snapshots) {
                if (!snapshots.hasData) {
                  return Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.lightBlueAccent,
                    ),
                  );
                }
                final messages = snapshots.data?.docs;
                List<Text> messageWidgets = [];
                messages?.forEach((message) {
                  Map<String, dynamic> data =
                      message.data() as Map<String, dynamic>;

                  final messageText = data['text'];
                  final messageSender = data['sender'];

                  final messageWidget =
                      Text('$messageText from $messageSender');

                  messageWidgets.add(messageWidget);
                });
                return Expanded(
                  child: ListView(
                    children: messageWidgets,
                  ),
                );
              },
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  MaterialButton(
                    onPressed: sendMessage,
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            )
          ],
        )));
  }
}

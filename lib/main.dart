import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:footer/footer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SmsQuery _query = SmsQuery();
  List<SmsMessage> _messages = [];
  List<SmsMessage> _searchResult = [];
  TextEditingController controller = new TextEditingController();
  double total = 0;
  List<double> amounts = [];

  Future<Null> getMessages() async {
    var permission = await Permission.sms.status;
    if (permission.isGranted) {
      final messages = await _query.querySms(
        kinds: [SmsQueryKind.inbox, SmsQueryKind.sent],
      );
      debugPrint('sms inbox messages: ${messages.length}');

      setState(() => _messages = messages);
    } else {
      await Permission.sms.request();
    }
  }

  @override
  void initState() {
    super.initState();
    getMessages();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Solve Task'),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: <Widget>[
              Container(
                color: Theme.of(context).primaryColor,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Card(
                    child: ListTile(
                      leading: Icon(Icons.search),
                      title: TextField(
                        controller: controller,
                        decoration: new InputDecoration(
                            hintText: 'Search', border: InputBorder.none),
                        onChanged: onSearchTextChanged,
                      ),
                      trailing: new IconButton(
                        icon: new Icon(Icons.cancel),
                        onPressed: () {
                          controller.clear();
                          onSearchTextChanged('');
                        },
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(5),
                child: Text(
                  'Total  $total AED',
                  style: TextStyle(
                    fontSize: 20,
                  ),
                ),
                height: 30,
              ),
              Container(
                padding: const EdgeInsets.all(10.0),
                height: 800,
                child: controller.text.isNotEmpty || _searchResult.isNotEmpty
                    ? ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResult.length,
                        itemBuilder: (context, int index) {
                          var message = _searchResult[index];
                          String sender = message.sender!;
                          String body = message.body!;
                          String date = message.date!.toString();
                          double amount = checkAmount(body);
                          // bold the words
                          int x = body.indexOf(controller.text);
                          return BottomCards(sender, body, x, controller.text,
                              date, "$amount AED");
                        },
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _messages.length,
                        itemBuilder: (BuildContext context, int index) {
                          var message = _messages[index];
                          String sender = message.sender!;
                          String body = message.body!;
                          String date = message.date!.toString();
                          double amount = checkAmount(body);

                          return BottomCards(
                              sender, body, -1, "", date, "$amount AED");
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void onSearchTextChanged(String text) async {
    _searchResult.clear();
    amounts.clear();
    if (text.isEmpty) {
      setState(() {});
      return;
    }
    _messages.forEach((meesage) {
      if (meesage.body!.toLowerCase().contains(text.toLowerCase())) {
        // print(meesage.body! + " -> " + text);
        _searchResult.add(meesage);
      }
    });
    setState(() {});
  }

  double checkAmount(String text) {
    double amount = 0;
    final regex = RegExp(r'(\d+\.*\d*) AED');
    final match = regex.firstMatch(text);
    String? res1 = match?.group(1);
    if (res1 != null) {
      amount = double.parse(res1);
    } else {
      final regex = RegExp(r'AED (\d+\.*\d*)');
      final match = regex.firstMatch(text);
      String? res2 = match?.group(1);
      if (res2 != null) amount = double.parse(res2);
    }
    amounts.add(amount);
    return amount;
  }
}

class BottomCards extends StatefulWidget {
  final String cardTitle;
  final String cardContent;
  final String date;
  final String amount;
  final int x;
  final String word;
  bool visable = false;

  BottomCards(this.cardTitle, this.cardContent, this.x,this.word, this.date, this.amount);

  @override
  _BottomCardsState createState() => _BottomCardsState();
}

class _BottomCardsState extends State<BottomCards> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onTap: () {},
          child: Container(
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Row(
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            widget.cardTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(widget.date),
                          Text(widget.amount),
                        ],
                      ),
                      Spacer(),
                      new ButtonBar(
                        children: <Widget>[
                          IconButton(
                            icon: widget.visable
                                ? Icon(Icons.visibility)
                                : Icon(Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                widget.visable = !widget.visable;
                              });
                              print(widget.visable);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  Visibility(
                    child: Container(
                      color: Colors.grey[100],
                      child: Padding(
                        padding: EdgeInsets.all(5),
                        child: this.widget.x == -1
                            ? Text(
                                widget.cardContent,
                              )
                            : RichText(
                                text: TextSpan(children: []),
                              ),
                      ),
                    ),
                    visible: widget.visable,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

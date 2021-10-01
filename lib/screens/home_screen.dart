import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:free_conf/components/home/home_bottom_icon_component.dart';
import 'package:free_conf/models/Reservation.dart';
import 'package:free_conf/utils/date_time_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<int> _calendarHours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];
  static final String _collectionName =
      "reservation-${DateTime.now().day}${DateTime.now().month}${DateTime.now().year}";
  static final CollectionReference _reservationCollection =
      FirebaseFirestore.instance.collection(_collectionName);
  static final Stream<QuerySnapshot> _reservationCollectionStream =
      _reservationCollection.snapshots();

  Future _showManageAccount(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? accountName = prefs.getString("accountName");

    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Put your name here:"),
            content: Row(children: [
              Expanded(
                  child: TextFormField(
                initialValue: accountName,
                onChanged: (value) {
                  accountName = value;
                },
              ))
            ]),
            actions: [
              TextButton(
                  onPressed: () async {
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setString("accountName", accountName!);

                    Navigator.of(context).pop();
                  },
                  child: const Text("Save"))
            ],
          );
        });
  }

  Future<void> _addReservation(int dateFrom) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? accountName = pref.getString("accountName");

    if (accountName?.isNotEmpty == true) {
      return _reservationCollection
          .add({
            "room": _selectedIndex,
            "name": pref.getString("accountName"),
            "dateFrom": dateFrom,
            "dateTo": dateFrom + 1
          })
          .then((value) => print("Reserved"))
          .catchError((error) => print("Failed to reservation"));
    }
  }

  Future<void> _removeReservation(Reservation reservation) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    String? accountName = pref.getString("accountName");

    if (accountName?.isNotEmpty == true && accountName == reservation.owner) {
      return _reservationCollection
          .doc(reservation.id)
          .delete()
          .then((value) => print("Deleted"))
          .catchError((error) => print("Failed to deletion"));
    }
  }

  void _changeConferenceRoom(int value) {
    setState(() {
      _selectedIndex = value;
    });
  }

  List<List<Reservation>> _generateCalendar(
      AsyncSnapshot<QuerySnapshot> snapshot) {
    final _calendar = List.generate(
        3, (i) => List.generate(11, (j) => Reservation(id: "", owner: "")));

    snapshot.data?.docs.forEach((DocumentSnapshot document) {
      Map<String, dynamic> data = document.data()! as Map<String, dynamic>;
      String id = document.id;
      int roomNumber = data["room"];
      int dateFrom = data["dateFrom"];
      int dateTo = data["dateTo"];
      String name = data["name"];
      int dateDiff = dateTo - dateFrom;

      for (var i = 0; i < dateDiff; ++i) {
        _calendar[roomNumber][dateFrom + i - 8] =
            Reservation(id: id, owner: name);
      }
    });

    return _calendar;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _reservationCollectionStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Container(
              color: Colors.white,
              child: const Center(
                  child: Text('Something went wrong with Firestore...')));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
              color: Colors.white,
              child: const Center(child: CircularProgressIndicator()));
        }

        final _calendar = _generateCalendar(snapshot);

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.title),
            actions: [
              IconButton(
                  icon: const Icon(Icons.manage_accounts),
                  onPressed: () async {
                    await _showManageAccount(context);
                  })
            ],
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount:
                _calendarHours.isNotEmpty ? _calendarHours.length + 1 : 0,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Center(
                    child: Text(
                  DateTimeUtils.getDateHeader(),
                  style: const TextStyle(fontSize: 16),
                ));
              }

              index -= 1;
              int itemHour = _calendarHours[index];
              TextStyle textStyle = TextStyle(
                  fontWeight: itemHour == DateTime.now().hour
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: itemHour < DateTime.now().hour
                      ? Colors.black45
                      : Colors.black);

              if (_calendar[_selectedIndex][index].owner.isEmpty) {
                return GestureDetector(
                    child: Container(
                      height: 34,
                      padding: const EdgeInsets.only(left: 8),
                      child: Text("$itemHour:00", style: textStyle),
                    ),
                    onDoubleTap: () async {
                      await _addReservation(itemHour);
                    });
              }
              return GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.only(left: 8),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text("$itemHour:00",
                                style: textStyle, textAlign: TextAlign.justify),
                          ),
                          Expanded(
                              flex: 2,
                              child: Text(
                                  _calendar[_selectedIndex][index].owner,
                                  style: textStyle))
                        ]),
                  ),
                  onDoubleTap: () async {
                    await _removeReservation(_calendar[_selectedIndex][index]);
                  });
            },
            separatorBuilder: (BuildContext context, int index) =>
                const Divider(),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                  label: "Sagiton",
                  icon: HomeBottomIcon(calendar: _calendar[0])),
              BottomNavigationBarItem(
                  label: "Zebra", icon: HomeBottomIcon(calendar: _calendar[1])),
              BottomNavigationBarItem(
                  label: "Wspólna",
                  icon: HomeBottomIcon(calendar: _calendar[2]))
            ],
            currentIndex: _selectedIndex,
            onTap: _changeConferenceRoom,
          ),
        );
      },
    );
  }
}

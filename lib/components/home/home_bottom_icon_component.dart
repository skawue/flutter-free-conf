import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:free_conf/models/Reservation.dart';

class HomeBottomIcon extends StatelessWidget {
  const HomeBottomIcon({Key? key, required this.calendar}) : super(key: key);

  final List<Reservation> calendar;

  bool _isRoomOccupied() {
    int _currentHour = DateTime.now().hour;

    if (_currentHour < 8 || _currentHour > 18) {
      return false;
    }

    return calendar[DateTime.now().hour - 8].owner.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      const Icon(Icons.meeting_room),
      Positioned(
          top: 0,
          right: 0,
          child: Icon(Icons.brightness_1,
              color: _isRoomOccupied() ? Colors.red : Colors.green, size: 10))
    ]);
  }
}

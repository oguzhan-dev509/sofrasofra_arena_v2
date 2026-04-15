import 'package:flutter/material.dart';

import '../modules/user_reservations_page.dart';
import '../modules/create_reservation_page.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      AnaSayfa(),
      UserReservationsPage(),
      const CreateReservationPage(
        chefId: 'RhkyTCD5TgWJFdEzP50mvCOrz5a2',
        chefName: 'Ahmet Usta',
        tableTitle: 'Şef Masası',
        concept: 'Tadım Menüsü',
        capacity: '8',
        unitPrice: 1500,
      ),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFFFD54F),
        unselectedItemColor: Colors.white54,
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Menü',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Rezervasyonlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Rezervasyon',
          ),
        ],
      ),
    );
  }
}

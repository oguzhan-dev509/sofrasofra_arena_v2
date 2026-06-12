import 'package:flutter/material.dart';
import 'package:sofrasofra_arena_v2/modules/radyo/sofrasofra_radyo_bolumu.dart';

class RadyoMerkeziSayfasi extends StatelessWidget {
  const RadyoMerkeziSayfasi({super.key});

  static const Color _bg = Color(0xFF090909);
  static const Color _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        iconTheme: IconThemeData(color: _gold),
        title: Text(
          'Sofrasofra Radyo',
          style: TextStyle(
            color: _gold,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: SofrasofraRadyoBolumu(),
      ),
    );
  }
}

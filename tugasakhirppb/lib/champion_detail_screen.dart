// champion_detail_screen.dart

import 'package:flutter/material.dart';

class ChampionDetailScreen extends StatelessWidget {
  final dynamic champion;
  final int level;

  const ChampionDetailScreen(
      {super.key, required this.champion, this.level = 1});

  // Fungsi untuk mendapatkan nilai dari "variables" berdasarkan nama
  double getAbilityVariable(String name) {
    final variable = champion['ability']['variables']
        .firstWhere((v) => v['name'] == name, orElse: () => null);
    if (variable != null && level < variable['value'].length) {
      return variable['value'][level];
    }
    return 0; // Jika tidak ditemukan, kembalikan nilai 0
  }

  // Fungsi dinamis untuk membangun deskripsi kemampuan berdasarkan variabel yang ada
  String buildAbilityDescription(String description) {
    // Loop melalui semua variabel dan ganti setiap placeholder dalam deskripsi
    for (var variable in champion['ability']['variables']) {
      String name = variable['name'];
      double value = getAbilityVariable(name);

      // Debugging log untuk memastikan penggantian placeholder
      print("Replacing @$name@ with value $value");

      // Format nilai variabel jika perlu (misalnya, gunakan satuan AP jika relevan)
      String formattedValue = name.contains('Damage') ||
              name.contains('AP') ||
              name.contains('Heal')
          ? '${value.toStringAsFixed(0)}/AP' // Tambahkan "AP" untuk variabel terkait
          : value.toStringAsFixed(0);

      // Gantikan placeholder di deskripsi
      description = description.replaceAll('@$name@', formattedValue);
    }

    // Hapus markup seperti <magicDamage>, <scaleHealth>, <TFTKeyword>
    description = description.replaceAll(RegExp(r'<[^>]+>'), ' ');
    description = description.replaceAll(RegExp('&nbsp;'), ' ');
    description = description.replaceAll(RegExp('(%i:scaleAP%)'), ' ');
    description = description.replaceAll(RegExp('(%i:scaleAD%)'), ' ');

    // Debugging log untuk output akhir deskripsi
    print("Final ability description: $description");

    return description;
  }

  @override
  Widget build(BuildContext context) {
    final stats = champion['stats'];
    final ability = champion['ability'];
    final abilityDescription =
        buildAbilityDescription(ability['desc'] ?? 'No description available');

    return Scaffold(
      appBar: AppBar(
        title: Text(champion['name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Traits: ${champion['traits']?.join(", ")}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              const Text(
                'Stats:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Card(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HP: ${stats['hp']}'),
                      Text('Armor: ${stats['armor']}'),
                      Text('Magic Resist: ${stats['magicResist']}'),
                      Text('Damage: ${stats['damage']}'),
                      Text('Attack Speed: ${stats['attackSpeed']}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ability: ${ability['name']}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                abilityDescription,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

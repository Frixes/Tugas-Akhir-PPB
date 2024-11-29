import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // Import cache manager
import 'champion_detail_screen.dart';

class HeroesScreen extends StatefulWidget {
  const HeroesScreen({super.key});

  @override
  _HeroesScreenState createState() => _HeroesScreenState();
}

class _HeroesScreenState extends State<HeroesScreen> {
  Map<int, List<dynamic>> _groupedChampions = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChampions();
  }

  Future<void> _fetchChampions() async {
    const url = 'https://raw.communitydragon.org/latest/cdragon/tft/en_sg.json';

    try {
      // Menggunakan cache manager
      final cacheManager = DefaultCacheManager();
      final file = await cacheManager.getSingleFile(url);

      // Membaca data dari cache (jika tersedia)
      final response = await file.readAsString();
      final data = json.decode(response);

      // Akses champions dari data JSON pada set '12'
      List<dynamic> champions = data['sets']['13']['champions'] ?? [];
      champions = champions
          .where((champion) =>
              champion['characterName'].toString().contains('TFT13_') &&
              (champion['traits']?.isNotEmpty ?? false)) // Filter `traits`
          .toList();

      // Kelompokkan champion berdasarkan `cost`
      final groupedChampions = <int, List<dynamic>>{};
      for (var champion in champions) {
        int cost = champion['cost'];
        if (!groupedChampions.containsKey(cost)) {
          groupedChampions[cost] = [];
        }
        groupedChampions[cost]?.add(champion);
      }

      setState(() {
        _groupedChampions = groupedChampions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching champions: $e');
    }
  }

  String _getChampionIconUrl(String characterName) {
    // Membentuk URL gambar dengan format yang benar
    final formattedName = characterName.toLowerCase();
    if (formattedName == "tft13_twitch") {
      return 'https://raw.communitydragon.org/latest/game/assets/characters/$formattedName/skins/base/images/${formattedName}__mobile.tft_set13.png';
    } else {
      return 'https://raw.communitydragon.org/latest/game/assets/characters/$formattedName/skins/base/images/${formattedName}_mobile.tft_set13.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Heroes'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: (() {
                // Mengonversi dan mengurutkan entri berdasarkan `cost`
                final sortedEntries = _groupedChampions.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key));

                // Mengonversi hasil sortedEntries menjadi List<Widget>
                return sortedEntries.map<Widget>((entry) {
                  final cost = entry.key;
                  final champions = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Cost $cost',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...champions.map((champion) {
                        final championName = champion['name'];
                        final championTraits = champion['traits']?.join(", ");
                        final championIconUrl =
                            _getChampionIconUrl(champion['characterName']);

                        return ListTile(
                          leading: Image.network(
                            championIconUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          ),
                          title: Text(championName),
                          subtitle: Text('Traits: $championTraits'),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChampionDetailScreen(champion: champion),
                              ),
                            );
                          },
                        );
                      }),
                    ],
                  );
                }).toList();
              })(), // Panggil sebagai List<Widget>
            ),
    );
  }
}

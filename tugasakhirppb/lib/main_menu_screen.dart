import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'player_detail_screen.dart';
import 'dart:async';
import 'profile_screen.dart';

class MainMenuScreen extends StatefulWidget {
  @override
  _MainMenuScreenState createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _leaderboard = [];
  List<Map<String, dynamic>> _searchResults = [];
  final String _apiKey = 'RGAPI-117e7b59-da0d-4b91-a0a4-d94560ac1003';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.isNotEmpty) {
        _searchPlayerByRiotId(_searchController.text);
      } else {
        setState(() {
          _searchResults.clear();
        });
      }
    });
  }

  Future<void> _fetchLeaderboard() async {
    final leaderboardUrl =
        'https://sg2.api.riotgames.com/tft/league/v1/challenger?queue=RANKED_TFT';

    final response = await http.get(
      Uri.parse(leaderboardUrl),
      headers: {'X-Riot-Token': _apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final entries = data['entries'] as List<dynamic>;

      List<Map<String, dynamic>> players = [];

      for (var entry in entries) {
        final summonerId = entry['summonerId'];
        final rankInfo = {
          'rank': entry['rank'],
          'leaguePoints': entry['leaguePoints'],
          'summonerId': summonerId,
        };
        final playerData =
            await _fetchSummonerGameNameAndPuuid(summonerId, rankInfo);
        if (playerData != null) {
          players.add(playerData);
        }
      }

      if (mounted) {
        setState(() {
          _leaderboard = players;
        });
      }
    } else {
      print('Failed to fetch leaderboard');
    }
  }

  Future<Map<String, dynamic>?> _fetchSummonerGameNameAndPuuid(
      String summonerId, Map<String, dynamic> rankInfo) async {
    final summonerUrl =
        'https://sg2.api.riotgames.com/tft/summoner/v1/summoners/$summonerId';

    final summonerResponse = await http.get(
      Uri.parse(summonerUrl),
      headers: {'X-Riot-Token': _apiKey},
    );

    if (summonerResponse.statusCode == 200) {
      final summonerData = json.decode(summonerResponse.body);
      final puuid = summonerData['puuid'];

      final accountUrl =
          'https://asia.api.riotgames.com/riot/account/v1/accounts/by-puuid/$puuid';
      final accountResponse = await http.get(
        Uri.parse(accountUrl),
        headers: {'X-Riot-Token': _apiKey},
      );

      if (accountResponse.statusCode == 200) {
        final accountData = json.decode(accountResponse.body);
        return {
          'gameName': accountData['gameName'],
          'tagLine': accountData['tagLine'],
          'tier': rankInfo['rank'],
          'leaguePoints': rankInfo['leaguePoints'],
          'summonerId': summonerId,
          'puuid': puuid,
        };
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchPlayerRanks(
      String summonerId) async {
    final rankUrl =
        'https://sg2.api.riotgames.com/tft/league/v1/entries/by-summoner/$summonerId';

    final response = await http.get(
      Uri.parse(rankUrl),
      headers: {'X-Riot-Token': _apiKey},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    print('Failed to fetch rank data. Status Code: ${response.statusCode}');
    return [];
  }

  Future<void> _searchPlayerByRiotId(String query) async {
    final parts = query.split('#');
    if (parts.length != 2) {
      print('Invalid input format. Use GameName#TagLine.');
      if (mounted) {
        setState(() {
          _searchResults.clear();
        });
      }
      return;
    }

    final gameName = parts[0];
    final tagLine = parts[1];

    final searchUrl =
        'https://asia.api.riotgames.com/riot/account/v1/accounts/by-riot-id/$gameName/$tagLine';

    final response = await http.get(
      Uri.parse(searchUrl),
      headers: {'X-Riot-Token': _apiKey},
    );

    if (response.statusCode == 200) {
      final accountData = json.decode(response.body);
      final puuid = accountData['puuid'];

      if (mounted) {
        setState(() {
          _searchResults = [
            {
              'gameName': accountData['gameName'],
              'tagLine': accountData['tagLine'],
              'puuid': puuid,
            }
          ];
        });
      }
    } else {
      print('Failed to find player. Status Code: ${response.statusCode}');
      if (mounted) {
        setState(() {
          _searchResults.clear();
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildMainMenu() {
    return Column(
      children: [
        // Single Search Bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search GameName#TagLine',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 10),

        // Search Results
        if (_searchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  title: Text('${result['gameName']}#${result['tagLine']}'),
                  onTap: () async {
                    final ranks = await _fetchPlayerRanks(result['puuid']);
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerDetailScreen(
                          puuid: result['puuid'],
                          gameName: result['gameName'],
                          tagLine: result['tagLine'],
                          ranks: ranks,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

        // Leaderboard Section
        Expanded(
          child: _leaderboard.isEmpty
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _leaderboard.length,
                  itemBuilder: (context, index) {
                    final player = _leaderboard[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${index + 1}')),
                      title: Text('${player['gameName']}#${player['tagLine']}'),
                      subtitle: Text(
                          'Rank: ${player['tier']} - LP: ${player['leaguePoints']}'),
                      onTap: () async {
                        final ranks =
                            await _fetchPlayerRanks(player['summonerId']);
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerDetailScreen(
                              puuid: player['puuid'],
                              gameName: player['gameName'],
                              tagLine: player['tagLine'],
                              ranks: ranks,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 0 ? _buildMainMenu() : ProfileScreen(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Main Menu',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

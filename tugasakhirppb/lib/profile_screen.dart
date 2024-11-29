import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tugasakhirppb/player_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _gameNameController = TextEditingController();
  final TextEditingController _tagLineController = TextEditingController();

  String _gameName = 'Player Name';
  String _tagLine = 'Tagline';
  String? _puuid;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _rankData;
  String? _rankIconUrl; // Variable to store rank icon URL

  final String _apiKey = 'RGAPI-a624b0e3-fe5b-4ffc-8ef4-9de1e4c4d36c';
  static Map<String, Map<String, String>> _rankIconDataCache = {};

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _gameNameController.dispose();
    _tagLineController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _gameName = prefs.getString('gameName') ?? 'Player Name';
      _tagLine = prefs.getString('tagLine') ?? 'Tagline';
    });
    if (_gameName.isNotEmpty && _tagLine.isNotEmpty) {
      await _fetchPuuid();
    }
  }

  Future<void> _saveProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('gameName', _gameName);
    await prefs.setString('tagLine', _tagLine);
  }

  void _showEditDialog() {
    _gameNameController.text = _gameName;
    _tagLineController.text = _tagLine;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _gameNameController,
                decoration: InputDecoration(labelText: 'Game Name'),
              ),
              TextField(
                controller: _tagLineController,
                decoration: InputDecoration(labelText: 'Tagline'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _gameName = _gameNameController.text.trim();
                  _tagLine = _tagLineController.text.trim();
                });

                if (_gameName.isEmpty || _tagLine.isEmpty) {
                  setState(() {
                    _errorMessage = 'Game name and Tagline cannot be empty';
                  });
                  return;
                }

                await _saveProfileData();
                await _fetchPuuid();
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchPuuid() async {
    final apiUrl =
        'https://asia.api.riotgames.com/riot/account/v1/accounts/by-riot-id/$_gameName/$_tagLine';
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'X-Riot-Token': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _puuid = data['puuid'];
        });
        final summonerId = await _fetchSummonerIdByPuuid(_puuid!);
        if (summonerId != null) {
          await _fetchRankIconData(); // Load rank icons first
          await _fetchPlayerRanks(summonerId);
        }
      } else {
        setState(() {
          _errorMessage =
              'Failed to find player. Please check Game Name and Tagline.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching player data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String?> _fetchSummonerIdByPuuid(String puuid) async {
    final summonerIdUrl =
        'https://sg2.api.riotgames.com/tft/summoner/v1/summoners/by-puuid/$puuid';

    final response = await http.get(
      Uri.parse(summonerIdUrl),
      headers: {'X-Riot-Token': _apiKey},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['id'];
    } else {
      return null;
    }
  }

  Future<void> _fetchRankIconData() async {
    if (_rankIconDataCache.isNotEmpty) return;

    final rankDataUrl =
        'https://ddragon.leagueoflegends.com/cdn/14.21.1/data/en_SG/tft-regalia.json';
    final response = await http.get(Uri.parse(rankDataUrl));

    if (response.statusCode == 200) {
      final rankData =
          json.decode(response.body)['data'] as Map<String, dynamic>;
      _rankIconDataCache = {
        for (var rankType in rankData.keys)
          rankType: {
            for (var tier in rankData[rankType].keys)
              tier: rankData[rankType][tier]['image']['full'] as String
          }
      };
      print('Rank icon data cached successfully: $_rankIconDataCache');
    } else {
      print(
          'Failed to fetch rank icon data. Status Code: ${response.statusCode}');
    }
  }

  Future<void> _fetchPlayerRanks(String summonerId) async {
    final rankUrl =
        'https://sg2.api.riotgames.com/tft/league/v1/entries/by-summoner/$summonerId';

    try {
      final response = await http.get(
        Uri.parse(rankUrl),
        headers: {'X-Riot-Token': _apiKey},
      );

      if (response.statusCode == 200) {
        final rankData =
            List<Map<String, dynamic>>.from(json.decode(response.body));
        final rankedTftData = rankData.firstWhere(
          (rank) => rank['queueType'] == 'RANKED_TFT',
          orElse: () => {},
        );

        // Set the rank data and icon URL based on the tier and rank
        setState(() {
          _rankData = rankedTftData.isNotEmpty ? rankedTftData : null;

          if (_rankData != null) {
            String queueType = _rankData!['queueType'];
            // Capitalize the tier name to match the keys in _rankIconDataCache
            String tier = _rankData!['tier'].toString().capitalize();

            if (_rankIconDataCache[queueType]?.containsKey(tier) == true) {
              String iconFileName = _rankIconDataCache[queueType]![tier]!;
              _rankIconUrl =
                  'https://ddragon.leagueoflegends.com/cdn/14.21.1/img/tft-regalia/$iconFileName';
              print(
                  "Constructed Rank Icon URL: $_rankIconUrl"); // Final debug output for URL
            } else {
              _rankIconUrl = null;
              print("Icon for $queueType with tier $tier not found in cache.");
            }
          }
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch rank data. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching rank data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: const Color.fromARGB(255, 222, 218, 228),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple[50],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/icon-tft-512.png'),
                    ),
                    SizedBox(height: 20),
                    Text(
                      _gameName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple[800],
                      ),
                    ),
                    Text(
                      '#$_tagLine',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 20),
                    _isLoading
                        ? CircularProgressIndicator()
                        : _rankData != null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_rankIconUrl != null)
                                    Image.network(
                                      _rankIconUrl!,
                                      width: 50,
                                      height: 50,
                                      errorBuilder: (context, error,
                                              stackTrace) =>
                                          Icon(Icons.error, color: Colors.red),
                                    ),
                                  SizedBox(height: 10),
                                  Text(
                                    'RANKED_TFT: ${_rankData!['tier']} ${_rankData!['rank'] ?? ''} - ${_rankData!['leaguePoints'] ?? 0} LP',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.deepPurple[800],
                                    ),
                                  ),
                                ],
                              )
                            : _errorMessage != null
                                ? Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  )
                                : Text(
                                    'No rank data available for RANKED_TFT.',
                                    textAlign: TextAlign.center,
                                  ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showEditDialog,
                      child: Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        backgroundColor:
                            const Color.fromARGB(255, 209, 194, 235),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

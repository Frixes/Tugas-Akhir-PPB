import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'app_styles.dart'; // Import file styles

class PlayerDetailScreen extends StatelessWidget {
  final String puuid;
  final String gameName;
  final String tagLine;

  const PlayerDetailScreen({
    super.key,
    required this.puuid,
    required this.gameName,
    required this.tagLine,
    required List<Map<String, dynamic>> ranks,
  });

  final String _apiKey = 'RGAPI-a624b0e3-fe5b-4ffc-8ef4-9de1e4c4d36c';

  // Cache for trait and rank data
  static Map<String, String> _traitIconDataCache = {};
  static Map<String, Map<String, String>> _rankIconDataCache = {};

  // Fetch details for a specific match
  Future<Map<String, dynamic>> _fetchMatchDetails(String matchId) async {
    final matchDetailsUrl =
        'https://sea.api.riotgames.com/tft/match/v1/matches/$matchId';

    final response = await http.get(
      Uri.parse(matchDetailsUrl),
      headers: {'X-Riot-Token': _apiKey},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return {};
    }
  }

  // Fetch trait icon data
  Future<void> _fetchTraitIconData() async {
    if (_traitIconDataCache.isNotEmpty) return;

    final traitDataUrl =
        'https://ddragon.leagueoflegends.com/cdn/14.23.1/data/en_SG/tft-trait.json';
    final response = await http.get(Uri.parse(traitDataUrl));

    if (response.statusCode == 200) {
      final traitData =
          json.decode(response.body)['data'] as Map<String, dynamic>;
      _traitIconDataCache = {
        for (var entry in traitData.entries)
          entry.key: entry.value['image']['full']
      };
    } else {
      print(
          'Failed to fetch trait icon data. Status Code: ${response.statusCode}');
    }
  }

  // Fetch rank icon data
  Future<void> _fetchRankIconData() async {
    if (_rankIconDataCache.isNotEmpty) return;

    final rankDataUrl =
        'https://ddragon.leagueoflegends.com/cdn/14.23.1/data/en_SG/tft-regalia.json';
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

  // Get trait icon URL from cache
  String _getTraitIconUrl(String traitName) {
    if (_traitIconDataCache.containsKey(traitName)) {
      return 'https://ddragon.leagueoflegends.com/cdn/14.23.1/img/tft-trait/${_traitIconDataCache[traitName]}';
    }
    return 'https://ddragon.leagueoflegends.com/cdn/14.23.1/img/tft-trait/default.png';
  }

  // Get rank icon URL based on rank type and tier
  String _getRankIconUrl(String rankType, String tier) {
    String iconFileName;
    if (rankType == "RANKED_TFT_TURBO") {
      iconFileName = 'PostGameScene_RatedIcon_${tier.capitalize()}.png';
    } else {
      iconFileName = 'TFT_Regalia_${tier.capitalize()}.png';
    }

    return 'https://ddragon.leagueoflegends.com/cdn/14.23.1/img/tft-regalia/$iconFileName';
  }

  // Dynamically construct champion icon URL
  String _getChampionIconUrl(String championId) {
    if (championId.startsWith("TFT13_")) {
      return 'https://ddragon.leagueoflegends.com/cdn/14.23.1/img/tft-champion/$championId.TFT_Set13.png';
    }
    return 'https://ddragon.leagueoflegends.com/cdn/14.23.1/img/tft-champion/$championId.png';
  }

  String _getChampionIconUrl2(String characterName) {
    // Membentuk URL gambar dengan format yang benar
    final formattedName = characterName.toLowerCase();
    if (formattedName == "tft13_sion") {
      return 'https://raw.communitydragon.org/latest/game/assets/characters/tft13_sion/skins/base/images/tft13_sion_splash_tile_0_mobile.tft_set13.png';
    } else if (formattedName == "tft13_twitch") {
      return 'https://raw.communitydragon.org/latest/game/assets/characters/tft13_twitch/skins/base/images/tft13_twitch__mobile.tft_set13.png';
    } else {
      return 'https://raw.communitydragon.org/latest/game/assets/characters/$formattedName/skins/base/images/${formattedName}_mobile.tft_set13.png';
    }
  }

  // Fetch the player's rank types
  Future<List<Map<String, dynamic>>> _fetchPlayerRanks() async {
    final summonerId = await _fetchSummonerId();
    final rankUrl =
        'https://sg2.api.riotgames.com/tft/league/v1/entries/by-summoner/$summonerId';

    final response = await http.get(
      Uri.parse(rankUrl),
      headers: {'X-Riot-Token': _apiKey},
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      return [];
    }
  }

  // Fetch the summoner ID using puuid
  Future<String> _fetchSummonerId() async {
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
      throw Exception('Failed to fetch summoner ID');
    }
  }

  // Fetch the last 10 matches using puuid
  Future<List<String>> _fetchMatchHistory() async {
    final matchHistoryUrl =
        'https://sea.api.riotgames.com/tft/match/v1/matches/by-puuid/$puuid/ids?count=10';

    final response = await http.get(
      Uri.parse(matchHistoryUrl),
      headers: {'X-Riot-Token': _apiKey},
    );

    if (response.statusCode == 200) {
      return List<String>.from(json.decode(response.body));
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: Future.wait([
        _fetchTraitIconData(),
        _fetchRankIconData(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child:
                  Text('Failed to load data', style: AppStyles.errorTextStyle));
        } else {
          return Scaffold(
            appBar: AppBar(
              title: Text('$gameName#$tagLine'),
            ),
            body: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchPlayerRanks(),
              builder: (context, rankSnapshot) {
                if (rankSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (rankSnapshot.hasError ||
                    rankSnapshot.data == null ||
                    rankSnapshot.data!.isEmpty) {
                  return Center(
                      child: Text('Failed to load rank data',
                          style: AppStyles.errorTextStyle));
                } else {
                  final rankData = rankSnapshot.data!;
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        ...rankData.map((rank) {
                          final rankType = rank['queueType'];
                          final tier = rankType == 'RANKED_TFT_TURBO'
                              ? rank['ratedTier']
                              : rank['tier'];
                          final iconUrl = _getRankIconUrl(rankType, tier);
                          final rankDisplay = rankType == 'RANKED_TFT_TURBO'
                              ? '$rankType: ${rank['ratedTier']} - ${rank['ratedRating']} Rating'
                              : '$rankType: ${rank['tier']} ${rank['rank']} - ${rank['leaguePoints']} LP';

                          return Card(
                            margin: AppStyles.cardMargin,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: AppStyles.cardPadding,
                              child: Row(
                                children: [
                                  Image.network(
                                    iconUrl,
                                    width: AppStyles.iconSize,
                                    height: AppStyles.iconSize,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                            Icons.image,
                                            size: AppStyles.iconSize),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(rankDisplay,
                                        style: AppStyles.rankTextStyle),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        SizedBox(height: 20),
                        FutureBuilder<List<String>>(
                          future: _fetchMatchHistory(),
                          builder: (context, matchSnapshot) {
                            if (matchSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (matchSnapshot.hasError ||
                                !matchSnapshot.hasData ||
                                matchSnapshot.data!.isEmpty) {
                              return Center(
                                  child: Text('Failed to load match history',
                                      style: AppStyles.errorTextStyle));
                            } else {
                              final matchIds = matchSnapshot.data!;
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: matchIds.length,
                                itemBuilder: (context, index) {
                                  final matchId = matchIds[index];
                                  return FutureBuilder<Map<String, dynamic>>(
                                    future: _fetchMatchDetails(matchId),
                                    builder: (context, matchDetailSnapshot) {
                                      if (matchDetailSnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      } else if (matchDetailSnapshot.hasError ||
                                          matchDetailSnapshot.data == null) {
                                        return ListTile(
                                          title: Text(
                                              'Failed to load match details',
                                              style: AppStyles.errorTextStyle),
                                        );
                                      } else {
                                        final matchData =
                                            matchDetailSnapshot.data!;
                                        final playerData = matchData['info']
                                                ['participants']
                                            .firstWhere((participant) =>
                                                participant['puuid'] == puuid);

                                        return Card(
                                          margin: AppStyles.cardMargin,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Padding(
                                            padding: AppStyles.cardPadding,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Ranked TFT Match ${index + 1}',
                                                  style:
                                                      AppStyles.titleTextStyle,
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                    'Placement: ${playerData['placement']}'),
                                                SizedBox(height: 8),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text('Traits:',
                                                        style: AppStyles
                                                            .rankTextStyle),
                                                    SizedBox(height: 8),
                                                    Wrap(
                                                      spacing: 4,
                                                      runSpacing: 4,
                                                      children:
                                                          playerData['traits']
                                                              .map<Widget>(
                                                                  (trait) {
                                                        final traitIconUrl =
                                                            _getTraitIconUrl(
                                                                trait['name']);
                                                        return Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.black
                                                                .withOpacity(
                                                                    0.6), // Darker background
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8), // Rounded corners
                                                          ),
                                                          padding: EdgeInsets.all(
                                                              4), // Padding around the icon
                                                          child: Image.network(
                                                            traitIconUrl,
                                                            width: AppStyles
                                                                .smallIconSize,
                                                            height: AppStyles
                                                                .smallIconSize,
                                                            errorBuilder: (context,
                                                                    error,
                                                                    stackTrace) =>
                                                                Icon(
                                                                    Icons.image,
                                                                    size: AppStyles
                                                                        .smallIconSize),
                                                          ),
                                                        );
                                                      }).toList(),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Text('Units:',
                                                    style: AppStyles
                                                        .rankTextStyle),
                                                SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: playerData['units']
                                                      .map<Widget>((unit) {
                                                    final championIconUrl =
                                                        _getChampionIconUrl2(
                                                            unit[
                                                                'character_id']);

                                                    return Column(
                                                      children: [
                                                        Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border.all(
                                                                width: AppStyles
                                                                    .unitIconBorderWidth),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                          ),
                                                          child: ClipRRect(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8),
                                                            child:
                                                                Image.network(
                                                              championIconUrl,
                                                              width: AppStyles
                                                                  .unitIconSize,
                                                              height: AppStyles
                                                                  .unitIconSize,
                                                              errorBuilder: (context,
                                                                      error,
                                                                      stackTrace) =>
                                                                  Icon(
                                                                      Icons
                                                                          .image,
                                                                      size: AppStyles
                                                                          .unitIconSize),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(height: 4),
                                                        Text(
                                                          unit['character_id']
                                                              .replaceFirst(
                                                                  'TFT13_', ''),
                                                          style: AppStyles
                                                              .subtitleTextStyle,
                                                        ),
                                                      ],
                                                    );
                                                  }).toList(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          );
        }
      },
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

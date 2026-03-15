const String bhamReplayCityCode = 'bham';
const int bhamReplayBaseYear = 2023;

const Map<String, String> bhamLocalityDisplayNames = <String, String>{
  'bham_downtown': 'Downtown',
  'bham_southside': 'Southside',
  'bham_uptown': 'Uptown',
  'bham_avondale': 'Avondale',
  'bham_five_points': 'Five Points South',
  'bham_lakeview': 'Lakeview',
  'bham_woodlawn': 'Woodlawn',
  'bham_homewood': 'Homewood',
};

String displayNameForBhamLocality(String localityCode) {
  return bhamLocalityDisplayNames[localityCode] ?? localityCode;
}

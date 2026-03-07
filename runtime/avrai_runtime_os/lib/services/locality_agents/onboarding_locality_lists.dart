/// Curated locality lists for onboarding, sourced from real OpenStreetMap data.
///
/// Provides static city-specific lists (NYC, Denver, Atlanta) organized into
/// food, events, and activities categories. Used during onboarding to seed
/// the user's initial locality feed based on their homebase selection.
class OnboardingLocalityLists {
  OnboardingLocalityLists._();

  /// Resolves a user-facing location name to an internal city key.
  ///
  /// Maps borough/neighborhood names to their parent metro area.
  /// Falls back to `'nyc'` when no match is found.
  static String resolveCity(String? locationName) {
    if (locationName == null || locationName.isEmpty) return 'nyc';
    final lower = locationName.toLowerCase();

    const nycTokens = [
      'new york',
      'brooklyn',
      'manhattan',
      'queens',
      'bronx',
      'staten island',
    ];
    for (final token in nycTokens) {
      if (lower.contains(token)) return 'nyc';
    }

    const denverTokens = ['denver', 'aurora', 'lakewood', 'boulder'];
    for (final token in denverTokens) {
      if (lower.contains(token)) return 'denver';
    }

    const atlantaTokens = ['atlanta', 'decatur', 'marietta', 'buckhead'];
    for (final token in atlantaTokens) {
      if (lower.contains(token)) return 'atlanta';
    }

    const birminghamTokens = [
      'birmingham',
      'homewood',
      'avondale',
      'five points',
      'mountain brook',
    ];
    for (final token in birminghamTokens) {
      if (lower.contains(token)) return 'birmingham';
    }

    return 'nyc';
  }

  /// Returns curated lists for the given [cityName] key.
  ///
  /// Valid keys: `'nyc'`, `'denver'`, `'atlanta'`.
  /// Returns an empty list for unknown cities.
  static List<Map<String, dynamic>> getListsForCity(String cityName) {
    switch (cityName) {
      case 'nyc':
        return _nycLists;
      case 'denver':
        return _denverLists;
      case 'atlanta':
        return _atlantaLists;
      case 'birmingham':
        return _birminghamLists;
      default:
        return <Map<String, dynamic>>[];
    }
  }

  /// Returns NYC lists as the default.
  static List<Map<String, dynamic>> getDefaultLists() => _nycLists;

  // ---------------------------------------------------------------------------
  // NYC
  // ---------------------------------------------------------------------------

  static final List<Map<String, dynamic>> _nycLists = [
    {
      'name': 'Best Pizza in NYC',
      'creator': 'avrai food agent',
      'spots': 8,
      'respects': 487,
      'category': 'Food & Drink',
      'location': 'New York, NY',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Midwood', 'Greenwich Village', 'Williamsburg'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 8,
      },
      'spotsList': [
        {'name': 'Di Fara Pizza', 'location': 'Midwood, Brooklyn'},
        {'name': 'L&B Spumoni Gardens', 'location': 'Gravesend, Brooklyn'},
        {'name': "Joe's Pizza", 'location': 'Greenwich Village, Manhattan'},
        {'name': 'Lucali', 'location': 'Carroll Gardens, Brooklyn'},
        {'name': 'Prince Street Pizza', 'location': 'Nolita, Manhattan'},
        {'name': "Paulie Gee's", 'location': 'Greenpoint, Brooklyn'},
        {"name": "Scarr's Pizza", 'location': 'Lower East Side, Manhattan'},
        {"name": "Roberta's", 'location': 'Bushwick, Brooklyn'},
      ],
    },
    {
      'name': 'Late Night Eats',
      'creator': 'avrai food agent',
      'spots': 7,
      'respects': 352,
      'category': 'Food & Drink',
      'location': 'New York, NY',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['East Village', 'Lower East Side', 'Chelsea'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 7,
      },
      'spotsList': [
        {'name': 'Veselka', 'location': 'East Village, Manhattan'},
        {
          'name': "Katz's Delicatessen",
          'location': 'Lower East Side, Manhattan',
        },
        {'name': 'Los Tacos No. 1', 'location': 'Chelsea, Manhattan'},
        {'name': 'Wo Hop', 'location': 'Chinatown, Manhattan'},
        {
          "name": "Mamoun's Falafel",
          'location': 'Greenwich Village, Manhattan',
        },
        {
          "name": "L'industrie Pizzeria",
          'location': 'Williamsburg, Brooklyn',
        },
        {'name': 'Halal Guys', 'location': 'Midtown, Manhattan'},
      ],
    },
    {
      'name': 'Free Events This Week',
      'creator': 'avrai events agent',
      'spots': 6,
      'respects': 531,
      'category': 'Entertainment',
      'location': 'New York, NY',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Central Park', 'Williamsburg', 'DUMBO'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 6,
      },
      'spotsList': [
        {
          'name': 'SummerStage in Central Park',
          'location': 'Central Park, Manhattan',
        },
        {'name': 'Smorgasburg', 'location': 'Williamsburg, Brooklyn'},
        {'name': 'Brooklyn Flea', 'location': 'DUMBO, Brooklyn'},
        {
          'name': 'The Met Free Fridays',
          'location': 'Upper East Side, Manhattan',
        },
        {
          'name': 'Jazz at Lincoln Center Free Concerts',
          'location': 'Columbus Circle, Manhattan',
        },
        {
          'name': 'Prospect Park Bandshell',
          'location': 'Prospect Park, Brooklyn',
        },
      ],
    },
    {
      'name': 'Live Music Venues',
      'creator': 'avrai events agent',
      'spots': 8,
      'respects': 419,
      'category': 'Entertainment',
      'location': 'New York, NY',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Williamsburg', 'Lower East Side', 'Greenwich Village'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 8,
      },
      'spotsList': [
        {'name': 'Brooklyn Steel', 'location': 'Williamsburg, Brooklyn'},
        {
          'name': 'Bowery Ballroom',
          'location': 'Lower East Side, Manhattan',
        },
        {
          'name': 'Village Vanguard',
          'location': 'Greenwich Village, Manhattan',
        },
        {"name": "Baby's All Right", 'location': 'Williamsburg, Brooklyn'},
        {
          'name': 'Blue Note Jazz Club',
          'location': 'Greenwich Village, Manhattan',
        },
        {
          'name': 'Rough Trade NYC',
          'location': 'Rockefeller Center, Manhattan',
        },
        {
          'name': 'Mercury Lounge',
          'location': 'Lower East Side, Manhattan',
        },
        {
          'name': 'Music Hall of Williamsburg',
          'location': 'Williamsburg, Brooklyn',
        },
      ],
    },
    {
      'name': 'Best Parks & Green Spaces',
      'creator': 'avrai activities agent',
      'spots': 8,
      'respects': 563,
      'category': 'Outdoor & Nature',
      'location': 'New York, NY',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Prospect Park', 'Chelsea', 'DUMBO'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 8,
      },
      'spotsList': [
        {'name': 'Prospect Park', 'location': 'Prospect Park, Brooklyn'},
        {'name': 'The High Line', 'location': 'Chelsea, Manhattan'},
        {'name': 'Domino Park', 'location': 'Williamsburg, Brooklyn'},
        {'name': 'Fort Greene Park', 'location': 'Fort Greene, Brooklyn'},
        {'name': 'Hudson River Park', 'location': 'West Side, Manhattan'},
        {'name': 'Brooklyn Bridge Park', 'location': 'DUMBO, Brooklyn'},
        {'name': 'Governors Island', 'location': 'New York Harbor'},
        {
          'name': 'Gantry Plaza State Park',
          'location': 'Long Island City, Queens',
        },
      ],
    },
    {
      'name': 'Coffee & Work Spots',
      'creator': 'avrai activities agent',
      'spots': 7,
      'respects': 298,
      'category': 'Activities',
      'location': 'New York, NY',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Williamsburg', 'Greenwich Village', 'East Village'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 7,
      },
      'spotsList': [
        {'name': 'Devoción', 'location': 'Williamsburg, Brooklyn'},
        {
          'name': 'Think Coffee',
          'location': 'Greenwich Village, Manhattan',
        },
        {'name': 'Sey Coffee', 'location': 'Bushwick, Brooklyn'},
        {'name': 'Partners Coffee', 'location': 'Park Slope, Brooklyn'},
        {'name': 'Abraço', 'location': 'East Village, Manhattan'},
        {'name': 'Café Grumpy', 'location': 'Greenpoint, Brooklyn'},
        {'name': 'Butler Bakery', 'location': 'Williamsburg, Brooklyn'},
      ],
    },
  ];

  // ---------------------------------------------------------------------------
  // Denver
  // ---------------------------------------------------------------------------

  static final List<Map<String, dynamic>> _denverLists = [
    {
      'name': 'Best Restaurants in Denver',
      'creator': 'avrai food agent',
      'spots': 8,
      'respects': 412,
      'category': 'Food & Drink',
      'location': 'Denver, CO',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['LoHi', 'RiNo', 'Union Station'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 8,
      },
      'spotsList': [
        {'name': 'Linger', 'location': 'LoHi, Denver'},
        {'name': 'Guard and Grace', 'location': 'LoDo, Denver'},
        {'name': 'Tavernetta', 'location': 'Union Station, Denver'},
        {'name': 'El Five', 'location': 'LoHi, Denver'},
        {'name': 'Hop Alley', 'location': 'RiNo, Denver'},
        {'name': 'Safta', 'location': 'The Source, Denver'},
        {'name': 'Uncle', 'location': 'RiNo, Denver'},
        {'name': 'Brutø', 'location': 'Baker, Denver'},
      ],
    },
    {
      'name': 'Late Night Denver',
      'creator': 'avrai food agent',
      'spots': 7,
      'respects': 274,
      'category': 'Food & Drink',
      'location': 'Denver, CO',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Colfax', 'LoDo', 'RiNo'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 7,
      },
      'spotsList': [
        {"name": "Pete's Kitchen", 'location': 'Colfax, Denver'},
        {
          "name": "Biker Jim's Gourmet Dogs",
          'location': 'LoDo, Denver',
        },
        {"name": "Fat Sully's Pizza", 'location': 'RiNo, Denver'},
        {"name": "Torchy's Tacos", 'location': 'RiNo, Denver'},
        {"name": "Steuben's", 'location': 'Uptown, Denver'},
        {'name': 'Snooze', 'location': 'Union Station, Denver'},
        {
          'name': 'Denver Biscuit Company',
          'location': 'Colfax, Denver',
        },
      ],
    },
    {
      'name': 'Denver Live Music',
      'creator': 'avrai events agent',
      'spots': 8,
      'respects': 541,
      'category': 'Entertainment',
      'location': 'Denver, CO',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Colfax', 'Five Points', 'Capitol Hill'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 8,
      },
      'spotsList': [
        {
          'name': 'Red Rocks Amphitheatre',
          'location': 'Morrison, CO',
        },
        {'name': 'Bluebird Theater', 'location': 'Colfax, Denver'},
        {'name': 'The Ogden Theatre', 'location': 'Colfax, Denver'},
        {'name': 'Gothic Theatre', 'location': 'Englewood, CO'},
        {
          'name': 'Cervantes Masterpiece Ballroom',
          'location': 'Five Points, Denver',
        },
        {'name': 'Dazzle Jazz', 'location': 'Capitol Hill, Denver'},
        {
          "name": "Ophelia's Electric Soapbox",
          'location': 'Capitol Hill, Denver',
        },
        {'name': 'Globe Hall', 'location': 'Globeville, Denver'},
      ],
    },
    {
      'name': 'Free Things to Do',
      'creator': 'avrai events agent',
      'spots': 6,
      'respects': 389,
      'category': 'Entertainment',
      'location': 'Denver, CO',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['RiNo', 'City Park', 'LoDo'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 6,
      },
      'spotsList': [
        {
          'name': 'First Friday Art Walk',
          'location': 'RiNo, Denver',
        },
        {
          'name': 'Denver Art Museum Free Days',
          'location': 'Civic Center, Denver',
        },
        {'name': 'City Park Jazz', 'location': 'City Park, Denver'},
        {'name': 'Confluence Park', 'location': 'LoDo, Denver'},
        {'name': '16th Street Mall', 'location': 'Downtown, Denver'},
        {
          'name': 'Denver Botanic Gardens Free Days',
          'location': 'Cheesman Park, Denver',
        },
      ],
    },
    {
      'name': 'Best Hiking Near Denver',
      'creator': 'avrai activities agent',
      'spots': 8,
      'respects': 602,
      'category': 'Outdoor & Nature',
      'location': 'Denver, CO',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Morrison', 'Golden', 'Lakewood'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 8,
      },
      'spotsList': [
        {
          'name': 'Red Rocks Park Trail',
          'location': 'Morrison, CO',
        },
        {'name': 'Mount Falcon', 'location': 'Morrison, CO'},
        {"name": "Lair o' the Bear", 'location': 'Idledale, CO'},
        {'name': 'Waterton Canyon', 'location': 'Littleton, CO'},
        {
          'name': 'South Table Mountain',
          'location': 'Golden, CO',
        },
        {'name': 'Lookout Mountain', 'location': 'Golden, CO'},
        {'name': 'Cherry Creek Trail', 'location': 'Denver, CO'},
        {'name': 'Bear Creek Trail', 'location': 'Lakewood, CO'},
      ],
    },
    {
      'name': 'Denver Coffee Scene',
      'creator': 'avrai activities agent',
      'spots': 7,
      'respects': 318,
      'category': 'Activities',
      'location': 'Denver, CO',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['RiNo', 'Capitol Hill', 'Five Points'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 7,
      },
      'spotsList': [
        {'name': 'Huckleberry Roasters', 'location': 'RiNo, Denver'},
        {
          'name': 'Sweet Bloom Coffee',
          'location': 'Lakewood, CO',
        },
        {'name': 'Corvus Coffee', 'location': 'Broadway, Denver'},
        {
          'name': 'Little Owl Coffee',
          'location': 'Capitol Hill, Denver',
        },
        {
          'name': 'Jubilee Roasting',
          'location': 'Five Points, Denver',
        },
        {'name': 'Thump Coffee', 'location': 'Capitol Hill, Denver'},
        {
          'name': 'Commonwealth Coffee',
          'location': 'Five Points, Denver',
        },
      ],
    },
  ];

  // ---------------------------------------------------------------------------
  // Atlanta
  // ---------------------------------------------------------------------------

  static final List<Map<String, dynamic>> _atlantaLists = [
    {
      'name': 'Best Restaurants in Atlanta',
      'creator': 'avrai food agent',
      'spots': 8,
      'respects': 445,
      'category': 'Food & Drink',
      'location': 'Atlanta, GA',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Westside', 'Old Fourth Ward', 'East Atlanta'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 8,
      },
      'spotsList': [
        {
          'name': 'Bacchanalia',
          'location': 'Westside Provisions, Atlanta',
        },
        {'name': 'Gunshow', 'location': 'Glenwood Park, Atlanta'},
        {
          'name': 'Staplehouse',
          'location': 'Old Fourth Ward, Atlanta',
        },
        {'name': 'The Optimist', 'location': 'Westside, Atlanta'},
        {
          'name': 'Fox Bros Bar-B-Q',
          'location': 'Candler Park, Atlanta',
        },
        {
          'name': 'Bon Ton',
          'location': 'Ponce City Market, Atlanta',
        },
        {'name': 'Lazy Betty', 'location': 'East Atlanta, Atlanta'},
        {
          'name': 'Cooks & Soldiers',
          'location': 'Westside, Atlanta',
        },
      ],
    },
    {
      'name': 'Late Night Atlanta',
      'creator': 'avrai food agent',
      'spots': 7,
      'respects': 327,
      'category': 'Food & Drink',
      'location': 'Atlanta, GA',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Midtown', 'Poncey-Highland', 'Buckhead'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 7,
      },
      'spotsList': [
        {'name': 'The Varsity', 'location': 'Midtown, Atlanta'},
        {'name': 'Waffle House', 'location': 'Atlanta, GA'},
        {
          'name': 'Clermont Lounge',
          'location': 'Poncey-Highland, Atlanta',
        },
        {
          'name': 'Sublime Doughnuts',
          'location': 'Midtown, Atlanta',
        },
        {
          'name': 'Taqueria del Sol',
          'location': 'Westside, Atlanta',
        },
        {
          'name': 'R. Thomas Deluxe Grill',
          'location': 'Buckhead, Atlanta',
        },
        {'name': 'Ortolana', 'location': 'East Atlanta, Atlanta'},
      ],
    },
    {
      'name': 'Live Music in Atlanta',
      'creator': 'avrai events agent',
      'spots': 8,
      'respects': 478,
      'category': 'Entertainment',
      'location': 'Atlanta, GA',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Little Five Points', 'East Atlanta', 'Midtown'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 8,
      },
      'spotsList': [
        {'name': 'The Tabernacle', 'location': 'Downtown, Atlanta'},
        {'name': 'Terminal West', 'location': 'Westside, Atlanta'},
        {
          'name': 'Variety Playhouse',
          'location': 'Little Five Points, Atlanta',
        },
        {'name': 'Center Stage', 'location': 'Midtown, Atlanta'},
        {'name': 'The Earl', 'location': 'East Atlanta, Atlanta'},
        {"name": "Eddie's Attic", 'location': 'Decatur, GA'},
        {
          'name': 'Aisle 5',
          'location': 'Little Five Points, Atlanta',
        },
        {
          "name": "Smith's Olde Bar",
          'location': 'Midtown, Atlanta',
        },
      ],
    },
    {
      'name': 'Free Things to Do in Atlanta',
      'creator': 'avrai events agent',
      'spots': 6,
      'respects': 394,
      'category': 'Entertainment',
      'location': 'Atlanta, GA',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Midtown', 'Old Fourth Ward', 'Inman Park'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 6,
      },
      'spotsList': [
        {'name': 'BeltLine Trail', 'location': 'Atlanta, GA'},
        {'name': 'Piedmont Park', 'location': 'Midtown, Atlanta'},
        {
          'name': 'Ponce City Market Rooftop',
          'location': 'Old Fourth Ward, Atlanta',
        },
        {
          'name': 'Krog Street Market',
          'location': 'Inman Park, Atlanta',
        },
        {
          'name': 'Martin Luther King Jr. National Historical Park',
          'location': 'Sweet Auburn, Atlanta',
        },
        {
          'name': 'Freedom Park Trail',
          'location': 'Inman Park, Atlanta',
        },
      ],
    },
    {
      'name': 'Best Parks & Trails',
      'creator': 'avrai activities agent',
      'spots': 8,
      'respects': 517,
      'category': 'Outdoor & Nature',
      'location': 'Atlanta, GA',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Midtown', 'Buckhead', 'South Atlanta'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 8,
      },
      'spotsList': [
        {'name': 'Piedmont Park', 'location': 'Midtown, Atlanta'},
        {
          'name': 'BeltLine Eastside Trail',
          'location': 'Atlanta, GA',
        },
        {
          'name': 'Sweetwater Creek State Park',
          'location': 'Lithia Springs, GA',
        },
        {'name': 'Stone Mountain Park', 'location': 'Stone Mountain, GA'},
        {'name': 'Grant Park', 'location': 'Grant Park, Atlanta'},
        {'name': 'Chastain Park', 'location': 'Buckhead, Atlanta'},
        {
          'name': 'Constitution Lakes Park',
          'location': 'South Atlanta, Atlanta',
        },
        {
          'name': 'Cascade Springs Nature Preserve',
          'location': 'Cascade Heights, Atlanta',
        },
      ],
    },
    {
      'name': 'Atlanta Coffee Culture',
      'creator': 'avrai activities agent',
      'spots': 7,
      'respects': 283,
      'category': 'Activities',
      'location': 'Atlanta, GA',
      'userProfile': {
        'expertise': 'curated by avrai',
        'locations': ['Westside', 'Old Fourth Ward', 'East Atlanta'],
        'hostedEventsCount': 0,
        'differentSpotsCount': 7,
      },
      'spotsList': [
        {
          'name': 'Revelator Coffee',
          'location': 'Westside Provisions, Atlanta',
        },
        {
          'name': 'Chrome Yellow Trading Co',
          'location': 'Old Fourth Ward, Atlanta',
        },
        {
          'name': 'East Pole Coffee',
          'location': 'East Atlanta, Atlanta',
        },
        {'name': 'Taproom Coffee', 'location': 'Kirkwood, Atlanta'},
        {'name': 'Brash Coffee', 'location': 'Westside, Atlanta'},
        {
          'name': 'Dancing Goats Coffee',
          'location': 'Ponce City Market, Atlanta',
        },
        {'name': 'Octane Coffee', 'location': 'Grant Park, Atlanta'},
      ],
    },
  ];

  // ---------------------------------------------------------------------------
  // Birmingham
  // ---------------------------------------------------------------------------

  static final List<Map<String, dynamic>> _birminghamLists = [
    {
      'name': 'Birmingham Coffee + Work',
      'creator': 'avrai local agent',
      'spots': 5,
      'respects': 164,
      'category': 'Food & Drink',
      'location': 'Birmingham, AL',
      'spotsList': [
        {'name': 'June Coffee', 'location': 'Downtown Birmingham'},
        {'name': 'Seeds Coffee Co.', 'location': 'Homewood'},
        {'name': 'Cala Coffee', 'location': 'Cahaba Heights'},
        {'name': 'Domestique Coffee', 'location': 'Avondale'},
        {'name': 'Filter Coffee Parlor', 'location': 'Five Points South'},
      ],
    },
    {
      'name': 'Birmingham Music + Arts',
      'creator': 'avrai events agent',
      'spots': 5,
      'respects': 193,
      'category': 'Entertainment',
      'location': 'Birmingham, AL',
      'spotsList': [
        {'name': 'Saturn', 'location': 'Avondale'},
        {'name': 'Iron City', 'location': 'Downtown Birmingham'},
        {'name': 'Lyric Theatre', 'location': 'Downtown Birmingham'},
        {'name': 'Avondale Brewing', 'location': 'Avondale'},
        {
          'name': 'Sidewalk Film Center + Cinema',
          'location': 'Downtown Birmingham'
        },
      ],
    },
    {
      'name': 'Birmingham Volunteer + Civic',
      'creator': 'avrai community agent',
      'spots': 4,
      'respects': 142,
      'category': 'Community',
      'location': 'Birmingham, AL',
      'spotsList': [
        {
          'name': 'Railroad Park volunteer days',
          'location': 'Downtown Birmingham'
        },
        {
          'name': 'Jones Valley Teaching Farm',
          'location': 'Downtown Birmingham'
        },
        {'name': 'Rotary Trail cleanups', 'location': 'Birmingham'},
        {'name': 'Neighborhood association meetups', 'location': 'Homewood'},
      ],
    },
  ];
}

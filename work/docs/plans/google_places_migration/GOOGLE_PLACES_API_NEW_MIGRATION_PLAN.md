# Google Places API (New) Migration Plan

**Date:** January 2025  
**Status:** 📋 **PLANNING**  
**Reference:** [Google Places API (New) Documentation](https://docs.cloud.google.com/nodejs/docs/reference/places/latest)

---

## 🎯 **MIGRATION OVERVIEW**

Migrating from **Legacy Places API** to **Places API (New)** requires updating endpoints, request/response formats, and adding field masking for cost optimization.

---

## 📊 **KEY DIFFERENCES**

### **Current (Legacy API)**
- Base URL: `https://maps.googleapis.com/maps/api/place`
- Endpoints: `/textsearch/json`, `/nearbysearch/json`, `/details/json`
- Method: GET requests
- Response: Simple JSON with `results` array
- Field selection: Query parameter `fields=...`

### **New API**
- Base URL: `https://places.googleapis.com/v1`
- Endpoints: `/places:searchText`, `/places:searchNearby`, `/places/{placeId}`
- Method: POST requests (for most endpoints)
- Response: Structured JSON with different format
- Field masking: Required via `X-Goog-FieldMask` header
- Authentication: API key in header or query param

---

## 🔄 **MIGRATION REQUIREMENTS**

### **1. Update Base URL & Endpoints**

**Current:**
```dart
static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
// Endpoints: /textsearch/json, /nearbysearch/json, /details/json
```

**New:**
```dart
static const String _baseUrl = 'https://places.googleapis.com/v1';
// Endpoints: /places:searchText, /places:searchNearby, /places/{placeId}
```

### **2. Change Request Method (GET → POST)**

**Current:**
```dart
final response = await _httpClient.get(Uri.parse(url));
```

**New:**
```dart
final response = await _httpClient.post(
  Uri.parse(url),
  headers: {
    'Content-Type': 'application/json',
    'X-Goog-Api-Key': _apiKey,
    'X-Goog-FieldMask': 'places.id,places.displayName,places.location,...',
  },
  body: jsonEncode(requestBody),
);
```

### **3. Update Request Format**

**Current Text Search:**
```dart
// GET /textsearch/json?query=coffee&location=40.7128,-74.0060&radius=5000&key=API_KEY
```

**New Text Search:**
```dart
// POST /places:searchText
{
  "textQuery": "coffee",
  "locationBias": {
    "circle": {
      "center": {
        "latitude": 40.7128,
        "longitude": -74.0060
      },
      "radius": 5000.0
    }
  },
  "maxResultCount": 20
}
```

**Current Nearby Search:**
```dart
// GET /nearbysearch/json?location=40.7128,-74.0060&radius=5000&key=API_KEY
```

**New Nearby Search:**
```dart
// POST /places:searchNearby
{
  "includedTypes": ["restaurant"],
  "maxResultCount": 20,
  "locationRestriction": {
    "circle": {
      "center": {
        "latitude": 40.7128,
        "longitude": -74.0060
      },
      "radius": 5000.0
    }
  }
}
```

**Current Place Details:**
```dart
// GET /details/json?place_id=ChIJ...&fields=name,address&key=API_KEY
```

**New Place Details:**
```dart
// GET /places/{placeId}?languageCode=en
// With header: X-Goog-FieldMask: id,displayName,formattedAddress,location,rating,...
```

### **4. Update Response Parsing**

**Current Response Structure:**
```json
{
  "results": [
    {
      "place_id": "ChIJ...",
      "name": "Coffee Shop",
      "geometry": {
        "location": {
          "lat": 40.7128,
          "lng": -74.0060
        }
      },
      "rating": 4.5,
      "types": ["cafe", "food", "point_of_interest"]
    }
  ]
}
```

**New Response Structure:**
```json
{
  "places": [
    {
      "id": "places/ChIJ...",
      "displayName": {
        "text": "Coffee Shop",
        "languageCode": "en"
      },
      "location": {
        "latitude": 40.7128,
        "longitude": -74.0060
      },
      "rating": 4.5,
      "types": ["cafe", "food", "point_of_interest"],
      "formattedAddress": "123 Main St, New York, NY"
    }
  ]
}
```

### **5. Add Field Masking**

**Required for cost optimization:**
```dart
// Only request fields you actually need
final fieldMask = 'places.id,places.displayName,places.location,'
    'places.rating,places.formattedAddress,places.types,'
    'places.phoneNumber,places.websiteUri,places.openingHours';

headers['X-Goog-FieldMask'] = fieldMask;
```

### **6. Update Place ID Format**

**Current:** `place_id` (e.g., `ChIJ...`)  
**New:** `places/{place_id}` (e.g., `places/ChIJ...`)

---

## 📋 **FILES TO UPDATE**

### **1. Data Source Implementation**
- `lib/data/datasources/remote/google_places_datasource_impl.dart`
  - Update base URL
  - Change GET to POST
  - Update request body format
  - Update response parsing
  - Add field masking

### **2. Place ID Finder Service**
- `lib/core/services/google_place_id_finder_service.dart`
  - Update API endpoints
  - Change request format
  - Update response parsing

### **3. Response Parsing**
- Update `_parseSearchResults()` method
- Update `_createSpotFromPlace()` method
- Handle new response structure

---

## 🛠️ **IMPLEMENTATION STEPS**

### **Step 1: Create New API Implementation (Parallel)**

Create a new implementation alongside the old one:

```dart
// lib/data/datasources/remote/google_places_datasource_new_impl.dart
class GooglePlacesDataSourceNewImpl implements GooglePlacesDataSource {
  static const String _baseUrl = 'https://places.googleapis.com/v1';
  
  // Implement new API endpoints
}
```

### **Step 2: Update Request Builders**

```dart
Map<String, dynamic> _buildSearchTextRequest({
  required String query,
  double? latitude,
  double? longitude,
  int radius = 5000,
}) {
  final request = {
    'textQuery': query,
    'maxResultCount': 20,
  };
  
  if (latitude != null && longitude != null) {
    request['locationBias'] = {
      'circle': {
        'center': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'radius': radius.toDouble(),
      },
    };
  }
  
  return request;
}
```

### **Step 3: Update Response Parsing**

```dart
List<Spot> _parseNewSearchResults(Map<String, dynamic> data) {
  final places = data['places'] as List<dynamic>? ?? [];
  return places.map((place) => _createSpotFromNewPlace(place)).toList();
}

Spot _createSpotFromNewPlace(Map<String, dynamic> place) {
  final displayName = place['displayName'] as Map<String, dynamic>?;
  final location = place['location'] as Map<String, dynamic>?;
  final placeId = place['id'] as String? ?? '';
  
  // Extract place_id from "places/ChIJ..." format
  final cleanPlaceId = placeId.replaceFirst('places/', '');
  
  return Spot(
    id: 'google_$cleanPlaceId',
    name: displayName?['text'] ?? 'Unknown Place',
    latitude: location?['latitude']?.toDouble() ?? 0.0,
    longitude: location?['longitude']?.toDouble() ?? 0.0,
    // ... map other fields
  );
}
```

### **Step 4: Add Field Masking**

```dart
String _getFieldMask({bool includeDetails = false}) {
  final baseFields = [
    'places.id',
    'places.displayName',
    'places.location',
    'places.rating',
    'places.formattedAddress',
    'places.types',
  ];
  
  if (includeDetails) {
    baseFields.addAll([
      'places.phoneNumber',
      'places.websiteUri',
      'places.openingHours',
      'places.photos',
    ]);
  }
  
  return baseFields.join(',');
}
```

### **Step 5: Update Dependency Injection**

```dart
// Option 1: Feature flag to switch between APIs
sl.registerLazySingleton<GooglePlacesDataSource>(() {
  final useNewApi = bool.fromEnvironment('USE_NEW_PLACES_API', defaultValue: false);
  if (useNewApi) {
    return GooglePlacesDataSourceNewImpl(...);
  } else {
    return GooglePlacesDataSourceImpl(...);
  }
});

// Option 2: Direct switch
sl.registerLazySingleton<GooglePlacesDataSource>(
  () => GooglePlacesDataSourceNewImpl(...),
);
```

---

## ⚠️ **BREAKING CHANGES**

1. **Place ID Format**
   - Old: `ChIJ...`
   - New: `places/ChIJ...`
   - Need to handle both formats during migration

2. **Response Structure**
   - Old: `results` array
   - New: `places` array
   - Different field names (e.g., `name` → `displayName.text`)

3. **Request Method**
   - Old: GET requests
   - New: POST requests (for search endpoints)

4. **Field Selection**
   - Old: Query parameter `fields=...`
   - New: Header `X-Goog-FieldMask: ...`

---

## 💰 **COST CONSIDERATIONS**

### **Field Masking Benefits**
- Only pay for fields you request
- Reduces response size
- Lower bandwidth costs

### **Example Cost Savings:**
```dart
// Request only needed fields
final fieldMask = 'places.id,places.displayName,places.location';
// vs requesting all fields (more expensive)
```

---

## 🚀 **MIGRATION STRATEGY**

### **Option 1: Gradual Migration (Recommended)**
1. Implement new API alongside old API
2. Add feature flag to switch between them
3. Test thoroughly
4. Switch over when ready
5. Remove old implementation

### **Option 2: Direct Migration**
1. Update implementation directly
2. Test in development
3. Deploy when ready

### **Option 3: Hybrid Approach**
1. Use new API for new features
2. Keep old API for existing features
3. Gradually migrate features

---

## 📝 **CHECKLIST**

- [ ] Enable Places API (New) in Google Cloud Console
- [ ] Update base URL
- [ ] Change GET to POST for search endpoints
- [ ] Update request body format
- [ ] Add field masking headers
- [ ] Update response parsing
- [ ] Handle new Place ID format
- [ ] Update Place ID Finder Service
- [ ] Update tests
- [ ] Test with real API calls
- [ ] Monitor costs
- [ ] Update documentation

---

## 🔍 **TESTING REQUIREMENTS**

1. **Unit Tests**
   - Test request building
   - Test response parsing
   - Test field masking

2. **Integration Tests**
   - Test actual API calls
   - Test error handling
   - Test caching

3. **Performance Tests**
   - Compare response times
   - Compare costs
   - Test field masking impact

---

## 📚 **RESOURCES**

- [Places API (New) Documentation](https://developers.google.com/maps/documentation/places/web-service)
- [Places API (New) Node.js Client](https://docs.cloud.google.com/nodejs/docs/reference/places/latest)
- [Field Masking Guide](https://developers.google.com/maps/documentation/places/web-service/place-field-masks)
- [Migration Guide](https://developers.google.com/maps/documentation/places/web-service/migrate)

---

## ⏱️ **ESTIMATED EFFORT**

- **Implementation:** 2-3 days
- **Testing:** 1-2 days
- **Migration:** 1 day
- **Total:** 4-6 days

---

## ✅ **RECOMMENDATION**

**For SPOTS:** Consider migrating when:
1. You need new API features (autocomplete, photo media, etc.)
2. You want better cost optimization (field masking)
3. Legacy API is deprecated (check Google's timeline)
4. You have time for thorough testing

**Current Status:** Legacy API works well. Migration is optional unless you need new features.

---

*Part of SPOTS Google Places Integration Planning*


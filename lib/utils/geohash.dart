// Simple Geohash implementation for location queries
// Based on: https://en.wikipedia.org/wiki/Geohash

class Geohash {
  static const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
  
  static String encode(double latitude, double longitude, {int precision = 9}) {
    double latMin = -90.0;
    double latMax = 90.0;
    double lonMin = -180.0;
    double lonMax = 180.0;
    
    bool even = true;
    int bit = 0;
    int ch = 0;
    int geohashLength = 0;
    final geohash = StringBuffer();
    
    while (geohashLength < precision) {
      if (even) {
        // Longitude
        final lonMid = (lonMin + lonMax) / 2;
        if (longitude >= lonMid) {
          ch |= (1 << (4 - bit));
          lonMin = lonMid;
        } else {
          lonMax = lonMid;
        }
      } else {
        // Latitude
        final latMid = (latMin + latMax) / 2;
        if (latitude >= latMid) {
          ch |= (1 << (4 - bit));
          latMin = latMid;
        } else {
          latMax = latMid;
        }
      }
      
      even = !even;
      if (bit < 4) {
        bit++;
      } else {
        geohash.write(_base32[ch]);
        geohashLength++;
        bit = 0;
        ch = 0;
      }
    }
    
    return geohash.toString();
  }
  
  // Get neighboring geohashes (simplified - returns 9 neighbors including center)
  static List<String> getNeighbors(String geohash) {
    final neighbors = <String>[];
    final precision = geohash.length;
    
    // For simplicity, we'll generate neighbors by varying the last character
    // This is a simplified approach - for production, use a proper geohash library
    final base = precision > 1 ? geohash.substring(0, precision - 1) : '';
    final lastChar = geohash[precision - 1];
    final lastCharIndex = _base32.indexOf(lastChar);
    
    // Generate 9 neighbors (3x3 grid)
    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        final newIndex = lastCharIndex + i + (j * 8); // Simplified neighbor calculation
        if (newIndex >= 0 && newIndex < _base32.length) {
          neighbors.add(base + _base32[newIndex]);
        } else {
          neighbors.add(geohash); // Fallback to original
        }
      }
    }
    
    return neighbors;
  }
}


# Firestore Data Structure

## Collections

### `road_reports`
Document structure:
```typescript
{
  location: {
    lat: number,      // Latitude
    lng: number,     // Longitude
    geohash: string  // Geohash for location queries
  },
  issue_type: string,  // 'checkpoint' | 'accident' | 'construction' | 'flood' | 'tree_fallen' | 'protest' | 'other'
  description?: string,
  created_at: Timestamp,
  expires_at: Timestamp,  // created_at + 4 hours
  created_by?: string,    // Firebase Auth UID (nullable for anonymous)
  is_active: boolean,
  confirmations_count: number,
  dismissals_count: number
}
```

### `report_votes`
Document structure:
```typescript
{
  report_id: string,     // Reference to road_reports document ID
  user_id?: string,      // Firebase Auth UID (nullable for anonymous)
  vote_type: string,     // 'confirm' | 'dismiss'
  created_at: Timestamp
}
```

## Indexes Required

Create composite indexes in Firestore Console:

1. **road_reports collection:**
   - Fields: `is_active` (Ascending), `expires_at` (Ascending)
   - Query scope: Collection

2. **road_reports collection:**
   - Fields: `location.geohash` (Ascending), `is_active` (Ascending), `expires_at` (Ascending)
   - Query scope: Collection

3. **report_votes collection:**
   - Fields: `report_id` (Ascending), `user_id` (Ascending), `vote_type` (Ascending)
   - Query scope: Collection

## Geohash for Location Queries

We use geohash to enable efficient location-based queries in Firestore. Geohash converts lat/lng coordinates into a string that can be used for range queries.

- Precision: We use geohash precision 9 (approximately 5km accuracy)
- Nearby queries: Query geohash prefixes to find nearby reports


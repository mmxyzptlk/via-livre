import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/geohash.dart';
import '../models/road_report.dart';
import '../models/report_vote.dart';
import '../models/issue_type.dart';

class FirebaseService {
  FirebaseFirestore get _firestore {
    try {
      return FirebaseFirestore.instanceFor(app: Firebase.app('via-livre'));
    } catch (e) {
      // Fallback to default if named app doesn't exist
      return FirebaseFirestore.instance;
    }
  }
  
  FirebaseAuth get _auth {
    try {
      return FirebaseAuth.instanceFor(app: Firebase.app('via-livre'));
    } catch (e) {
      // Fallback to default if named app doesn't exist
      return FirebaseAuth.instance;
    }
  }

  // Initialize anonymous session if not already authenticated
  Future<void> ensureAuthenticated() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  // Calculate distance between two points in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    final double lat1Rad = point1.latitude * pi / 180;
    final double lat2Rad = point2.latitude * pi / 180;
    final double deltaLatRad = (point2.latitude - point1.latitude) * pi / 180;
    final double deltaLngRad = (point2.longitude - point1.longitude) * pi / 180;

    final double a = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLngRad / 2) * sin(deltaLngRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }


  // Get all active reports (no distance filtering)
  Future<List<RoadReport>> getAllReports() async {
    try {
      final allReports = <RoadReport>[];
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      
      // Query all active, non-expired reports
      final query = _firestore
          .collection('road_reports')
          .where('is_active', isEqualTo: true)
          .limit(500); // Reasonable limit for all reports
      
      final snapshot = await query.get();
      
      for (final doc in snapshot.docs) {
        try {
          final report = RoadReport.fromFirestore(doc);
          
          // Client-side filter: ensure report is not older than 2 hours
          if (report.createdAt.isBefore(twoHoursAgo)) {
            continue;
          }
          
          allReports.add(report);
        } catch (e) {
          // Skip invalid reports
          continue;
        }
      }
      
      return allReports;
    } catch (e) {
      throw Exception('Failed to fetch all reports: $e');
    }
  }

  // Get nearby reports within a radius (in meters)
  Future<List<RoadReport>> getNearbyReports(
    LatLng center,
    double radiusMeters,
  ) async {
    try {
      // For 30km radius, we need to query a much larger area
      // Precision 4 = ~20km per cell, 3x3 grid covers ~60km (sufficient for 30km radius)
      // Precision 5 = ~5km per cell, 3x3 grid only covers ~15km (not enough)
      final precision = radiusMeters > 20000 ? 4 : 9;
      final prefixLength = radiusMeters > 20000 ? 4 : 7;
      
      final centerGeohash = Geohash.encode(center.latitude, center.longitude, precision: precision);
      
      // For large radii, we need to query multiple geohash cells
      // Generate a grid of geohash prefixes to cover the radius
      final geohashPrefixes = <String>{};
      
      if (radiusMeters > 20000) {
        // For 30km radius, use precision 4 geohash (~20km per cell)
        // Query neighbors to cover ~60km x 60km area (sufficient for 30km radius)
        final neighbors = Geohash.getNeighbors(centerGeohash);
        for (final neighbor in neighbors) {
          final prefix = neighbor.substring(0, prefixLength);
          geohashPrefixes.add(prefix);
        }
        
        // Also add the center cell's prefix
        final centerPrefix = centerGeohash.substring(0, prefixLength);
        geohashPrefixes.add(centerPrefix);
      } else {
        // For smaller radii, use the standard approach
        final geohashNeighbors = Geohash.getNeighbors(centerGeohash);
        geohashPrefixes.addAll(geohashNeighbors.map((h) => h.substring(0, prefixLength)));
      }
      
      final allReports = <RoadReport>[];
      final twoHoursAgo = DateTime.now().subtract(const Duration(hours: 2));
      
      // Query each geohash prefix
      for (final prefix in geohashPrefixes) {
        final query = _firestore
            .collection('road_reports')
            .where('location.geohash', isGreaterThanOrEqualTo: prefix)
            .where('location.geohash', isLessThan: '${prefix}z')
            .where('is_active', isEqualTo: true)
            .limit(200); // Increased limit for larger search area
        
        final snapshot = await query.get();
        
        for (final doc in snapshot.docs) {
          try {
            final report = RoadReport.fromFirestore(doc);
            
            // Client-side filter: ensure report is not older than 2 hours
            if (report.createdAt.isBefore(twoHoursAgo)) {
              continue;
            }
            
            final distance = _calculateDistance(center, report.location);
            
            if (distance <= radiusMeters) {
              allReports.add(report);
            }
          } catch (e) {
            // Skip invalid reports
            continue;
          }
        }
      }
      
      // Remove duplicates (in case a report appears in multiple geohash queries)
      final uniqueReports = <String, RoadReport>{};
      for (final report in allReports) {
        uniqueReports[report.id] = report;
      }
      
      // Sort by distance
      final sortedReports = uniqueReports.values.toList();
      sortedReports.sort((a, b) {
        final distA = _calculateDistance(center, a.location);
        final distB = _calculateDistance(center, b.location);
        return distA.compareTo(distB);
      });
      
      return sortedReports;
    } catch (e) {
      throw Exception('Failed to fetch nearby reports: $e');
    }
  }

  // Create a new road report
  Future<RoadReport> createReport({
    required LatLng location,
    required IssueType issueType,
    String? description,
  }) async {
    try {
      await ensureAuthenticated();
      
      final now = DateTime.now();
      final expiresAt = now.add(const Duration(hours: 2));
      final geohash = Geohash.encode(location.latitude, location.longitude, precision: 9);
      
      final reportData = {
        'location': {
          'lat': location.latitude,
          'lng': location.longitude,
          'geohash': geohash,
        },
        'issue_type': issueType.value,
        'description': description,
        'created_at': Timestamp.fromDate(now),
        'expires_at': Timestamp.fromDate(expiresAt),
        'created_by': _auth.currentUser?.uid,
        'is_active': true,
        'confirmations_count': 0,
        'dismissals_count': 0,
      };
      
      final docRef = await _firestore.collection('road_reports').add(reportData);
      
      return RoadReport(
        id: docRef.id,
        location: location,
        geohash: geohash,
        issueType: issueType,
        description: description,
        createdAt: now,
        expiresAt: expiresAt,
        createdBy: _auth.currentUser?.uid,
        isActive: true,
        confirmationsCount: 0,
        dismissalsCount: 0,
      );
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  // Subscribe to real-time updates for road reports
  Stream<List<RoadReport>> subscribeToReports(LatLng center, double radiusMeters) {
    final controller = StreamController<List<RoadReport>>.broadcast();
    
    // Initial fetch
    getNearbyReports(center, radiusMeters).then((reports) {
      controller.add(reports);
    }).catchError((error) {
      controller.addError(error);
    });

    // Subscribe to real-time changes
    // For 30km radius, use precision 4 geohash and query neighbors
    final centerGeohash = Geohash.encode(center.latitude, center.longitude, precision: 4);
    final prefixLength = 4;
    
    // Generate geohash prefixes to cover 30km radius
    final geohashPrefixes = <String>{};
    final neighbors = Geohash.getNeighbors(centerGeohash);
    for (final neighbor in neighbors) {
      final prefix = neighbor.substring(0, prefixLength);
      geohashPrefixes.add(prefix);
    }
    
    // Also add the center cell's prefix
    final centerPrefix = centerGeohash.substring(0, prefixLength);
    geohashPrefixes.add(centerPrefix); // Even broader prefix for 30km
    
    final subscriptions = <StreamSubscription>[];
    
    for (final prefix in geohashPrefixes) {
      final stream = _firestore
          .collection('road_reports')
          .where('location.geohash', isGreaterThanOrEqualTo: prefix)
          .where('location.geohash', isLessThan: '${prefix}z')
          .where('is_active', isEqualTo: true)
          .snapshots();
      
      final subscription = stream.listen((snapshot) async {
        // When data changes, refetch nearby reports with fresh TTL filtering
        try {
          final reports = await getNearbyReports(center, radiusMeters);
          controller.add(reports);
        } catch (e) {
          controller.addError(e);
        }
      });
      
      subscriptions.add(subscription);
    }
    
    // Clean up subscriptions when stream is cancelled
    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };

    return controller.stream;
  }

  // Vote on a report (confirm or dismiss)
  Future<void> voteOnReport(String reportId, VoteType voteType) async {
    try {
      await ensureAuthenticated();
      final userId = _auth.currentUser?.uid;

      // Check if user already voted
      QuerySnapshot? existingVoteQuery;
      if (userId != null) {
        existingVoteQuery = await _firestore
            .collection('report_votes')
            .where('report_id', isEqualTo: reportId)
            .where('user_id', isEqualTo: userId)
            .limit(1)
            .get();
      }

      if (existingVoteQuery != null && existingVoteQuery.docs.isNotEmpty) {
        // Update existing vote if different type
        final existingVote = existingVoteQuery.docs.first;
        final existingVoteData = existingVote.data() as Map<String, dynamic>;
        
        if (existingVoteData['vote_type'] != voteType.value) {
          await existingVote.reference.update({'vote_type': voteType.value});
          await _updateVoteCounts(reportId, existingVoteData['vote_type'] as String, voteType.value);
        }
        // If same type, do nothing (already voted)
      } else {
        // Create new vote
        await _firestore.collection('report_votes').add({
          'report_id': reportId,
          'user_id': userId,
          'vote_type': voteType.value,
          'created_at': Timestamp.now(),
        });
        
        // Update vote counts
        await _updateVoteCounts(reportId, null, voteType.value);
      }
    } catch (e) {
      throw Exception('Failed to vote on report: $e');
    }
  }


  // Get user's vote for a specific report
  Future<VoteType?> getUserVote(String reportId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final query = await _firestore
          .collection('report_votes')
          .where('report_id', isEqualTo: reportId)
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final data = query.docs.first.data();
      return VoteType.fromString(data['vote_type'] as String);
    } catch (e) {
      return null;
    }
  }

  // Remove user's vote
  Future<void> removeVote(String reportId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final query = await _firestore
          .collection('report_votes')
          .where('report_id', isEqualTo: reportId)
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final voteData = query.docs.first.data();
        final voteType = voteData['vote_type'] as String;
        
        await query.docs.first.reference.delete();
        
        // Update vote counts
        await _updateVoteCountsForRemoval(reportId, voteType);
      }
    } catch (e) {
      throw Exception('Failed to remove vote: $e');
    }
  }

  // Update vote counts when removing a vote
  Future<void> _updateVoteCountsForRemoval(String reportId, String voteType) async {
    final reportRef = _firestore.collection('road_reports').doc(reportId);
    
    await _firestore.runTransaction((transaction) async {
      final reportDoc = await transaction.get(reportRef);
      if (!reportDoc.exists) return;
      
      final data = reportDoc.data()!;
      int confirmations = data['confirmations_count'] as int? ?? 0;
      int dismissals = data['dismissals_count'] as int? ?? 0;
      
      if (voteType == 'confirm') {
        confirmations = max(0, confirmations - 1);
      } else if (voteType == 'dismiss') {
        dismissals = max(0, dismissals - 1);
      }
      
      transaction.update(reportRef, {
        'confirmations_count': confirmations,
        'dismissals_count': dismissals,
      });
    });
  }

  // Update vote counts (overloaded for removal)
  Future<void> _updateVoteCounts(String reportId, String? oldVoteType, String? newVoteType) async {
    final reportRef = _firestore.collection('road_reports').doc(reportId);
    
    await _firestore.runTransaction((transaction) async {
      final reportDoc = await transaction.get(reportRef);
      if (!reportDoc.exists) return;
      
      final data = reportDoc.data()!;
      int confirmations = data['confirmations_count'] as int? ?? 0;
      int dismissals = data['dismissals_count'] as int? ?? 0;
      
      // Decrement old vote type
      if (oldVoteType == 'confirm') {
        confirmations = max(0, confirmations - 1);
      } else if (oldVoteType == 'dismiss') {
        dismissals = max(0, dismissals - 1);
      }
      
      // Increment new vote type
      if (newVoteType == 'confirm') {
        confirmations++;
      } else if (newVoteType == 'dismiss') {
        dismissals++;
      }
      
      transaction.update(reportRef, {
        'confirmations_count': confirmations,
        'dismissals_count': dismissals,
      });
    });
  }

}
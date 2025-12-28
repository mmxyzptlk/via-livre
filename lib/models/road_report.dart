import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'issue_type.dart';

class RoadReport {
  final String id;
  final LatLng location;
  final String geohash;
  final IssueType issueType;
  final String? description;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? createdBy;
  final bool isActive;
  final int confirmationsCount;
  final int dismissalsCount;

  RoadReport({
    required this.id,
    required this.location,
    required this.geohash,
    required this.issueType,
    this.description,
    required this.createdAt,
    required this.expiresAt,
    this.createdBy,
    required this.isActive,
    required this.confirmationsCount,
    required this.dismissalsCount,
  });

  factory RoadReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final locationData = data['location'] as Map<String, dynamic>;
    
    return RoadReport(
      id: doc.id,
      location: LatLng(
        locationData['lat'] as double,
        locationData['lng'] as double,
      ),
      geohash: locationData['geohash'] as String,
      issueType: IssueType.fromString(data['issue_type'] as String),
      description: data['description'] as String?,
      createdAt: (data['created_at'] as Timestamp).toDate(),
      expiresAt: data['expires_at'] != null 
          ? (data['expires_at'] as Timestamp).toDate()
          : (data['created_at'] as Timestamp).toDate().add(const Duration(hours: 2)),
      createdBy: data['created_by'] as String?,
      isActive: data['is_active'] as bool? ?? true,
      confirmationsCount: data['confirmations_count'] as int? ?? 0,
      dismissalsCount: data['dismissals_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'location': {
        'lat': location.latitude,
        'lng': location.longitude,
        'geohash': geohash,
      },
      'issue_type': issueType.value,
      'description': description,
      'created_at': Timestamp.fromDate(createdAt),
      'expires_at': Timestamp.fromDate(expiresAt),
      'created_by': createdBy,
      'is_active': isActive,
      'confirmations_count': confirmationsCount,
      'dismissals_count': dismissalsCount,
    };
  }

  RoadReport copyWith({
    String? id,
    LatLng? location,
    String? geohash,
    IssueType? issueType,
    String? description,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? createdBy,
    bool? isActive,
    int? confirmationsCount,
    int? dismissalsCount,
  }) {
    return RoadReport(
      id: id ?? this.id,
      location: location ?? this.location,
      geohash: geohash ?? this.geohash,
      issueType: issueType ?? this.issueType,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
      confirmationsCount: confirmationsCount ?? this.confirmationsCount,
      dismissalsCount: dismissalsCount ?? this.dismissalsCount,
    );
  }
}


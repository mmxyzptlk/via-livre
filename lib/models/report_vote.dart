import 'package:cloud_firestore/cloud_firestore.dart';

enum VoteType {
  confirm,
  dismiss;

  String get value {
    switch (this) {
      case VoteType.confirm:
        return 'confirm';
      case VoteType.dismiss:
        return 'dismiss';
    }
  }

  static VoteType fromString(String value) {
    switch (value) {
      case 'confirm':
        return VoteType.confirm;
      case 'dismiss':
        return VoteType.dismiss;
      default:
        return VoteType.confirm;
    }
  }
}

class ReportVote {
  final String id;
  final String reportId;
  final String? userId;
  final VoteType voteType;
  final DateTime createdAt;

  ReportVote({
    required this.id,
    required this.reportId,
    this.userId,
    required this.voteType,
    required this.createdAt,
  });

  factory ReportVote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportVote(
      id: doc.id,
      reportId: data['report_id'] as String,
      userId: data['user_id'] as String?,
      voteType: VoteType.fromString(data['vote_type'] as String),
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'report_id': reportId,
      'user_id': userId,
      'vote_type': voteType.value,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}


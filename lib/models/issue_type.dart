enum IssueType {
  accident,
  construction,
  flood,
  treeFallen,
  protest,
  other;

  String get value {
    switch (this) {
      case IssueType.accident:
        return 'accident';
      case IssueType.construction:
        return 'construction';
      case IssueType.flood:
        return 'flood';
      case IssueType.treeFallen:
        return 'tree_fallen';
      case IssueType.protest:
        return 'protest';
      case IssueType.other:
        return 'other';
    }
  }

  static IssueType fromString(String value) {
    switch (value) {
      case 'checkpoint':
        // Legacy support - map checkpoint to other
        return IssueType.other;
      case 'accident':
        return IssueType.accident;
      case 'construction':
        return IssueType.construction;
      case 'flood':
        return IssueType.flood;
      case 'tree_fallen':
        return IssueType.treeFallen;
      case 'protest':
        return IssueType.protest;
      case 'other':
        return IssueType.other;
      default:
        return IssueType.other;
    }
  }
}


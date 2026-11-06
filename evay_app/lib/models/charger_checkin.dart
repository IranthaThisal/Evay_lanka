import 'package:cloud_firestore/cloud_firestore.dart';

enum CheckInOutcome {
  success,        // Successfully charged
  couldNotCharge, // Could not charge / issue encountered
  commentOnly;    // General comment or queue report

  String get label => switch (this) {
    CheckInOutcome.success => 'Successfully Charged',
    CheckInOutcome.couldNotCharge => 'Could Not Charge',
    CheckInOutcome.commentOnly => 'Status / Comment',
  };
}

enum CheckInIssue {
  none,
  noPower,          // Power cut / tripped breaker
  brokenConnector,  // Broken plug / damaged cable
  bayBlocked,       // Bay blocked by ICE or unauthorized vehicle
  paymentFailed,    // Payment / RFID reader failed
  stationClosed,    // Gate locked / restricted access
  other;

  String get label => switch (this) {
    CheckInIssue.none => 'No Issue',
    CheckInIssue.noPower => 'No Power / Tripped Breaker',
    CheckInIssue.brokenConnector => 'Broken Connector / Screen',
    CheckInIssue.bayBlocked => 'Bay Blocked (ICE-ing)',
    CheckInIssue.paymentFailed => 'Payment / RFID Failed',
    CheckInIssue.stationClosed => 'Gate Locked / Access Denied',
    CheckInIssue.other => 'Other Issue',
  };
}

class ChargerCheckIn {
  const ChargerCheckIn({
    required this.id,
    required this.chargerId,
    required this.chargerName,
    required this.userId,
    required this.userName,
    required this.outcome,
    this.issue = CheckInIssue.none,
    this.peakPowerKw,
    this.vehicleModel,
    this.comment = '',
    required this.createdAt,
  });

  final String id;
  final String chargerId;
  final String chargerName;
  final String userId;
  final String userName;
  final CheckInOutcome outcome;
  final CheckInIssue issue;
  final double? peakPowerKw;
  final String? vehicleModel;
  final String comment;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'chargerId': chargerId,
    'chargerName': chargerName,
    'userId': userId,
    'userName': userName,
    'outcome': outcome.name,
    'issue': issue.name,
    'peakPowerKw': peakPowerKw,
    'vehicleModel': vehicleModel,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  static ChargerCheckIn fromDoc(String id, Map<String, dynamic> data) {
    final outcomeStr = data['outcome']?.toString() ?? 'commentOnly';
    final issueStr = data['issue']?.toString() ?? 'none';

    final outcome = CheckInOutcome.values.firstWhere(
      (e) => e.name == outcomeStr,
      orElse: () => CheckInOutcome.commentOnly,
    );

    final issue = CheckInIssue.values.firstWhere(
      (e) => e.name == issueStr,
      orElse: () => CheckInIssue.none,
    );

    final ts = data['createdAt'];
    final createdAt = ts is Timestamp ? ts.toDate() : DateTime.now();

    return ChargerCheckIn(
      id: id,
      chargerId: (data['chargerId'] ?? '').toString(),
      chargerName: (data['chargerName'] ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      userName: (data['userName'] ?? 'EV Driver').toString(),
      outcome: outcome,
      issue: issue,
      peakPowerKw: (data['peakPowerKw'] as num?)?.toDouble(),
      vehicleModel: data['vehicleModel']?.toString(),
      comment: (data['comment'] ?? '').toString(),
      createdAt: createdAt,
    );
  }
}

class ChargerReliabilitySummary {
  const ChargerReliabilitySummary({
    required this.score,
    required this.totalCheckIns,
    required this.successCount,
    required this.failureCount,
    this.lastSuccessfulCheckIn,
    this.lastIssue,
    this.lastIssueTime,
  });

  final double score; // 0.0 to 10.0
  final int totalCheckIns;
  final int successCount;
  final int failureCount;
  final DateTime? lastSuccessfulCheckIn;
  final CheckInIssue? lastIssue;
  final DateTime? lastIssueTime;

  bool get isHighReliability => score >= 8.0;
  bool get isModerateReliability => score >= 5.0 && score < 8.0;
  bool get isLowReliability => score < 5.0;

  bool get isReportedDownRecently {
    if (lastIssueTime == null || lastIssue == null || lastIssue == CheckInIssue.none) {
      return false;
    }
    // Flagged down if an issue was reported within the last 4 hours
    return DateTime.now().difference(lastIssueTime!).inHours < 4;
  }
}

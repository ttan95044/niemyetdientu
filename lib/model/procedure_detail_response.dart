import 'package:niemyetdientu/model/procedure_detail.dart';

class ProcedureDetailResponse {
  final int count;
  final List<String> variantCodes;
  final List<ProcedureDetail> variants;

  ProcedureDetailResponse({
    required this.count,
    required this.variantCodes,
    required this.variants,
  });

  factory ProcedureDetailResponse.fromJson(Map<String, dynamic> json) {
    return ProcedureDetailResponse(
      count: json['count'] ?? 0,
      variantCodes: List<String>.from(json['variant_codes'] ?? []),
      variants: (json['variants'] as List? ?? [])
          .map((e) => ProcedureDetail.fromJson(e))
          .toList(),
    );
  }
}

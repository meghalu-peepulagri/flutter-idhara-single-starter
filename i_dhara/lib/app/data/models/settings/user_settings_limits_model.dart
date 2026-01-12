// To parse this JSON data, do
//
//     final userSettingsLimitsResponse = userSettingsLimitsResponseFromJson(jsonString);

import 'dart:convert';

UserSettingsLimitsResponse userSettingsLimitsResponseFromJson(String str) =>
    UserSettingsLimitsResponse.fromJson(json.decode(str));

String userSettingsLimitsResponseToJson(UserSettingsLimitsResponse data) =>
    json.encode(data.toJson());

class UserSettingsLimitsResponse {
  int? status;
  bool? success;
  String? message;
  UserSettingsLimits? data;

  UserSettingsLimitsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory UserSettingsLimitsResponse.fromJson(Map<String, dynamic> json) =>
      UserSettingsLimitsResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null
            ? null
            : UserSettingsLimits.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class UserSettingsLimits {
  int? id;
  int? starterId;
  int? dvcFlcMin;
  int? dvcFlcMax;
  int? dvcFltIpfMin;
  int? dvcFltIpfMax;
  int? dvcFltLvfMin;
  int? dvcFltLvfMax;
  int? dvcFltHvfMin;
  int? dvcFltHvfMax;
  int? dvcFltVifMin;
  int? dvcFltVifMax;
  int? dvcFltPaminfMin;
  int? dvcFltPaminfMax;
  int? dvcFltPamaxfMin;
  int? dvcFltPamaxfMax;
  int? dvcFltFminfMin;
  int? dvcFltFminfMax;
  int? dvcFltFmaxfMin;
  int? dvcFltFmaxfMax;
  int? dvcAltPfaMin;
  int? dvcAltPfaMax;
  int? dvcAltLvaMin;
  int? dvcAltLvaMax;
  int? dvcAltHvaMin;
  int? dvcAltHvaMax;
  int? dvcAltViaMin;
  int? dvcAltViaMax;
  int? dvcAltPaminaMin;
  int? dvcAltPaminaMax;
  int? dvcAltPamaxaMin;
  int? dvcAltPamaxaMax;
  int? dvcAltFminaMin;
  int? dvcAltFminaMax;
  double? dvcAltFmaxaMin;
  int? dvcAltFmaxaMax;
  int? dvcRecLvrMin;
  int? dvcRecLvrMax;
  int? dvcRecHvrMin;
  int? dvcRecHvrMax;
  int? mtrFltDrMin;
  int? mtrFltDrMax;
  int? mtrFltOlMin;
  int? mtrFltOlMax;
  int? mtrFltLrMin;
  int? mtrFltLrMax;
  int? mtrFltCiMin;
  int? mtrFltCiMax;
  int? mtrAltDrMin;
  int? mtrAltDrMax;
  int? mtrAltOlMin;
  int? mtrAltOlMax;
  int? mtrAltLrMin;
  int? mtrAltLrMax;
  int? mtrAltCiMin;
  int? mtrAltCiMax;
  double? mtrRecCiMin;
  int? mtrRecCiMax;
  int? atmlUgRMin;
  int? atmlUgRMax;
  int? atmlUgYMin;
  int? atmlUgYMax;
  int? atmlUgBMin;
  int? atmlUgBMax;
  int? atmlIgRMin;
  int? atmlIgRMax;
  int? atmlIgYMin;
  int? atmlIgYMax;
  int? atmlIgBMin;
  int? atmlIgBMax;
  int? atmlTpfMin;
  int? atmlTpfMax;
  int? frqDftLivFMin;
  int? frqDftLivFMax;
  int? frqHLivFMin;
  int? frqHLivFMax;
  int? frqMLivFMin;
  int? frqMLivFMax;
  int? frqLLivFMin;
  int? frqLLivFMax;
  int? frqPwrInfoFMin;
  int? frqPwrInfoFMax;
  DateTime? createdAt;
  DateTime? updatedAt;

  UserSettingsLimits({
    this.id,
    this.starterId,
    this.dvcFlcMin,
    this.dvcFlcMax,
    this.dvcFltIpfMin,
    this.dvcFltIpfMax,
    this.dvcFltLvfMin,
    this.dvcFltLvfMax,
    this.dvcFltHvfMin,
    this.dvcFltHvfMax,
    this.dvcFltVifMin,
    this.dvcFltVifMax,
    this.dvcFltPaminfMin,
    this.dvcFltPaminfMax,
    this.dvcFltPamaxfMin,
    this.dvcFltPamaxfMax,
    this.dvcFltFminfMin,
    this.dvcFltFminfMax,
    this.dvcFltFmaxfMin,
    this.dvcFltFmaxfMax,
    this.dvcAltPfaMin,
    this.dvcAltPfaMax,
    this.dvcAltLvaMin,
    this.dvcAltLvaMax,
    this.dvcAltHvaMin,
    this.dvcAltHvaMax,
    this.dvcAltViaMin,
    this.dvcAltViaMax,
    this.dvcAltPaminaMin,
    this.dvcAltPaminaMax,
    this.dvcAltPamaxaMin,
    this.dvcAltPamaxaMax,
    this.dvcAltFminaMin,
    this.dvcAltFminaMax,
    this.dvcAltFmaxaMin,
    this.dvcAltFmaxaMax,
    this.dvcRecLvrMin,
    this.dvcRecLvrMax,
    this.dvcRecHvrMin,
    this.dvcRecHvrMax,
    this.mtrFltDrMin,
    this.mtrFltDrMax,
    this.mtrFltOlMin,
    this.mtrFltOlMax,
    this.mtrFltLrMin,
    this.mtrFltLrMax,
    this.mtrFltCiMin,
    this.mtrFltCiMax,
    this.mtrAltDrMin,
    this.mtrAltDrMax,
    this.mtrAltOlMin,
    this.mtrAltOlMax,
    this.mtrAltLrMin,
    this.mtrAltLrMax,
    this.mtrAltCiMin,
    this.mtrAltCiMax,
    this.mtrRecCiMin,
    this.mtrRecCiMax,
    this.atmlUgRMin,
    this.atmlUgRMax,
    this.atmlUgYMin,
    this.atmlUgYMax,
    this.atmlUgBMin,
    this.atmlUgBMax,
    this.atmlIgRMin,
    this.atmlIgRMax,
    this.atmlIgYMin,
    this.atmlIgYMax,
    this.atmlIgBMin,
    this.atmlIgBMax,
    this.atmlTpfMin,
    this.atmlTpfMax,
    this.frqDftLivFMin,
    this.frqDftLivFMax,
    this.frqHLivFMin,
    this.frqHLivFMax,
    this.frqMLivFMin,
    this.frqMLivFMax,
    this.frqLLivFMin,
    this.frqLLivFMax,
    this.frqPwrInfoFMin,
    this.frqPwrInfoFMax,
    this.createdAt,
    this.updatedAt,
  });

  factory UserSettingsLimits.fromJson(Map<String, dynamic> json) =>
      UserSettingsLimits(
        id: json["id"],
        starterId: json["starter_id"],
        dvcFlcMin: json["dvc_flc_min"],
        dvcFlcMax: json["dvc_flc_max"],
        dvcFltIpfMin: json["dvc_flt_ipf_min"],
        dvcFltIpfMax: json["dvc_flt_ipf_max"],
        dvcFltLvfMin: json["dvc_flt_lvf_min"],
        dvcFltLvfMax: json["dvc_flt_lvf_max"],
        dvcFltHvfMin: json["dvc_flt_hvf_min"],
        dvcFltHvfMax: json["dvc_flt_hvf_max"],
        dvcFltVifMin: json["dvc_flt_vif_min"],
        dvcFltVifMax: json["dvc_flt_vif_max"],
        dvcFltPaminfMin: json["dvc_flt_paminf_min"],
        dvcFltPaminfMax: json["dvc_flt_paminf_max"],
        dvcFltPamaxfMin: json["dvc_flt_pamaxf_min"],
        dvcFltPamaxfMax: json["dvc_flt_pamaxf_max"],
        dvcFltFminfMin: json["dvc_flt_fminf_min"],
        dvcFltFminfMax: json["dvc_flt_fminf_max"],
        dvcFltFmaxfMin: json["dvc_flt_fmaxf_min"],
        dvcFltFmaxfMax: json["dvc_flt_fmaxf_max"],
        dvcAltPfaMin: json["dvc_alt_pfa_min"],
        dvcAltPfaMax: json["dvc_alt_pfa_max"],
        dvcAltLvaMin: json["dvc_alt_lva_min"],
        dvcAltLvaMax: json["dvc_alt_lva_max"],
        dvcAltHvaMin: json["dvc_alt_hva_min"],
        dvcAltHvaMax: json["dvc_alt_hva_max"],
        dvcAltViaMin: json["dvc_alt_via_min"],
        dvcAltViaMax: json["dvc_alt_via_max"],
        dvcAltPaminaMin: json["dvc_alt_pamina_min"],
        dvcAltPaminaMax: json["dvc_alt_pamina_max"],
        dvcAltPamaxaMin: json["dvc_alt_pamaxa_min"],
        dvcAltPamaxaMax: json["dvc_alt_pamaxa_max"],
        dvcAltFminaMin: json["dvc_alt_fmina_min"],
        dvcAltFminaMax: json["dvc_alt_fmina_max"],
        dvcAltFmaxaMin: json["dvc_alt_fmaxa_min"]?.toDouble(),
        dvcAltFmaxaMax: json["dvc_alt_fmaxa_max"],
        dvcRecLvrMin: json["dvc_rec_lvr_min"],
        dvcRecLvrMax: json["dvc_rec_lvr_max"],
        dvcRecHvrMin: json["dvc_rec_hvr_min"],
        dvcRecHvrMax: json["dvc_rec_hvr_max"],
        mtrFltDrMin: json["mtr_flt_dr_min"],
        mtrFltDrMax: json["mtr_flt_dr_max"],
        mtrFltOlMin: json["mtr_flt_ol_min"],
        mtrFltOlMax: json["mtr_flt_ol_max"],
        mtrFltLrMin: json["mtr_flt_lr_min"],
        mtrFltLrMax: json["mtr_flt_lr_max"],
        mtrFltCiMin: json["mtr_flt_ci_min"],
        mtrFltCiMax: json["mtr_flt_ci_max"],
        mtrAltDrMin: json["mtr_alt_dr_min"],
        mtrAltDrMax: json["mtr_alt_dr_max"],
        mtrAltOlMin: json["mtr_alt_ol_min"],
        mtrAltOlMax: json["mtr_alt_ol_max"],
        mtrAltLrMin: json["mtr_alt_lr_min"],
        mtrAltLrMax: json["mtr_alt_lr_max"],
        mtrAltCiMin: json["mtr_alt_ci_min"],
        mtrAltCiMax: json["mtr_alt_ci_max"],
        mtrRecCiMin: json["mtr_rec_ci_min"]?.toDouble(),
        mtrRecCiMax: json["mtr_rec_ci_max"],
        atmlUgRMin: json["atml_ug_r_min"],
        atmlUgRMax: json["atml_ug_r_max"],
        atmlUgYMin: json["atml_ug_y_min"],
        atmlUgYMax: json["atml_ug_y_max"],
        atmlUgBMin: json["atml_ug_b_min"],
        atmlUgBMax: json["atml_ug_b_max"],
        atmlIgRMin: json["atml_ig_r_min"],
        atmlIgRMax: json["atml_ig_r_max"],
        atmlIgYMin: json["atml_ig_y_min"],
        atmlIgYMax: json["atml_ig_y_max"],
        atmlIgBMin: json["atml_ig_b_min"],
        atmlIgBMax: json["atml_ig_b_max"],
        atmlTpfMin: json["atml_tpf_min"],
        atmlTpfMax: json["atml_tpf_max"],
        frqDftLivFMin: json["frq_dft_liv_f_min"],
        frqDftLivFMax: json["frq_dft_liv_f_max"],
        frqHLivFMin: json["frq_h_liv_f_min"],
        frqHLivFMax: json["frq_h_liv_f_max"],
        frqMLivFMin: json["frq_m_liv_f_min"],
        frqMLivFMax: json["frq_m_liv_f_max"],
        frqLLivFMin: json["frq_l_liv_f_min"],
        frqLLivFMax: json["frq_l_liv_f_max"],
        frqPwrInfoFMin: json["frq_pwr_info_f_min"],
        frqPwrInfoFMax: json["frq_pwr_info_f_max"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "starter_id": starterId,
        "dvc_flc_min": dvcFlcMin,
        "dvc_flc_max": dvcFlcMax,
        "dvc_flt_ipf_min": dvcFltIpfMin,
        "dvc_flt_ipf_max": dvcFltIpfMax,
        "dvc_flt_lvf_min": dvcFltLvfMin,
        "dvc_flt_lvf_max": dvcFltLvfMax,
        "dvc_flt_hvf_min": dvcFltHvfMin,
        "dvc_flt_hvf_max": dvcFltHvfMax,
        "dvc_flt_vif_min": dvcFltVifMin,
        "dvc_flt_vif_max": dvcFltVifMax,
        "dvc_flt_paminf_min": dvcFltPaminfMin,
        "dvc_flt_paminf_max": dvcFltPaminfMax,
        "dvc_flt_pamaxf_min": dvcFltPamaxfMin,
        "dvc_flt_pamaxf_max": dvcFltPamaxfMax,
        "dvc_flt_fminf_min": dvcFltFminfMin,
        "dvc_flt_fminf_max": dvcFltFminfMax,
        "dvc_flt_fmaxf_min": dvcFltFmaxfMin,
        "dvc_flt_fmaxf_max": dvcFltFmaxfMax,
        "dvc_alt_pfa_min": dvcAltPfaMin,
        "dvc_alt_pfa_max": dvcAltPfaMax,
        "dvc_alt_lva_min": dvcAltLvaMin,
        "dvc_alt_lva_max": dvcAltLvaMax,
        "dvc_alt_hva_min": dvcAltHvaMin,
        "dvc_alt_hva_max": dvcAltHvaMax,
        "dvc_alt_via_min": dvcAltViaMin,
        "dvc_alt_via_max": dvcAltViaMax,
        "dvc_alt_pamina_min": dvcAltPaminaMin,
        "dvc_alt_pamina_max": dvcAltPaminaMax,
        "dvc_alt_pamaxa_min": dvcAltPamaxaMin,
        "dvc_alt_pamaxa_max": dvcAltPamaxaMax,
        "dvc_alt_fmina_min": dvcAltFminaMin,
        "dvc_alt_fmina_max": dvcAltFminaMax,
        "dvc_alt_fmaxa_min": dvcAltFmaxaMin,
        "dvc_alt_fmaxa_max": dvcAltFmaxaMax,
        "dvc_rec_lvr_min": dvcRecLvrMin,
        "dvc_rec_lvr_max": dvcRecLvrMax,
        "dvc_rec_hvr_min": dvcRecHvrMin,
        "dvc_rec_hvr_max": dvcRecHvrMax,
        "mtr_flt_dr_min": mtrFltDrMin,
        "mtr_flt_dr_max": mtrFltDrMax,
        "mtr_flt_ol_min": mtrFltOlMin,
        "mtr_flt_ol_max": mtrFltOlMax,
        "mtr_flt_lr_min": mtrFltLrMin,
        "mtr_flt_lr_max": mtrFltLrMax,
        "mtr_flt_ci_min": mtrFltCiMin,
        "mtr_flt_ci_max": mtrFltCiMax,
        "mtr_alt_dr_min": mtrAltDrMin,
        "mtr_alt_dr_max": mtrAltDrMax,
        "mtr_alt_ol_min": mtrAltOlMin,
        "mtr_alt_ol_max": mtrAltOlMax,
        "mtr_alt_lr_min": mtrAltLrMin,
        "mtr_alt_lr_max": mtrAltLrMax,
        "mtr_alt_ci_min": mtrAltCiMin,
        "mtr_alt_ci_max": mtrAltCiMax,
        "mtr_rec_ci_min": mtrRecCiMin,
        "mtr_rec_ci_max": mtrRecCiMax,
        "atml_ug_r_min": atmlUgRMin,
        "atml_ug_r_max": atmlUgRMax,
        "atml_ug_y_min": atmlUgYMin,
        "atml_ug_y_max": atmlUgYMax,
        "atml_ug_b_min": atmlUgBMin,
        "atml_ug_b_max": atmlUgBMax,
        "atml_ig_r_min": atmlIgRMin,
        "atml_ig_r_max": atmlIgRMax,
        "atml_ig_y_min": atmlIgYMin,
        "atml_ig_y_max": atmlIgYMax,
        "atml_ig_b_min": atmlIgBMin,
        "atml_ig_b_max": atmlIgBMax,
        "atml_tpf_min": atmlTpfMin,
        "atml_tpf_max": atmlTpfMax,
        "frq_dft_liv_f_min": frqDftLivFMin,
        "frq_dft_liv_f_max": frqDftLivFMax,
        "frq_h_liv_f_min": frqHLivFMin,
        "frq_h_liv_f_max": frqHLivFMax,
        "frq_m_liv_f_min": frqMLivFMin,
        "frq_m_liv_f_max": frqMLivFMax,
        "frq_l_liv_f_min": frqLLivFMin,
        "frq_l_liv_f_max": frqLLivFMax,
        "frq_pwr_info_f_min": frqPwrInfoFMin,
        "frq_pwr_info_f_max": frqPwrInfoFMax,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
      };
}

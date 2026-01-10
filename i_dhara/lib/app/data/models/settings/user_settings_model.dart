// To parse this JSON data, do
//
//     final userSettingsResponse = userSettingsResponseFromJson(jsonString);

import 'dart:convert';

UserSettingsResponse userSettingsResponseFromJson(String str) =>
    UserSettingsResponse.fromJson(json.decode(str));

String userSettingsResponseToJson(UserSettingsResponse data) =>
    json.encode(data.toJson());

class UserSettingsResponse {
  int? status;
  bool? success;
  String? message;
  Data? data;

  UserSettingsResponse({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory UserSettingsResponse.fromJson(Map<String, dynamic> json) =>
      UserSettingsResponse(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class Data {
  int? id;
  int? dvcFltEn;
  int? dvcFlc;
  int? dvcSt;
  int? starterId;
  String? pcbNumber;
  int? dvcFltIpf;
  int? dvcFltLvf;
  int? dvcFltHvf;
  int? dvcFltVif;
  int? dvcFltPaminf;
  int? dvcFltPamaxf;
  int? dvcAltPfa;
  int? dvcAltLva;
  int? dvcAltHva;
  int? dvcAltVia;
  int? dvcAltPamina;
  int? dvcAltPamaxa;
  int? dvcRecLvr;
  int? dvcRecHvr;
  int? mtrFltDr;
  int? mtrFltOl;
  int? mtrFltLr;
  int? mtrFltOpf;
  int? mtrFltCi;
  int? mtrAltDr;
  int? mtrAltOl;
  int? mtrAltLr;
  int? mtrAltCi;
  int? mtrRecOl;
  int? mtrRecLr;
  int? mtrRecCi;
  int? atmlUgR;
  int? atmlUgY;
  int? atmlUgB;
  int? atmlIgR;
  int? atmlIgY;
  int? atmlIgB;
  String? mqtCaFn;
  String? mqtBkrAdrs;
  String? mqtCId;
  String? mqtEmqxUsrn;
  String? mqtEmqxPswd;
  String? mqtProdHttp;
  String? mqtBkpHttp;
  int? mqtBkrPort;
  int? mqtCeLen;
  String? ivrsSmsPswd;
  int? ivrsCLang;
  List<dynamic>? ivrsAuthNum;
  int? frqDftLivF;
  int? frqHLivF;
  int? frqMLivF;
  int? frqLLivF;
  int? frqPwrInfoF;
  int? featsIvrsEn;
  int? featsSmsEn;
  int? featsRmtEn;
  int? fltEnIpf;
  int? fltEnLvf;
  int? fltEnHvf;
  int? fltEnVif;
  int? fltEnDr;
  int? fltEnOl;
  int? fltEnLr;
  int? fltEnOpf;
  int? fltEnCi;
  DateTime? timeStamp;
  int? isNewConfigurationSaved;
  String? acknowledgement;
  int? createdBy;
  DateTime? createdAt;
  DateTime? updatedAt;
  Starter? starter;

  Data({
    this.id,
    this.dvcFltEn,
    this.dvcFlc,
    this.dvcSt,
    this.starterId,
    this.pcbNumber,
    this.dvcFltIpf,
    this.dvcFltLvf,
    this.dvcFltHvf,
    this.dvcFltVif,
    this.dvcFltPaminf,
    this.dvcFltPamaxf,
    this.dvcAltPfa,
    this.dvcAltLva,
    this.dvcAltHva,
    this.dvcAltVia,
    this.dvcAltPamina,
    this.dvcAltPamaxa,
    this.dvcRecLvr,
    this.dvcRecHvr,
    this.mtrFltDr,
    this.mtrFltOl,
    this.mtrFltLr,
    this.mtrFltOpf,
    this.mtrFltCi,
    this.mtrAltDr,
    this.mtrAltOl,
    this.mtrAltLr,
    this.mtrAltCi,
    this.mtrRecOl,
    this.mtrRecLr,
    this.mtrRecCi,
    this.atmlUgR,
    this.atmlUgY,
    this.atmlUgB,
    this.atmlIgR,
    this.atmlIgY,
    this.atmlIgB,
    this.mqtCaFn,
    this.mqtBkrAdrs,
    this.mqtCId,
    this.mqtEmqxUsrn,
    this.mqtEmqxPswd,
    this.mqtProdHttp,
    this.mqtBkpHttp,
    this.mqtBkrPort,
    this.mqtCeLen,
    this.ivrsSmsPswd,
    this.ivrsCLang,
    this.ivrsAuthNum,
    this.frqDftLivF,
    this.frqHLivF,
    this.frqMLivF,
    this.frqLLivF,
    this.frqPwrInfoF,
    this.featsIvrsEn,
    this.featsSmsEn,
    this.featsRmtEn,
    this.fltEnIpf,
    this.fltEnLvf,
    this.fltEnHvf,
    this.fltEnVif,
    this.fltEnDr,
    this.fltEnOl,
    this.fltEnLr,
    this.fltEnOpf,
    this.fltEnCi,
    this.timeStamp,
    this.isNewConfigurationSaved,
    this.acknowledgement,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.starter,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        id: json["id"],
        dvcFltEn: json["dvc_flt_en"],
        dvcFlc: json["dvc_flc"],
        dvcSt: json["dvc_st"],
        starterId: json["starter_id"],
        pcbNumber: json["pcb_number"],
        dvcFltIpf: json["dvc_flt_ipf"],
        dvcFltLvf: json["dvc_flt_lvf"],
        dvcFltHvf: json["dvc_flt_hvf"],
        dvcFltVif: json["dvc_flt_vif"],
        dvcFltPaminf: json["dvc_flt_paminf"],
        dvcFltPamaxf: json["dvc_flt_pamaxf"],
        dvcAltPfa: json["dvc_alt_pfa"],
        dvcAltLva: json["dvc_alt_lva"],
        dvcAltHva: json["dvc_alt_hva"],
        dvcAltVia: json["dvc_alt_via"],
        dvcAltPamina: json["dvc_alt_pamina"],
        dvcAltPamaxa: json["dvc_alt_pamaxa"],
        dvcRecLvr: json["dvc_rec_lvr"],
        dvcRecHvr: json["dvc_rec_hvr"],
        mtrFltDr: json["mtr_flt_dr"],
        mtrFltOl: json["mtr_flt_ol"],
        mtrFltLr: json["mtr_flt_lr"],
        mtrFltOpf: json["mtr_flt_opf"],
        mtrFltCi: json["mtr_flt_ci"],
        mtrAltDr: json["mtr_alt_dr"],
        mtrAltOl: json["mtr_alt_ol"],
        mtrAltLr: json["mtr_alt_lr"],
        mtrAltCi: json["mtr_alt_ci"],
        mtrRecOl: json["mtr_rec_ol"],
        mtrRecLr: json["mtr_rec_lr"],
        mtrRecCi: json["mtr_rec_ci"],
        atmlUgR: json["atml_ug_r"],
        atmlUgY: json["atml_ug_y"],
        atmlUgB: json["atml_ug_b"],
        atmlIgR: json["atml_ig_r"],
        atmlIgY: json["atml_ig_y"],
        atmlIgB: json["atml_ig_b"],
        mqtCaFn: json["mqt_ca_fn"],
        mqtBkrAdrs: json["mqt_bkr_adrs"],
        mqtCId: json["mqt_c_id"],
        mqtEmqxUsrn: json["mqt_emqx_usrn"],
        mqtEmqxPswd: json["mqt_emqx_pswd"],
        mqtProdHttp: json["mqt_prod_http"],
        mqtBkpHttp: json["mqt_bkp_http"],
        mqtBkrPort: json["mqt_bkr_port"],
        mqtCeLen: json["mqt_ce_len"],
        ivrsSmsPswd: json["ivrs_sms_pswd"],
        ivrsCLang: json["ivrs_c_lang"],
        ivrsAuthNum: json["ivrs_auth_num"] == null
            ? []
            : List<dynamic>.from(json["ivrs_auth_num"]!.map((x) => x)),
        frqDftLivF: json["frq_dft_liv_f"],
        frqHLivF: json["frq_h_liv_f"],
        frqMLivF: json["frq_m_liv_f"],
        frqLLivF: json["frq_l_liv_f"],
        frqPwrInfoF: json["frq_pwr_info_f"],
        featsIvrsEn: json["feats_ivrs_en"],
        featsSmsEn: json["feats_sms_en"],
        featsRmtEn: json["feats_rmt_en"],
        fltEnIpf: json["flt_en_ipf"],
        fltEnLvf: json["flt_en_lvf"],
        fltEnHvf: json["flt_en_hvf"],
        fltEnVif: json["flt_en_vif"],
        fltEnDr: json["flt_en_dr"],
        fltEnOl: json["flt_en_ol"],
        fltEnLr: json["flt_en_lr"],
        fltEnOpf: json["flt_en_opf"],
        fltEnCi: json["flt_en_ci"],
        timeStamp: json["time_stamp"] == null
            ? null
            : DateTime.parse(json["time_stamp"]),
        isNewConfigurationSaved: json["is_new_configuration_saved"],
        acknowledgement: json["acknowledgement"],
        createdBy: json["created_by"],
        createdAt: json["created_at"] == null
            ? null
            : DateTime.parse(json["created_at"]),
        updatedAt: json["updated_at"] == null
            ? null
            : DateTime.parse(json["updated_at"]),
        starter:
            json["starter"] == null ? null : Starter.fromJson(json["starter"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "dvc_flt_en": dvcFltEn,
        "dvc_flc": dvcFlc,
        "dvc_st": dvcSt,
        "starter_id": starterId,
        "pcb_number": pcbNumber,
        "dvc_flt_ipf": dvcFltIpf,
        "dvc_flt_lvf": dvcFltLvf,
        "dvc_flt_hvf": dvcFltHvf,
        "dvc_flt_vif": dvcFltVif,
        "dvc_flt_paminf": dvcFltPaminf,
        "dvc_flt_pamaxf": dvcFltPamaxf,
        "dvc_alt_pfa": dvcAltPfa,
        "dvc_alt_lva": dvcAltLva,
        "dvc_alt_hva": dvcAltHva,
        "dvc_alt_via": dvcAltVia,
        "dvc_alt_pamina": dvcAltPamina,
        "dvc_alt_pamaxa": dvcAltPamaxa,
        "dvc_rec_lvr": dvcRecLvr,
        "dvc_rec_hvr": dvcRecHvr,
        "mtr_flt_dr": mtrFltDr,
        "mtr_flt_ol": mtrFltOl,
        "mtr_flt_lr": mtrFltLr,
        "mtr_flt_opf": mtrFltOpf,
        "mtr_flt_ci": mtrFltCi,
        "mtr_alt_dr": mtrAltDr,
        "mtr_alt_ol": mtrAltOl,
        "mtr_alt_lr": mtrAltLr,
        "mtr_alt_ci": mtrAltCi,
        "mtr_rec_ol": mtrRecOl,
        "mtr_rec_lr": mtrRecLr,
        "mtr_rec_ci": mtrRecCi,
        "atml_ug_r": atmlUgR,
        "atml_ug_y": atmlUgY,
        "atml_ug_b": atmlUgB,
        "atml_ig_r": atmlIgR,
        "atml_ig_y": atmlIgY,
        "atml_ig_b": atmlIgB,
        "mqt_ca_fn": mqtCaFn,
        "mqt_bkr_adrs": mqtBkrAdrs,
        "mqt_c_id": mqtCId,
        "mqt_emqx_usrn": mqtEmqxUsrn,
        "mqt_emqx_pswd": mqtEmqxPswd,
        "mqt_prod_http": mqtProdHttp,
        "mqt_bkp_http": mqtBkpHttp,
        "mqt_bkr_port": mqtBkrPort,
        "mqt_ce_len": mqtCeLen,
        "ivrs_sms_pswd": ivrsSmsPswd,
        "ivrs_c_lang": ivrsCLang,
        "ivrs_auth_num": ivrsAuthNum == null
            ? []
            : List<dynamic>.from(ivrsAuthNum!.map((x) => x)),
        "frq_dft_liv_f": frqDftLivF,
        "frq_h_liv_f": frqHLivF,
        "frq_m_liv_f": frqMLivF,
        "frq_l_liv_f": frqLLivF,
        "frq_pwr_info_f": frqPwrInfoF,
        "feats_ivrs_en": featsIvrsEn,
        "feats_sms_en": featsSmsEn,
        "feats_rmt_en": featsRmtEn,
        "flt_en_ipf": fltEnIpf,
        "flt_en_lvf": fltEnLvf,
        "flt_en_hvf": fltEnHvf,
        "flt_en_vif": fltEnVif,
        "flt_en_dr": fltEnDr,
        "flt_en_ol": fltEnOl,
        "flt_en_lr": fltEnLr,
        "flt_en_opf": fltEnOpf,
        "flt_en_ci": fltEnCi,
        "time_stamp": timeStamp?.toIso8601String(),
        "is_new_configuration_saved": isNewConfigurationSaved,
        "acknowledgement": acknowledgement,
        "created_by": createdBy,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "starter": starter?.toJson(),
      };
}

class Starter {
  int? id;
  dynamic name;
  String? pcbNumber;
  String? macAddress;

  Starter({
    this.id,
    this.name,
    this.pcbNumber,
    this.macAddress,
  });

  factory Starter.fromJson(Map<String, dynamic> json) => Starter(
        id: json["id"],
        name: json["name"],
        pcbNumber: json["pcb_number"],
        macAddress: json["mac_address"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "pcb_number": pcbNumber,
        "mac_address": macAddress,
      };
}

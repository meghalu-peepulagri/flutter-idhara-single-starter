// To parse this JSON data, do
//
//     final userUpdateSettingsDto = userUpdateSettingsDtoFromJson(jsonString);

import 'dart:convert';

UserUpdateSettingsDto userUpdateSettingsDtoFromJson(String str) =>
    UserUpdateSettingsDto.fromJson(json.decode(str));

String userUpdateSettingsDtoToJson(UserUpdateSettingsDto data) =>
    json.encode(data.toJson());

/* ---------------- SAFE PARSERS ---------------- */

double? parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? parseInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

/* ---------------- DTO MODEL ---------------- */

class UserUpdateSettingsDto {
  int? starterId;
  dynamic multiMotorConfig;
  int? allfltEn;

  /// 🔥 FIXED
  double? flc;

  int? asDly;
  int? prFltEn;
  int? tpf;
  int? vEn;
  int? cEn;
  int? ipf;
  int? lvf;
  int? hvf;
  int? vif;
  int? paminf;
  int? pamaxf;
  int? fDr;
  int? fOl;
  int? fLr;
  num? limit;

  /// decimals
  double? fOpf;

  int? fCi;
  int? pfa;
  int? lva;
  int? hva;
  int? via;
  int? pamina;
  int? pamaxa;
  int? dr;
  int? ol;
  int? lr;
  int? ci;
  int? lvr;
  int? hvr;
  int? olf;
  int? lrf;

  /// decimals
  double? opf;
  double? cif;

  int? drf;
  int? olr;
  int? lrr;
  int? cir;

  int? vfltUnderVoltage;
  int? vfltOverVoltage;
  int? vfltVoltageImbalance;
  int? vfltPhaseFailure;
  int? cfltDryRun;
  int? cfltOverCurrent;
  int? cfltOutputPhaseFail;
  int? cfltCurrImbalance;

  int? ugR;
  int? ugY;
  int? ugB;
  int? ipR;
  int? ipY;
  int? ipB;
  int? vgR;
  int? vgY;
  int? vgB;
  int? voR;
  int? voY;
  int? voB;
  int? igR;
  int? igY;
  int? igB;
  int? ioR;
  int? ioY;
  int? ioB;

  int? r1;
  int? r2;
  int? off;

  String? caFn;
  String? bkrAdrs;
  String? sn;
  String? usrn;
  String? pswd;
  String? prdUrl;
  int? port;
  int? crtEn;
  String? smsPswd;
  int? cLang;

  List<String>? authNum;

  int? dftLivF;
  int? hLivF;
  int? mLivF;
  int? lLivF;
  int? pwrInfoF;
  int? ivrsEn;
  int? smsEn;
  int? rmtEn;

  UserUpdateSettingsDto({
    this.starterId,
    this.multiMotorConfig,
    this.allfltEn,
    this.flc,
    this.asDly,
    this.prFltEn,
    this.tpf,
    this.vEn,
    this.cEn,
    this.ipf,
    this.lvf,
    this.hvf,
    this.vif,
    this.paminf,
    this.pamaxf,
    this.fDr,
    this.fOl,
    this.fLr,
    this.fOpf,
    this.fCi,
    this.pfa,
    this.lva,
    this.hva,
    this.via,
    this.pamina,
    this.pamaxa,
    this.dr,
    this.ol,
    this.lr,
    this.ci,
    this.lvr,
    this.hvr,
    this.olf,
    this.lrf,
    this.opf,
    this.cif,
    this.drf,
    this.olr,
    this.lrr,
    this.cir,
    this.limit,
    this.vfltUnderVoltage,
    this.vfltOverVoltage,
    this.vfltVoltageImbalance,
    this.vfltPhaseFailure,
    this.cfltDryRun,
    this.cfltOverCurrent,
    this.cfltOutputPhaseFail,
    this.cfltCurrImbalance,
    this.ugR,
    this.ugY,
    this.ugB,
    this.ipR,
    this.ipY,
    this.ipB,
    this.vgR,
    this.vgY,
    this.vgB,
    this.voR,
    this.voY,
    this.voB,
    this.igR,
    this.igY,
    this.igB,
    this.ioR,
    this.ioY,
    this.ioB,
    this.r1,
    this.r2,
    this.off,
    this.caFn,
    this.bkrAdrs,
    this.sn,
    this.usrn,
    this.pswd,
    this.prdUrl,
    this.port,
    this.crtEn,
    this.smsPswd,
    this.cLang,
    this.authNum,
    this.dftLivF,
    this.hLivF,
    this.mLivF,
    this.lLivF,
    this.pwrInfoF,
    this.ivrsEn,
    this.smsEn,
    this.rmtEn,
  });

  factory UserUpdateSettingsDto.fromJson(Map<String, dynamic> json) =>
      UserUpdateSettingsDto(
        starterId: parseInt(json["starter_id"]),
        multiMotorConfig: json["multi_motor_config"],
        allfltEn: parseInt(json["allflt_en"]),
        flc: parseDouble(json["flc"]), // 🔥 FIXED
        asDly: parseInt(json["as_dly"]),
        prFltEn: parseInt(json["pr_flt_en"]),
        tpf: parseInt(json["tpf"]),
        vEn: parseInt(json["v_en"]),
        cEn: parseInt(json["c_en"]),
        ipf: parseInt(json["ipf"]),
        lvf: parseInt(json["lvf"]),
        hvf: parseInt(json["hvf"]),
        vif: parseInt(json["vif"]),
        paminf: parseInt(json["paminf"]),
        pamaxf: parseInt(json["pamaxf"]),
        fDr: parseInt(json["f_dr"]),
        fOl: parseInt(json["f_ol"]),
        fLr: parseInt(json["f_lr"]),
        fOpf: parseDouble(json["f_opf"]),
        fCi: parseInt(json["f_ci"]),
        pfa: parseInt(json["pfa"]),
        lva: parseInt(json["lva"]),
        hva: parseInt(json["hva"]),
        via: parseInt(json["via"]),
        limit: json["limit"],
        pamina: parseInt(json["pamina"]),
        pamaxa: parseInt(json["pamaxa"]),
        dr: parseInt(json["dr"]),
        ol: parseInt(json["ol"]),
        lr: parseInt(json["lr"]),
        ci: parseInt(json["ci"]),
        lvr: parseInt(json["lvr"]),
        hvr: parseInt(json["hvr"]),
        olf: parseInt(json["olf"]),
        lrf: parseInt(json["lrf"]),
        opf: parseDouble(json["opf"]),
        cif: parseDouble(json["cif"]),
        drf: parseInt(json["drf"]),
        olr: parseInt(json["olr"]),
        lrr: parseInt(json["lrr"]),
        cir: parseInt(json["cir"]),
        vfltUnderVoltage: json["vflt_under_voltage"],
        vfltOverVoltage: json["vflt_over_voltage"],
        vfltVoltageImbalance: json["vflt_voltage_imbalance"],
        vfltPhaseFailure: json["vflt_phase_failure"],
        cfltDryRun: json["cflt_dry_run"],
        cfltOverCurrent: json["cflt_over_current"],
        cfltOutputPhaseFail: json["cflt_output_phase_fail"],
        cfltCurrImbalance: json["cflt_curr_imbalance"],
        ugR: parseInt(json["ug_r"]),
        ugY: parseInt(json["ug_y"]),
        ugB: parseInt(json["ug_b"]),
        ipR: parseInt(json["ip_r"]),
        ipY: parseInt(json["ip_y"]),
        ipB: parseInt(json["ip_b"]),
        vgR: parseInt(json["vg_r"]),
        vgY: parseInt(json["vg_y"]),
        vgB: parseInt(json["vg_b"]),
        voR: parseInt(json["vo_r"]),
        voY: parseInt(json["vo_y"]),
        voB: parseInt(json["vo_b"]),
        igR: parseInt(json["ig_r"]),
        igY: parseInt(json["ig_y"]),
        igB: parseInt(json["ig_b"]),
        ioR: parseInt(json["io_r"]),
        ioY: parseInt(json["io_y"]),
        ioB: parseInt(json["io_b"]),
        r1: parseInt(json["r1"]),
        r2: parseInt(json["r2"]),
        off: parseInt(json["off"]),
        caFn: json["ca_fn"],
        bkrAdrs: json["bkr_adrs"],
        sn: json["sn"]?.toString(),
        usrn: json["usrn"],
        pswd: json["pswd"],
        prdUrl: json["prd_url"],
        port: parseInt(json["port"]),
        crtEn: parseInt(json["crt_en"]),
        smsPswd: json["sms_pswd"],
        cLang: parseInt(json["c_lang"]),
        authNum: json["auth_num"] == null
            ? []
            : List<String>.from(json["auth_num"].map((x) => x.toString())),
        dftLivF: parseInt(json["dft_liv_f"]),
        hLivF: parseInt(json["h_liv_f"]),
        mLivF: parseInt(json["m_liv_f"]),
        lLivF: parseInt(json["l_liv_f"]),
        pwrInfoF: parseInt(json["pwr_info_f"]),
        ivrsEn: parseInt(json["ivrs_en"]),
        smsEn: parseInt(json["sms_en"]),
        rmtEn: parseInt(json["rmt_en"]),
      );

  Map<String, dynamic> toJson() => {
        "starter_id": starterId,
        "allflt_en": allfltEn,
        "flc": flc,
        "as_dly": asDly,
        "pr_flt_en": prFltEn,
        "tpf": tpf,
        "v_en": vEn,
        "c_en": cEn,
        "ipf": ipf,
        "lvf": lvf,
        "hvf": hvf,
        "vif": vif,
        "paminf": paminf,
        "pamaxf": pamaxf,
        "f_dr": fDr,
        "f_ol": fOl,
        "f_lr": fLr,
        "f_opf": fOpf,
        "limit": limit,
        "f_ci": fCi,
        "pfa": pfa,
        "lva": lva,
        "hva": hva,
        "via": via,
        "pamina": pamina,
        "pamaxa": pamaxa,
        "dr": dr,
        "ol": ol,
        "lr": lr,
        "ci": ci,
        "lvr": lvr,
        "hvr": hvr,
        "olf": olf,
        "lrf": lrf,
        "opf": opf,
        "cif": cif,
        "drf": drf,
        "olr": olr,
        "lrr": lrr,
        "cir": cir,
        "vflt_under_voltage": vfltUnderVoltage,
        "vflt_over_voltage": vfltOverVoltage,
        "vflt_voltage_imbalance": vfltVoltageImbalance,
        "vflt_phase_failure": vfltPhaseFailure,
        "cflt_dry_run": cfltDryRun,
        "cflt_over_current": cfltOverCurrent,
        "cflt_output_phase_fail": cfltOutputPhaseFail,
        "cflt_curr_imbalance": cfltCurrImbalance,
        "ug_r": ugR,
        "ug_y": ugY,
        "ug_b": ugB,
        "ip_r": ipR,
        "ip_y": ipY,
        "ip_b": ipB,
        "vg_r": vgR,
        "vg_y": vgY,
        "vg_b": vgB,
        "vo_r": voR,
        "vo_y": voY,
        "vo_b": voB,
        "ig_r": igR,
        "ig_y": igY,
        "ig_b": igB,
        "io_r": ioR,
        "io_y": ioY,
        "io_b": ioB,
        "r1": r1,
        "r2": r2,
        "off": off,
        "ca_fn": caFn,
        "bkr_adrs": bkrAdrs,
        "sn": sn,
        "usrn": usrn,
        "pswd": pswd,
        "prd_url": prdUrl,
        "port": port,
        "crt_en": crtEn,
        "sms_pswd": smsPswd,
        "c_lang": cLang,
        "auth_num": authNum ?? [],
        "dft_liv_f": dftLivF,
        "h_liv_f": hLivF,
        "m_liv_f": mLivF,
        "l_liv_f": lLivF,
        "pwr_info_f": pwrInfoF,
        "ivrs_en": ivrsEn,
        "sms_en": smsEn,
        "rmt_en": rmtEn,
        ...(multiMotorConfig == null
            ? <String, dynamic>{}
            : {"multi_motor_config": multiMotorConfig}),
      };
}

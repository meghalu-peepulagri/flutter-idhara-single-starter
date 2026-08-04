// To parse this JSON data, do
//
//     final userSettingsResponse2 = userSettingsResponse2FromJson(jsonString);

import 'dart:convert';

UserSettingsResponse2 userSettingsResponse2FromJson(String str) =>
    UserSettingsResponse2.fromJson(json.decode(str));

String userSettingsResponse2ToJson(UserSettingsResponse2 data) =>
    json.encode(data.toJson());

class UserSettingsResponse2 {
  int? status;
  bool? success;
  String? message;
  UserSettings2? data;

  UserSettingsResponse2({
    this.status,
    this.success,
    this.message,
    this.data,
  });

  factory UserSettingsResponse2.fromJson(Map<String, dynamic> json) =>
      UserSettingsResponse2(
        status: json["status"],
        success: json["success"],
        message: json["message"],
        data:
            json["data"] == null ? null : UserSettings2.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "success": success,
        "message": message,
        "data": data?.toJson(),
      };
}

class UserSettings2 {
  int? id;
  int? starterId;
  int? allfltEn;
  num? flc;
  int? asDly;
  int? prFltEn;
  int? tpf;
  int? vEn;
  int? cEn;
  num? ipf;
  int? lvf;
  int? hvf;
  num? vif;
  int? paminf;
  int? pamaxf;
  num? fDr;
  int? fOl;
  int? fLr;
  num? fOpf;
  num? fCi;
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
  num? lvr;
  num? hvr;
  num? olf;
  num? lrf;
  num? opf;
  num? cif;
  num? drf;
  num? olr;
  num? lrr;
  num? cir;
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
  num? vgR;
  num? vgY;
  num? vgB;
  num? voR;
  num? voY;
  num? voB;
  num? igR;
  num? igY;
  num? igB;
  num? ioR;
  num? ioY;
  num? ioB;
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
  List<dynamic>? authNum; // Changed to dynamic to handle both num and String
  int? dftLivF;
  int? hLivF;
  int? mLivF;
  int? lLivF;
  int? pwrInfoF;
  int? ivrsEn;
  int? smsEn;
  int? rmtEn;
  num? limit;
  MultiMotorConfig? multiMotorConfig;
  DateTime? timeStamp;
  int? isNewConfigurationSaved;
  String? acknowledgement;
  int? createdBy;
  DateTime? createdAt;
  DateTime? updatedAt;
  SettingStarter? starter;

  UserSettings2({
    this.id,
    this.starterId,
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
    this.limit,
    this.multiMotorConfig,
    this.timeStamp,
    this.isNewConfigurationSaved,
    this.acknowledgement,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.starter,
  });

  factory UserSettings2.fromJson(Map<String, dynamic> json) => UserSettings2(
        id: json["id"],
        starterId: json["starter_id"],
        allfltEn: json["allflt_en"],
        flc: json["flc"],
        asDly: json["as_dly"],
        prFltEn: json["pr_flt_en"],
        tpf: json["tpf"],
        vEn: json["v_en"],
        cEn: json["c_en"],
        ipf: json["ipf"],
        lvf: json["lvf"],
        hvf: json["hvf"],
        vif: json["vif"],
        paminf: json["paminf"],
        pamaxf: json["pamaxf"],
        fDr: json["f_dr"],
        fOl: json["f_ol"],
        fLr: json["f_lr"],
        fOpf: json["f_opf"],
        fCi: json["f_ci"],
        pfa: json["pfa"],
        lva: json["lva"],
        hva: json["hva"],
        via: json["via"],
        pamina: json["pamina"],
        pamaxa: json["pamaxa"],
        dr: json["dr"],
        ol: json["ol"],
        lr: json["lr"],
        ci: json["ci"],
        lvr: json["lvr"],
        hvr: json["hvr"],
        olf: json["olf"],
        lrf: json["lrf"],
        opf: json["opf"],
        cif: json["cif"],
        drf: json["drf"],
        olr: json["olr"],
        lrr: json["lrr"],
        cir: json["cir"],
        vfltUnderVoltage: json["vflt_under_voltage"],
        vfltOverVoltage: json["vflt_over_voltage"],
        vfltVoltageImbalance: json["vflt_voltage_imbalance"],
        vfltPhaseFailure: json["vflt_phase_failure"],
        cfltDryRun: json["cflt_dry_run"],
        cfltOverCurrent: json["cflt_over_current"],
        cfltOutputPhaseFail: json["cflt_output_phase_fail"],
        cfltCurrImbalance: json["cflt_curr_imbalance"],
        ugR: json["ug_r"],
        ugY: json["ug_y"],
        ugB: json["ug_b"],
        ipR: json["ip_r"],
        ipY: json["ip_y"],
        ipB: json["ip_b"],
        vgR: json["vg_r"],
        vgY: json["vg_y"],
        vgB: json["vg_b"],
        voR: json["vo_r"],
        voY: json["vo_y"],
        voB: json["vo_b"],
        igR: json["ig_r"],
        igY: json["ig_y"],
        igB: json["ig_b"],
        ioR: json["io_r"],
        ioY: json["io_y"],
        ioB: json["io_b"],
        r1: json["r1"],
        r2: json["r2"],
        off: json["off"],
        caFn: json["ca_fn"],
        limit: json["limit"],
        bkrAdrs: json["bkr_adrs"],
        sn: json["sn"],
        usrn: json["usrn"],
        pswd: json["pswd"],
        prdUrl: json["prd_url"],
        port: json["port"],
        crtEn: json["crt_en"],
        smsPswd: json["sms_pswd"],
        cLang: json["c_lang"],
        authNum: json["auth_num"] == null
            ? []
            : List<dynamic>.from(json["auth_num"]!.map((x) => x)),
        dftLivF: json["dft_liv_f"],
        hLivF: json["h_liv_f"],
        mLivF: json["m_liv_f"],
        lLivF: json["l_liv_f"],
        pwrInfoF: json["pwr_info_f"],
        ivrsEn: json["ivrs_en"],
        smsEn: json["sms_en"],
        rmtEn: json["rmt_en"],
        multiMotorConfig: json["multi_motor_config"] == null
            ? null
            : MultiMotorConfig.fromJson(json["multi_motor_config"]),
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
        starter: json["starter"] == null
            ? null
            : SettingStarter.fromJson(json["starter"]),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
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
        "limit": limit,
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
        "auth_num":
            authNum == null ? [] : List<dynamic>.from(authNum!.map((x) => x)),
        "dft_liv_f": dftLivF,
        "h_liv_f": hLivF,
        "m_liv_f": mLivF,
        "l_liv_f": lLivF,
        "pwr_info_f": pwrInfoF,
        "ivrs_en": ivrsEn,
        "sms_en": smsEn,
        "rmt_en": rmtEn,
        "multi_motor_config": multiMotorConfig?.toJson(),
        "time_stamp": timeStamp?.toIso8601String(),
        "is_new_configuration_saved": isNewConfigurationSaved,
        "acknowledgement": acknowledgement,
        "created_by": createdBy,
        "created_at": createdAt?.toIso8601String(),
        "updated_at": updatedAt?.toIso8601String(),
        "starter": starter?.toJson(),
      };
}

class SettingStarter {
  int? id;
  dynamic name;
  String? pcbNumber;
  String? macAddress;
  String? deviceAllocation;
  String? motorStarterType;

  List<SettingMotor>? motors;

  SettingStarter(
      {this.id,
      this.name,
      this.pcbNumber,
      this.macAddress,
      this.motors,
      this.motorStarterType,
      this.deviceAllocation});

  factory SettingStarter.fromJson(Map<String, dynamic> json) => SettingStarter(
        id: json["id"],
        name: json["name"],
        pcbNumber: json["pcb_number"],
        macAddress: json["mac_address"],
        deviceAllocation: json["device_allocation"],
        motorStarterType: json["motor_starter_type"],
        motors: json["motors"] == null
            ? []
            : List<SettingMotor>.from(
                json["motors"]!.map((x) => SettingMotor.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "pcb_number": pcbNumber,
        "mac_address": macAddress,
        "device_allocation": deviceAllocation,
        "motor_starter_type": motorStarterType,
        "motors": motors == null
            ? []
            : List<dynamic>.from(motors!.map((x) => x.toJson())),
      };
}

class SettingMotor {
  int? id;
  String? name;
  dynamic hp; // Changed to dynamic to handle both int, double, and String
  String? aliasName;

  SettingMotor({
    this.id,
    this.name,
    this.hp,
    this.aliasName,
  });

  factory SettingMotor.fromJson(Map<String, dynamic> json) => SettingMotor(
        id: json["id"],
        name: json["name"],
        hp: json["hp"], // Will accept any type
        aliasName: json["alias_name"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "hp": hp,
        "alias_name": aliasName,
      };
}

class MultiMotorConfig {
  List<MotorSettingConfig>? motors;
  num? sdTime;
  int? vFltEn;

  MultiMotorConfig({
    this.motors,
    this.sdTime,
    this.vFltEn,
  });

  factory MultiMotorConfig.fromJson(Map<String, dynamic> json) =>
      MultiMotorConfig(
        motors: json["motors"] == null
            ? []
            : List<MotorSettingConfig>.from(
                json["motors"]!.map((x) => MotorSettingConfig.fromJson(x))),
        sdTime: json["sd_time"],
        vFltEn: json["v_flt_en"],
      );

  Map<String, dynamic> toJson() => {
        "motors": motors == null
            ? []
            : List<dynamic>.from(motors!.map((x) => x.toJson())),
        "sd_time": sdTime,
        "v_flt_en": vFltEn,
      };
}

class MotorSettingConfig {
  num? cif;
  num? drf;
  num? flc;
  num? lrf;
  num? olf;
  num? opf;
  num? igB;
  num? igR;
  num? igY;
  num? ioB;
  num? ioR;
  num? ioY;
  int? fltEn;
  int? motorId;
  int? motorIndex;
  String? acknowledgement;
  String? motorReference;

  MotorSettingConfig({
    this.cif,
    this.drf,
    this.flc,
    this.lrf,
    this.olf,
    this.opf,
    this.igB,
    this.igR,
    this.igY,
    this.ioB,
    this.ioR,
    this.ioY,
    this.fltEn,
    this.motorId,
    this.motorIndex,
    this.acknowledgement,
    this.motorReference,
  });

  factory MotorSettingConfig.fromJson(Map<String, dynamic> json) =>
      MotorSettingConfig(
        cif: json["cif"],
        drf: json["drf"],
        flc: json["flc"],
        lrf: json["lrf"],
        olf: json["olf"],
        opf: json["opf"],
        igB: json["ig_b"],
        igR: json["ig_r"],
        igY: json["ig_y"],
        ioB: json["io_b"],
        ioR: json["io_r"],
        ioY: json["io_y"],
        fltEn: json["flt_en"],
        motorId: json["motor_id"],
        motorIndex: json["motor_index"],
        acknowledgement: json["acknowledgement"],
        motorReference: json["motor_reference"],
      );

  Map<String, dynamic> toJson() => {
        "cif": cif,
        "drf": drf,
        "flc": flc,
        "lrf": lrf,
        "olf": olf,
        "opf": opf,
        "ig_b": igB,
        "ig_r": igR,
        "ig_y": igY,
        "io_b": ioB,
        "io_r": ioR,
        "io_y": ioY,
        "flt_en": fltEn,
        "motor_id": motorId,
        "motor_index": motorIndex,
        "acknowledgement": acknowledgement,
        "motor_reference": motorReference,
      };
}

/*
 * Copyright (C) 2022-2025 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#include <android-base/logging.h>
#include <android-base/parseint.h>
#include <android-base/properties.h>
#define _REALLY_INCLUDE_SYS__SYSTEM_PROPERTIES_H_
#include <sys/_system_properties.h>

#include <fs_mgr.h>
#include <unordered_map>

using android::base::GetProperty;
using android::fs_mgr::GetKernelCmdline;

const std::unordered_map<int, std::string> kRegionSuffixMap = {
    {27,    "IN"},
    {55,    "RU"},
    {68,    "EEA"},
    {151,   ""},    // CN
    {161,   "NA"},
    {167,   ""},    // GLO
    {0,     ""},    // Default
};

struct ModelInfo {
    const char* brand;              // ro.product.brand
    const char* device;             // ro.product.device
    const char* manufacturer;       // ro.product.manufacturer
    const char* model;              // ro.product.model
    const char* base_name;          // ro.product.name  w/o region suffix
    const char* twversion;          // ro.twrp.device_version
    const char* supportSpr;         // vendor.display.enable_spr
};

const std::unordered_map<int, ModelInfo> kModelInfoMap = {
    {23821, {"OnePlus", "OP5D0DL1", "OnePlus", "PJZ110",  "PJZ110",  "OnePlus_13",          "1"}}, // dodge CN
    {23893, {"OnePlus", "OP5D55L1", "OnePlus", "CPH2653", "CPH2653", "OnePlus_13",          "1"}}, // dodge GLO
    {24600, {"realme",  "RE6018L1", "realme",  "RMX5010", "RMX5010", "Realme_GT_7_Pro",     "0"}}, // RMX5010 CN
    {24620, {"realme",  "RE602CL1", "realme",  "RMX5090", "RMX5090", "Realme_GT_7_Pro_JS",  "0"}}, // RMX5090 CN
    {24670, {"realme",  "RE605FL1", "realme",  "RMX5011", "RMX5011", "Realme_GT_7_Pro",     "0"}}, // RMX5011 IN
    {24671, {"realme",  "RE605FL1", "realme",  "RMX5011", "RMX5011", "Realme_GT_7_Pro",     "0"}}, // RMX5011 EEA/RU
    {24811, {"OnePlus", "OP60EBL1", "OnePlus", "PKR110",  "PKR110",  "OnePlus_ACE_5_Pro",   "0"}}, // hummer CN
    {24816, {"OnePlus", "OP60F0L1", "OnePlus", "PLU110",  "PLU110",  "OnePlus_Turbo_6",     "0"}}, // Prado CN
    {24821, {"OnePlus", "OP60F5L1", "OnePlus", "PKX110",  "PKX110",  "OnePlus_13_T",        "1"}}, // pagani CN
    {24875, {"OnePlus", "OP612BL1", "OnePlus", "CPH2723", "CPH2723", "OnePlus_13_s",        "1"}}, // pagani IN
    {24851, {"OnePlus", "OP6113L1", "OnePlus", "PLQ110",  "PLQ110",  "OnePlus_ACE_6",       "0"}}, // ktm CN
    {25600, {"realme",  "RE6400L1", "realme",  "RMX6699", "RMX6699", "Realme_GT_8",         "0"}}, // RMX6699 CN
    {24926, {"OnePlus", "OP615EL1", "OnePlus", "OPD2413", "OPD2413", "OnePlus_Pad2Pro",     "0"}}, // ossi CN
    {0,     {"OPLUS",   "SM87XX",   "OPLUS",   "SM87XX",  "SM87XX",  "SM87XX",              "0"}}, // Default
};

/*
 * SetProperty does not allow updating read only properties and as a result
 * does not work for our use case. Write "OverrideProperty" to do practically
 * the same thing as "SetProperty" without this restriction.
 */
void OverrideProperty(const char* name, const char* value) {
    size_t valuelen = strlen(value);

    prop_info* pi = (prop_info*)__system_property_find(name);
    if (pi != nullptr) {
        __system_property_update(pi, value, valuelen);
    } else {
        __system_property_add(name, strlen(name), value, valuelen);
    }
}

void SetupModelProperties(const ModelInfo& info, const std::string& region) {
    std::string name = info.base_name + region;
    struct PropPair {
        const char* key;
        const char* value;
    } props[] = {
        {"ro.product.brand",            info.brand},
        {"ro.product.device",           info.device},
        {"ro.product.manufacturer",     info.manufacturer},
        {"ro.product.model",            info.model},
        {"ro.product.name",             name.c_str()},
        {"vendor.display.enable_spr",   info.supportSpr},
        {"ro.twrp.device_version",      info.twversion},
        {"ro.build.date.utc",           "0"},
    };
    for (const auto& p : props) {
        OverrideProperty(p.key, p.value);
    }
}

void vendor_load_properties() {
    std::string buf = "0";
    GetKernelCmdline("oplus_region", &buf);

    auto region = std::stoi(buf);
    auto region_suffix_iter = kRegionSuffixMap.find(region);

    // Handle unknown regions gracefully
    if (region_suffix_iter == kRegionSuffixMap.end()) {
        LOG(WARNING) << "Unknown oplus_region: " << region << ", using default";
        region_suffix_iter = kRegionSuffixMap.find(0);
    }

    auto prjname = std::stoi(GetProperty("ro.boot.prjname", "0"));
    auto model_info = kModelInfoMap.find(prjname);

    // Handle unknown device models
    if (model_info == kModelInfoMap.end()) {
        LOG(ERROR) << "Unknown prjname: " << prjname << ", using default";
        model_info = kModelInfoMap.find(0);
    }

    SetupModelProperties(model_info->second, region_suffix_iter->second);

    // Set a prop to handle rotation
    if (prjname == 24926) {
        OverrideProperty("persist.twrp.rotation", "270");
    }
    // Set a prop to handle strongbox
    switch (prjname) {
        case 24851:
            OverrideProperty("twrp.se.no_sb", "true");
            break;
        default:
            OverrideProperty("twrp.se.no_sb", "false");
    }
}

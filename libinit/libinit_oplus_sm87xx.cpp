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
    {0,     ""},    // Default
};

struct ModelInfo {
    const char* brand;              // ro.product.brand
    const char* device;             // ro.product.device
    const char* manufacturer;       // ro.product.manufacturer
    const char* model;              // ro.product.model
    const char* base_name;          // ro.product.name  w/o region suffix
    const char* supportSpr;         // vendor.display.enable_spr
};

const std::unordered_map<int, ModelInfo> kModelInfoMap = {
    {23821, {"OnePlus", "OP5D0DL1", "OnePlus", "PJZ110",  "PJZ110",  "1"}}, // dodge CN
    {24600, {"realme",  "RE6018L1", "realme",  "RMX5010", "RMX5010", "0"}}, // RMX5010 CN
    {24620, {"realme",  "RE602CL1", "realme",  "RMX5090", "RMX5090", "0"}}, // RMX5090 CN
    {24670, {"realme",  "RE605FL1", "realme",  "RMX5011", "RMX5011", "0"}}, // RMX5011 IN
    {24671, {"realme",  "RE605FL1", "realme",  "RMX5011", "RMX5011", "0"}}, // RMX5011 EEA/RU
    {24811, {"OnePlus", "OP60EBL1", "OnePlus", "PKR110",  "PKR110",  "0"}}, // hummer CN
    {24821, {"OnePlus", "OP60F5L1", "OnePlus", "PKX110",  "PKX110",  "1"}}, // pagani CN
    {24831, {"OnePlus", "OP60FFL1", "OnePlus", "PLK110",  "PLK110",  "1"}}, // infiniti CN
    {24851, {"OnePlus", "OP6113L1", "OnePlus", "PLQ110",  "PLQ110",  "0"}}, // ktm CN
    {25600, {"realme",  "RE6400L1", "realme",  "RMX6699", "RMX6699", "0"}}, // RMX6699 CN
    {0,     {"OPLUS",   "SM87XX",   "OPLUS",   "SM87XX",  "SM87XX",  "0"}}, // Default
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

    auto prjname = std::stoi(GetProperty("ro.boot.prjname", "0"));
    auto model_info = kModelInfoMap.find(prjname);

    SetupModelProperties(model_info->second, region_suffix_iter->second);
}

/*
 * Copyright (C) 2022-2025 The LineageOS Project
 * SPDX-License-Identifier: Apache-2.0
 */

#include <android-base/logging.h>
#include <android-base/properties.h>
#define _REALLY_INCLUDE_SYS__SYSTEM_PROPERTIES_H_
#include <sys/_system_properties.h>

using android::base::GetProperty;

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

void SetupModelProperties(
    const char* brand,          // ro.product.brand
    const char* device,         // ro.product.device
    const char* manufacturer,   // ro.product.manufacturer
    const char* model,          // ro.product.model
    const char* name,           // ro.product.name
    const char* supportSpr      // vendor.display.enable_spr
) {
    OverrideProperty("ro.product.brand",            brand);
    OverrideProperty("ro.product.device",           device);
    OverrideProperty("ro.product.manufacturer",     manufacturer);
    OverrideProperty("ro.product.model",            model);
    OverrideProperty("ro.product.name",             name);
    OverrideProperty("vendor.display.enable_spr",   supportSpr);
    OverrideProperty("ro.build.date.utc",           "0");
}

/*
 * Only for read-only properties. Properties that can be wrote to more
 * than once should be set in a typical init script (e.g. init.oplus.hw.rc)
 * after the original property has been set.
 */
void vendor_load_properties() {
    auto prjname = std::stoi(GetProperty("ro.boot.prjname", "0"));

    switch (prjname) {
        default:
            LOG(ERROR) << "Unexpected prjname: " << prjname;
    }
}
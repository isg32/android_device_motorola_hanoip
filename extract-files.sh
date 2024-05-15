#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=hanoip
VENDOR=motorola

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
    # Fix xml version
    product/etc/permissions/vendor.qti.hardware.data.connection-V1.0-java.xml | product/etc/permissions/vendor.qti.hardware.data.connection-V1.1-java.xml)
        sed -i 's/xml version="2.0"/xml version="1.0"/' "${2}"
        ;;
    system_ext/etc/permissions/moto-telephony.xml)
        sed -i "s|system|system/system_ext|" "${2}"
        ;;
    vendor/lib64/camera/components/com.qti.node.gpu.so)
        sed -i "s/camera.mot.is.coming.cts/vendor.camera.coming.cts/g" "${2}"
        ;;
    vendor/lib64/hw/camera.qcom.so)
        sed -i "s/camera.mot.is.coming.cts/vendor.camera.coming.cts/g" "${2}"
        ;;
    vendor/lib64/hw/com.qti.chi.override.so)
        sed -i "s/camera.mot.is.coming.cts/vendor.camera.coming.cts/g" "${2}"
        ;;
    vendor/bin/thermal-engine)
        sed -i 's/ro.mot.build.customerid/vendor.build.customerid/g' "${2}"
        ;;
    vendor/bin/rmt_storage)
        sed -i 's/ro.mot.build.customerid/vendor.build.customerid/g' "${2}"
        ;;
    vendor/lib64/libril-qc-hal-qmi.so)
        sed -i 's/ro.mot.build.customerid/vendor.build.customerid/g' "${2}"
        ;;
    esac
}

# Reinitialize the helper for device
setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" false "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"
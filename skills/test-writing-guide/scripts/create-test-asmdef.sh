#!/usr/bin/env bash
#
# Generate a Unity Test Framework asmdef file for a test assembly.
#
# Usage:
#   scripts/create-test-asmdef.sh <ProductionAsmdefPath>
#
# Examples:
#   scripts/create-test-asmdef.sh Assets/MyGame/Scripts/Runtime/MyGame.asmdef
#     -> Assets/MyGame/Tests/Runtime/MyGame.Tests.asmdef
#   scripts/create-test-asmdef.sh Assets/MyGame/Scripts/Editor/MyGame.Editor.asmdef
#     -> Assets/MyGame/Tests/Editor/MyGame.Editor.Tests.asmdef
#
# The output directory is derived from the production asmdef path:
# <ProductionRoot>/Tests/<Mode>/ where <ProductionRoot> is two levels above
# the production asmdef and <Mode> is the production directory's last segment
# (typically "Runtime" or "Editor"). Editor mode is detected automatically
# when the production assembly name ends with ".Editor"; in that case the
# runtime test assembly (<Base>.Tests) is added to references and
# includePlatforms is set to ["Editor"].

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/create-test-asmdef.sh <ProductionAsmdefPath>

Arguments:
  ProductionAsmdefPath  Path to the production assembly definition file.
                        Example: Assets/MyGame/Scripts/Runtime/MyGame.asmdef
EOF
}

if [[ $# -ne 1 ]]; then
    usage >&2
    exit 1
fi

production_asmdef="$1"

if [[ ! -f "${production_asmdef}" ]]; then
    echo "Error: ${production_asmdef} does not exist." >&2
    exit 1
fi

if [[ "${production_asmdef}" != *.asmdef ]]; then
    echo "Error: ${production_asmdef} is not an .asmdef file." >&2
    exit 1
fi

production_dir="$(dirname "${production_asmdef}")"
production_assembly="$(basename "${production_asmdef}" .asmdef)"
mode="$(basename "${production_dir}")"
output_dir="$(dirname "$(dirname "${production_dir}")")/Tests/${mode}"
asmdef_name="${production_assembly}.Tests"
output_file="${output_dir}/${asmdef_name}.asmdef"

if [[ -e "${output_file}" ]]; then
    echo "Error: ${output_file} already exists. Refusing to overwrite." >&2
    exit 1
fi

if [[ "${production_assembly}" == *.Editor ]]; then
    runtime_test_assembly="${production_assembly%.Editor}.Tests"
    references_block=$(cat <<EOF
        "${production_assembly}",
        "${runtime_test_assembly}",
        "UnityEngine.TestRunner",
        "UnityEditor.TestRunner"
EOF
)
    include_platforms='"Editor"'
else
    references_block=$(cat <<EOF
        "${production_assembly}",
        "UnityEngine.TestRunner",
        "UnityEditor.TestRunner"
EOF
)
    include_platforms=''
fi

mkdir -p "${output_dir}"

cat > "${output_file}" <<EOF
{
    "name": "${asmdef_name}",
    "rootNamespace": "",
    "references": [
${references_block}
    ],
    "includePlatforms": [${include_platforms}],
    "excludePlatforms": [],
    "allowUnsafeCode": false,
    "overrideReferences": true,
    "precompiledReferences": [
        "nunit.framework.dll"
    ],
    "autoReferenced": false,
    "defineConstraints": [
        "UNITY_INCLUDE_TESTS"
    ],
    "versionDefines": [],
    "noEngineReferences": false
}
EOF

echo "Created ${output_file}"

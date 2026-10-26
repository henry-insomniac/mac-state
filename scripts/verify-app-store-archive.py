#!/usr/bin/env python3
"""Local structural checks, not a substitute for Organizer/App Store validation."""
import argparse
import json
from pathlib import Path
import plistlib
import subprocess

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('archive', type=Path)
parser.add_argument('--require-distribution', action='store_true')
args = parser.parse_args()
root = args.archive / 'Products/Applications/MacStateApp.app'
results = []
versions = set()
groups = []
teams = set()
for bundle in [root, root / 'Contents/PlugIns/MacStateWidgets.appex', root / 'Contents/Library/LoginItems/MacStateLoginHelper.app']:
    info = plistlib.loads((bundle / 'Contents/Info.plist').read_bytes())
    executable = bundle / 'Contents/MacOS' / info['CFBundleExecutable']
    subprocess.run(['codesign', '--verify', '--strict', str(bundle)], check=True, capture_output=True)
    signature = subprocess.run(['codesign', '-dv', '--verbose=4', str(bundle)], check=True, capture_output=True, text=True).stderr
    team = next(line.split('=', 1)[1] for line in signature.splitlines() if line.startswith('TeamIdentifier='))
    teams.add(team)
    entitlements = plistlib.loads(subprocess.check_output(['codesign', '-d', '--entitlements', ':-', str(bundle)], stderr=subprocess.DEVNULL))
    architectures = subprocess.check_output(['lipo', '-archs', str(executable)], text=True).split()
    assert {'arm64', 'x86_64'} <= set(architectures), f'Missing architecture: {bundle}'
    assert entitlements.get('com.apple.security.app-sandbox') is True, f'Not sandboxed: {bundle}'
    assert info['LSMinimumSystemVersion'] == '11.0', f'Unexpected support floor: {bundle}'
    manifest = plistlib.loads((bundle / 'Contents/Resources/PrivacyInfo.xcprivacy').read_bytes())
    assert manifest['NSPrivacyTracking'] is False, f'Unexpected tracking declaration: {bundle}'
    versions.add((info['CFBundleShortVersionString'], info['CFBundleVersion']))
    if bundle != root / 'Contents/Library/LoginItems/MacStateLoginHelper.app':
        group = info['MacStateAppGroupIdentifier']
        assert entitlements.get('com.apple.security.application-groups') == [group]
        groups.append(group)
    distribution = 'Authority=Apple Distribution:' in signature or 'Authority=3rd Party Mac Developer Application:' in signature
    if args.require_distribution:
        assert distribution, f'Distribution certificate missing: {bundle}'
        assert not entitlements.get('com.apple.security.get-task-allow', False), f'Debug entitlement present: {bundle}'
    if bundle == root:
        binary_strings = subprocess.check_output(['strings', str(executable)], text=True)
        assert '--sandbox-diagnostics' not in binary_strings, 'Debug diagnostics leaked into archive'
    results.append({'bundle': bundle.name, 'architectures': architectures, 'sandbox': True, 'signatureValid': True,
                    'privacyManifest': True, 'distributionSigned': distribution, 'build': info['CFBundleVersion']})
assert len(versions) == 1, 'Bundle version mismatch'
assert len(teams) == 1 and 'not set' not in teams, 'Signing team mismatch'
assert len(set(groups)) == 1 and groups[0].startswith(next(iter(teams)) + '.'), 'Shared group mismatch'
print(json.dumps({'checksPassed': True, 'scope': 'local structural checks only', 'bundles': results}, indent=2))

#!/usr/bin/env python3
"""Portable source-contract checks, not an iOS build or runtime test.

Run from any directory: python3 scripts/check_free_release.py
No dependencies or network access are required.
"""

from html.parser import HTMLParser
from pathlib import Path
import json
import plistlib
import re
import unittest
from urllib.parse import urlsplit
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
APP = ROOT / "SignalScout"
SOURCE = "\n".join(path.read_text() for path in sorted(APP.glob("*.swift")))
PROJECT = (ROOT / "SignalScout.xcodeproj/project.pbxproj").read_text()


class LinkParser(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []

    def handle_starttag(self, tag, attrs):
        for name, value in attrs:
            if name in {"href", "src"} and value:
                self.links.append(value)


class FreeReleaseSourceTests(unittest.TestCase):
    def test_launch_routes_directly_to_features(self):
        root = (APP / "RootView.swift").read_text()
        self.assertRegex(
            root,
            r"struct RootView: View \{\s*var body: some View \{\s*ScoutFeatureView\(\)\s*\}\s*\}",
        )
        app = (APP / "SignalScoutApp.swift").read_text()
        self.assertIn("RootView()", app)
        self.assertNotIn(".task", app)

    def test_no_purchase_or_entitlement_code_is_shipped(self):
        for token in (
            "StoreKit", "SubscriptionManager", "SubscriptionPaywallView",
            "SubscriptionAccess", "hasFeatureAccess", "currentEntitlements",
            "Product.products", ".purchase()", "AppStore.sync",
            "Restore Purchases", "Manage Subscription", "Checking App Store",
            "com.nicholasvandervelden.SignalScout.monthly",
        ):
            with self.subTest(token=token):
                self.assertNotIn(token, SOURCE)

    def test_no_time_limit_or_persisted_preview_gate(self):
        for token in (
            "previewSecondsRemaining", "PreviewCountdownBanner", "startPreview",
            "previewStartKey", "previewDuration", "signalScout.preview",
            "UserDefaults", "60-Second", "Free preview", "previewTimer",
        ):
            with self.subTest(token=token):
                self.assertNotIn(token, SOURCE)

    def test_paid_source_files_are_removed_from_both_project_sources(self):
        for name in ("SubscriptionManager.swift", "SubscriptionPaywallView.swift"):
            self.assertFalse((APP / name).exists())
            self.assertNotIn(name, PROJECT)
        self.assertIn("- path: SignalScout", (ROOT / "project.yml").read_text())

    def test_build_number_and_version_are_consistent(self):
        self.assertEqual(re.findall(r"CURRENT_PROJECT_VERSION = (\d+);", PROJECT), ["5", "5"])
        self.assertEqual(re.findall(r"MARKETING_VERSION = ([\d.]+);", PROJECT), ["1.3", "1.3"])
        spec = (ROOT / "project.yml").read_text()
        self.assertIn("CURRENT_PROJECT_VERSION: 5", spec)
        self.assertIn("MARKETING_VERSION: 1.3", spec)

    def test_support_privacy_and_terms_remain_accessible(self):
        for label, url in (
            ("Support", "https://nickvan23-lang.github.io/signal-scout/support.html"),
            ("Privacy Policy", "https://nickvan23-lang.github.io/signal-scout/privacy.html"),
            ("Terms of Use", "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"),
        ):
            self.assertIn(f'Link("{label}", destination: URL(string: "{url}")!)', SOURCE)

    def test_scanner_is_still_constructed_and_starts_with_bluetooth(self):
        self.assertIn("@StateObject private var scanner = BluetoothScanner()", SOURCE)
        scanner = (APP / "BluetoothScanner.swift").read_text()
        self.assertRegex(scanner, r"case \.poweredOn:\s*availability = \.ready\s*startScanning\(\)")
        self.assertIn("CBCentralManagerScanOptionAllowDuplicatesKey: true", scanner)

    def test_no_device_names_manufacturers_location_or_upload_apis(self):
        for token in (
            "peripheral.name", "CBAdvertisementDataLocalNameKey",
            "CBAdvertisementDataManufacturerDataKey", "CoreLocation",
            "CLLocationManager", "URLSession", "URLRequest",
        ):
            with self.subTest(token=token):
                self.assertNotIn(token, SOURCE)
        self.assertIn('var anonymousLabel: String { "Signal ', SOURCE)

    def test_privacy_manifest(self):
        manifest = plistlib.loads((APP / "PrivacyInfo.xcprivacy").read_bytes())
        self.assertFalse(manifest["NSPrivacyTracking"])
        self.assertEqual(manifest["NSPrivacyCollectedDataTypes"], [])
        self.assertEqual(manifest["NSPrivacyAccessedAPITypes"], [])

    def test_xml_and_json_files_parse(self):
        # Check source configuration, excluding generated apps and Xcode evidence.
        # Xcode outputs binary plists, which are valid plists but are not XML.
        project = ROOT / "SignalScout.xcodeproj"
        plist_paths = list((ROOT / "AppStore").glob("*.plist")) + list(APP.rglob("*.xcprivacy"))
        for path in plist_paths:
            with self.subTest(path=path.relative_to(ROOT)):
                plistlib.loads(path.read_bytes())
        for extension in ("*.xcscheme", "*.xcworkspacedata"):
            for path in project.rglob(extension):
                with self.subTest(path=path.relative_to(ROOT)):
                    ET.parse(path)
        for path in (APP / "Assets.xcassets").rglob("*.json"):
            with self.subTest(path=path.relative_to(ROOT)):
                json.loads(path.read_text())

    def test_project_source_references_resolve(self):
        names = set(re.findall(r"path = ([A-Za-z0-9_]+\.swift);", PROJECT))
        files = list(APP.glob("*.swift")) + list((ROOT / "SignalScoutTests").glob("*.swift"))
        self.assertEqual(names, {path.name for path in files})
        for path in files:
            self.assertIn(f"/* {path.name} in Sources */", PROJECT)

    def test_remaining_unit_tests_have_no_removed_type_references(self):
        tests = (ROOT / "SignalScoutTests/SignalTrendAnalyzerTests.swift").read_text()
        self.assertNotIn("SubscriptionManager", tests)
        self.assertEqual(len(re.findall(r"func test\w+\(", tests)), 10)

    def test_website_relative_links_resolve(self):
        for path in (ROOT / "Web").glob("*.html"):
            parser = LinkParser()
            parser.feed(path.read_text())
            for link in parser.links:
                parsed = urlsplit(link)
                if not parsed.scheme and parsed.path:
                    with self.subTest(page=path.name, link=link):
                        self.assertTrue((path.parent / parsed.path).is_file())

    def test_support_email_and_free_access_copy(self):
        support = (ROOT / "Web/support.html").read_text()
        self.assertIn("mailto:nickvan23@gmail.com?subject=Signal%20Scout%20Support", support)
        self.assertIn("All features are free, without a subscription or time limit.", support)
        self.assertNotIn("start the 60-second preview", support)
        self.assertNotIn("Use Restore Purchases", support)


if __name__ == "__main__":
    unittest.main(verbosity=2)

import SwiftUI

struct SearchHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("A signal is a clue, not a location.")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                    helpStep("1", title: "Wake your accessory", detail: "Use an accessory you own or have permission to locate. It must be actively advertising Bluetooth Low Energy. Sleeping devices, closed charging cases, and connected accessories may not appear.")
                    helpStep("2", title: "Compare nearby signals", detail: "Look for your accessory’s Bluetooth name and advertised manufacturer. Some devices omit these fields or use a generic name. Broadcast details are not verified identity. If unsure, bring an accessory you control close and compare the signal that strengthens.")
                    helpStep("3", title: "Move, pause, compare", detail: "Select a signal, hold the phone the same way, and take a few slow steps. Wait for several fresh readings. Use Reset comparison when trying a new position.")
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Reading the map", systemImage: "scope").font(.headline)
                        Text("Closer to the center means stronger signal strength. Dot angles are only visual spacing, not a direction to walk.")
                        Text("A value such as −50 dBm is stronger than −80 dBm. Walls, reflections, and the accessory's radio power can change the reading.")
                    }
                    .padding(18)
                    .background(ScoutPalette.panel, in: RoundedRectangle(cornerRadius: 18))
                    Label("Names and manufacturer identifiers stay on your phone. No location permission, accounts, or signal uploads.", systemImage: "hand.raised")
                        .font(.footnote)
                        .foregroundStyle(ScoutPalette.secondary)
                }
                .padding(22)
            }
            .background(ScoutPalette.background)
            .navigationTitle("How to search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.frame(minWidth: 44, minHeight: 44)
                }
            }
        }
        .tint(ScoutPalette.cyan)
        .preferredColorScheme(.dark)
    }

    private func helpStep(_ number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number).font(.headline).foregroundStyle(ScoutPalette.background)
                .frame(width: 32, height: 32).background(ScoutPalette.cyan, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.headline)
                Text(detail).foregroundStyle(ScoutPalette.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

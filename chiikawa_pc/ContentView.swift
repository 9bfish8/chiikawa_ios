//
//  ContentView.swift
//  chiikawa_pc
//
//  Character picker: choose which pets stand on the desktop.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var petManager: PetManager
    @Environment(\.openWindow) private var openWindow

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 120), spacing: 14)]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("치이카와 데스크탑 펫")
                    .font(.title2).bold()
                Text("바탕화면에 올려둘 캐릭터를 눌러서 선택하세요.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(PetCatalog.all) { species in
                        PetPickerCell(species: species)
                    }
                }
                .padding(.vertical, 4)
            }

            Divider()

            HStack {
                Button("모두 올리기") {
                    for species in PetCatalog.all { petManager.spawn(species) }
                }
                Button("모두 치우기", role: .destructive) {
                    petManager.removeAll()
                }
                Spacer()
                Button("다시 흩뿌리기") {
                    petManager.scatterActive()
                }
                .disabled(petManager.activeSpeciesIDs.isEmpty)
            }
        }
        .padding(20)
        .frame(minWidth: 420, idealWidth: 460, minHeight: 440, idealHeight: 520)
        .environmentObject(petManager)
        .onAppear {
            WindowOpener.open = { openWindow(id: "picker") }
        }
    }
}

private struct PetPickerCell: View {
    let species: PetSpecies
    @EnvironmentObject private var petManager: PetManager

    private var isActive: Bool { petManager.isActive(species.id) }

    var body: some View {
        Button {
            petManager.toggle(species)
        } label: {
            VStack(spacing: 6) {
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isActive ? Color.accentColor.opacity(0.15) : Color.gray.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 2)
                        )

                    if let image = petManager.previewImage(for: species.id) {
                        Image(nsImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(10)
                    }

                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, Color.accentColor)
                            .padding(5)
                    }
                }
                .frame(height: 88)

                Text(species.displayName)
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
        .environmentObject(PetManager())
}

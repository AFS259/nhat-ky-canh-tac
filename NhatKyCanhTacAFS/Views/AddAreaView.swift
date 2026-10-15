import SwiftUI

struct AddAreaView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var editingArea: Area? = nil

    @State private var name = ""
    @State private var address = ""
    @State private var note = ""
    @State private var latitude: Double? = nil
    @State private var longitude: Double? = nil
    @State private var showMapPicker = false

    private var isEditing: Bool { editingArea != nil }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

    private var hasLocation: Bool { latitude != nil && longitude != nil }

    private var mapsURL: URL? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(lat),\(lon)")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        AFSIconBadge(icon: "mappin.and.ellipse", color: AppTheme.primary)
                            .scaleEffect(1.3)
                            .padding(.top, 8)
                        Text(isEditing ? "Chỉnh sửa khu vực" : "Thêm khu vực canh tác")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)

                        AFSCard {
                            VStack(spacing: 16) {
                                AFSLabeledField(title: "Tên khu vực", icon: "leaf.fill") {
                                    AFSTextField(placeholder: "VD: Vườn ổi sau nhà", text: $name)
                                }
                                AFSLabeledField(title: "Địa chỉ / vị trí", icon: "mappin.and.ellipse") {
                                    AFSTextField(placeholder: "VD: Ấp 3, xã Tân Phú", text: $address)
                                }
                                locationPicker
                                AFSLabeledField(title: "Ghi chú", icon: "note.text") {
                                    AFSTextField(placeholder: "Mô tả ngắn (không bắt buộc)", text: $note)
                                }
                            }
                        }

                        Button {
                            save()
                        } label: {
                            Text(isEditing ? "LƯU THAY ĐỔI" : "LƯU KHU VỰC")
                        }
                        .buttonStyle(AFSPrimaryButtonStyle())
                        .disabled(trimmedName.isEmpty)
                        .opacity(trimmedName.isEmpty ? 0.5 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "Sửa khu vực" : "Khu vực mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }.foregroundColor(.white)
                }
            }
            .onAppear(perform: prefill)
            .sheet(isPresented: $showMapPicker) {
                LocationPickerView(initialLatitude: latitude, initialLongitude: longitude) { picked in
                    latitude = picked.latitude
                    longitude = picked.longitude
                    if address.trimmingCharacters(in: .whitespaces).isEmpty {
                        address = picked.address
                    }
                }
            }
        }
    }

    private var locationPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                showMapPicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "map.fill").foregroundColor(AppTheme.primary)
                    Text(hasLocation ? "Đổi vị trí trên bản đồ" : "Chọn vị trí trên bản đồ")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.primaryDark)
                    Spacer()
                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(AppTheme.accent.opacity(0.16)))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.accent, lineWidth: 1))
            }

            if hasLocation, let url = mapsURL {
                HStack(spacing: 8) {
                    Image(systemName: "mappin.circle.fill").foregroundColor(AppTheme.primary)
                    Text(String(format: "%.5f, %.5f", latitude ?? 0, longitude ?? 0))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Button {
                        openURL(url)
                    } label: {
                        Label("Google Maps", systemImage: "arrow.up.right.square")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
        }
    }

    private func prefill() {
        guard let area = editingArea else { return }
        name = area.name
        address = area.address
        note = area.note
        latitude = area.latitude
        longitude = area.longitude
    }

    private func save() {
        if var area = editingArea {
            area.name = trimmedName
            area.address = address.trimmingCharacters(in: .whitespaces)
            area.note = note.trimmingCharacters(in: .whitespaces)
            area.latitude = latitude
            area.longitude = longitude
            app.updateArea(area)
        } else {
            var area = Area(name: trimmedName,
                            address: address.trimmingCharacters(in: .whitespaces),
                            note: note.trimmingCharacters(in: .whitespaces))
            area.latitude = latitude
            area.longitude = longitude
            app.addArea(area)
        }
        dismiss()
    }
}

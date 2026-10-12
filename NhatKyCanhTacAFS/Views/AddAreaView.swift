import SwiftUI

struct AddAreaView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss

    var editingArea: Area? = nil

    @State private var name = ""
    @State private var address = ""
    @State private var note = ""

    private var isEditing: Bool { editingArea != nil }

    private var trimmedName: String { name.trimmingCharacters(in: .whitespaces) }

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
        }
    }

    private func prefill() {
        guard let area = editingArea else { return }
        name = area.name
        address = area.address
        note = area.note
    }

    private func save() {
        if var area = editingArea {
            area.name = trimmedName
            area.address = address.trimmingCharacters(in: .whitespaces)
            area.note = note.trimmingCharacters(in: .whitespaces)
            app.updateArea(area)
        } else {
            let area = Area(name: trimmedName,
                            address: address.trimmingCharacters(in: .whitespaces),
                            note: note.trimmingCharacters(in: .whitespaces))
            app.addArea(area)
        }
        dismiss()
    }
}

import SwiftUI

struct AddAreaView: View {
    @EnvironmentObject private var app: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var address = ""
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        AFSIconBadge(icon: "mappin.and.ellipse", color: AppTheme.primary)
                            .scaleEffect(1.3)
                            .padding(.top, 8)
                        Text("Thêm khu vực canh tác")
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
                            let area = Area(name: name.trimmingCharacters(in: .whitespaces),
                                            address: address.trimmingCharacters(in: .whitespaces),
                                            note: note.trimmingCharacters(in: .whitespaces))
                            app.addArea(area)
                            dismiss()
                        } label: {
                            Text("LƯU KHU VỰC")
                        }
                        .buttonStyle(AFSPrimaryButtonStyle())
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.5 : 1)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Khu vực mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }.foregroundColor(.white)
                }
            }
        }
    }
}

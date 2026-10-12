import SwiftUI

struct AreaListView: View {
    @EnvironmentObject private var app: AppState
    @State private var showAddArea = false
    @State private var search = ""

    private var filteredAreas: [Area] {
        let list = app.areas.sorted { $0.createdAt > $1.createdAt }
        guard !search.isEmpty else { return list }
        return list.filter { $0.name.localizedCaseInsensitiveContains(search) || $0.address.localizedCaseInsensitiveContains(search) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.screenGradient.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        hero

                        if !app.areas.isEmpty {
                            searchBar
                        }

                        if filteredAreas.isEmpty {
                            emptyState
                        } else {
                            ForEach(filteredAreas) { area in
                                NavigationLink {
                                    AreaDetailView(areaID: area.id)
                                } label: {
                                    AreaCard(area: area)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle("Vườn của tôi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Vườn của tôi")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddArea = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showAddArea) {
                AddAreaView()
            }
        }
    }

    private var hero: some View {
        HStack(spacing: 14) {
            ZStack {
                if let image = app.avatarImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white.opacity(0.85), lineWidth: 2))
                } else {
                    Circle().fill(.white.opacity(0.2)).frame(width: 52, height: 52)
                    Image(systemName: "person.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Xin chào,")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
                Text(app.currentUser?.fullName ?? "Kỹ thuật viên")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(app.areas.count)")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(.white)
                Text("khu vực")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                .fill(AppTheme.heroGradient)
                .shadow(color: AppTheme.primary.opacity(0.3), radius: 12, y: 6)
        )
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(AppTheme.textSecondary)
            TextField("Tìm khu vực...", text: $search)
                .font(.system(size: 15))
            if !search.isEmpty {
                Button { search = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(AppTheme.line, lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 30)
            ZStack {
                Circle().fill(AppTheme.primary.opacity(0.10)).frame(width: 110, height: 110)
                Image(systemName: "square.dashed.inset.filled")
                    .font(.system(size: 46))
                    .foregroundColor(AppTheme.primary)
            }
            Text("Chưa có khu vực canh tác")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            Text("Nhấn dấu + để thêm khu vực đầu tiên của bạn.")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button {
                showAddArea = true
            } label: {
                Label("Thêm khu vực", systemImage: "plus")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 13)
                    .background(Capsule().fill(AppTheme.primary))
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 8, y: 4)
            }
            .padding(.top, 4)
            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
    }
}

struct AreaCard: View {
    let area: Area

    var body: some View {
        AFSCard(padding: 16) {
            HStack(spacing: 14) {
                AFSIconBadge(icon: "leaf.fill")
                VStack(alignment: .leading, spacing: 5) {
                    Text(area.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    if !area.address.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse").font(.system(size: 11))
                            Text(area.address).font(.system(size: 12)).lineLimit(1)
                        }
                        .foregroundColor(AppTheme.textSecondary)
                    }
                    HStack(spacing: 10) {
                        Label("\(area.crops.count) vụ", systemImage: "sprout")
                        Label(Fmt.day.string(from: area.createdAt), systemImage: "calendar")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppTheme.primary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textSecondary.opacity(0.6))
            }
        }
    }
}

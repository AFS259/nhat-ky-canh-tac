import SwiftUI
import Foundation
import MapKit
import CoreLocation

/// Vị trí người dùng chọn trên bản đồ.
struct PickedLocation: Identifiable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let address: String
}

/// Chọn vị trí trên bản đồ (kéo bản đồ, ghim ở tâm). Không cần quyền vị trí.
struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var region: MKCoordinateRegion
    @State private var address = "Đang xác định địa chỉ..."
    @State private var picking = false
    @State private var query = ""
    @State private var results: [MKMapItem] = []
    @State private var searching = false

    private let onPick: (PickedLocation) -> Void
    private let geocoder = CLGeocoder()

    init(initialLatitude: Double?, initialLongitude: Double?,
         onPick: @escaping (PickedLocation) -> Void) {
        self.onPick = onPick
        let center: CLLocationCoordinate2D
        let span: MKCoordinateSpan
        if let lat = initialLatitude, let lon = initialLongitude {
            center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        } else {
            center = CLLocationCoordinate2D(latitude: 10.0452, longitude: 105.7469) // Đồng bằng sông Cửu Long
            span = MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        }
        _region = State(initialValue: MKCoordinateRegion(center: center, span: span))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region)
                    .ignoresSafeArea()

                VStack(spacing: 10) {
                    searchBar
                    if !results.isEmpty { resultsList }
                    Spacer()
                    bottomCard
                }
                .padding(14)

                // Ghim căn đúng tâm MÀN HÌNH (khung full-screen, trùng tâm Map).
                pinMarker
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .navigationTitle("Chọn vị trí")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { dismiss() }.foregroundColor(.white)
                }
            }
            .onAppear(perform: refreshAddress)
        }
    }

    /// Ghim nhỏ, nằm giữa bản đồ; đầu ghim trùng tâm màn hình.
    private var pinMarker: some View {
        Image(systemName: "mappin.circle.fill")
            .font(.system(size: 26))
            .foregroundColor(AppTheme.danger)
            .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
            .offset(y: -13)
            .allowsHitTesting(false)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(AppTheme.textSecondary)
            TextField("Tìm địa điểm...", text: $query)
                .font(.system(size: 14))
                .submitLabel(.search)
                .onSubmit(runSearch)
            if searching {
                ProgressView().scaleEffect(0.8)
            } else if !query.isEmpty {
                Button { query = ""; results = [] } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(AppTheme.textSecondary)
                }
            }
            Button("Tìm") { runSearch() }
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.primary)
        }
        .padding(.horizontal, 12).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
        .shadow(color: AppTheme.cardShadow, radius: 6, y: 2)
    }

    private var resultsList: some View {
        VStack(spacing: 0) {
            ForEach(Array(results.enumerated()), id: \.offset) { index, item in
                Button {
                    selectSearchResult(item)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "mappin.circle.fill").foregroundColor(AppTheme.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "Địa điểm").font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary).lineLimit(1)
                            if let sub = item.placemark.title {
                                Text(sub).font(.system(size: 11)).foregroundColor(AppTheme.textSecondary).lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                    .padding(12)
                }
                if index < results.count - 1 { Divider().overlay(AppTheme.line) }
            }
        }
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(.white))
        .shadow(color: AppTheme.cardShadow, radius: 6, y: 2)
    }

    private var bottomCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill").foregroundColor(AppTheme.primary)
                Text(address)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(3)
                Spacer(minLength: 0)
            }
            Button {
                confirm()
            } label: {
                if picking {
                    ProgressView().tint(.white)
                } else {
                    Label("CHỌN VỊ TRÍ NÀY", systemImage: "checkmark.circle.fill")
                }
            }
            .buttonStyle(AFSPrimaryButtonStyle())
            .disabled(picking)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(.white))
        .shadow(color: AppTheme.cardShadow, radius: 10, y: 3)
    }

    private func runSearch() {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        searching = true
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = text
        request.region = region
        MKLocalSearch(request: request).start { response, _ in
            searching = false
            results = response?.mapItems ?? []
        }
    }

    private func selectSearchResult(_ item: MKMapItem) {
        let coord = item.placemark.coordinate
        withAnimation {
            region = MKCoordinateRegion(center: coord,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        }
        address = item.placemark.title ?? item.name ?? "Địa điểm đã chọn"
        results = []
        query = ""
    }

    private func refreshAddress() {
        address = "Đang xác định địa chỉ..."
        reverseGeocode(region.center) { text in
            address = text
        }
    }

    private func confirm() {
        picking = true
        reverseGeocode(region.center) { text in
            picking = false
            onPick(PickedLocation(latitude: region.center.latitude,
                                  longitude: region.center.longitude,
                                  address: text))
            dismiss()
        }
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D, completion: @escaping (String) -> Void) {
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) { placemarks, _ in
            guard let p = placemarks?.first else {
                completion(String(format: "%.5f, %.5f", coord.latitude, coord.longitude))
                return
            }
            let parts = [p.name, p.thoroughfare, p.subLocality, p.locality,
                         p.administrativeArea, p.country]
                .compactMap { $0 }
            let unique = NSOrderedSet(array: parts).compactMap { $0 as? String }
            completion(unique.isEmpty ? String(format: "%.5f, %.5f", coord.latitude, coord.longitude)
                                      : unique.joined(separator: ", "))
        }
    }
}

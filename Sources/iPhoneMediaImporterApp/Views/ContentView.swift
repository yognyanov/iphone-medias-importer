import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isSettingsPresented = false

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let isCompact = proxy.size.width < 1120
                let isNarrow = proxy.size.width < 860

                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.95, green: 0.97, blue: 1.0), Color.white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            headerCard(isNarrow: isNarrow)
                            if viewModel.screenState == .copying || viewModel.screenState == .completed {
                                transferCard(isCompact: isCompact)
                            }
                            LazyVGrid(columns: cardColumns(isCompact: isCompact), alignment: .leading, spacing: 20) {
                                scanOverviewCard(isCompact: isCompact)

                                if viewModel.screenState == .scanned || viewModel.screenState == .copying || viewModel.screenState == .completed {
                                    planCard
                                }

                                if viewModel.screenState == .completed {
                                    summaryCard
                                }
                            }
                            if let error = viewModel.lastErrorMessage {
                                errorCard(message: error)
                            }
                        }
                        .frame(maxWidth: 1120)
                        .padding(isNarrow ? 20 : 28)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("iPhone Medya Aktarıcı")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Label("Ayarlar", systemImage: "gearshape.fill")
                    }
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                settingsSheet
            }
        }
    }

    private func cardColumns(isCompact: Bool) -> [GridItem] {
        if isCompact {
            return [GridItem(.flexible(minimum: 320), spacing: 20)]
        }

        return [
            GridItem(.flexible(minimum: 320), spacing: 20),
            GridItem(.flexible(minimum: 320), spacing: 20)
        ]
    }

    private func metricColumns(isCompact: Bool) -> [GridItem] {
        if isCompact {
            return [
                GridItem(.flexible(minimum: 140), spacing: 12),
                GridItem(.flexible(minimum: 140), spacing: 12)
            ]
        }

        return [
            GridItem(.flexible(minimum: 120), spacing: 12),
            GridItem(.flexible(minimum: 120), spacing: 12),
            GridItem(.flexible(minimum: 120), spacing: 12),
            GridItem(.flexible(minimum: 120), spacing: 12)
        ]
    }

    private func headerCard(isNarrow: Bool) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 16) {
                headerLogo

                Text("iPhone'dan Mac'e kolay aktarım")
                    .font(.system(size: 28, weight: .semibold))
            }

            Text("iPhone'unuzdaki fotoğraf ve video dosyalarını Mac'inize aktarır.")
                .foregroundStyle(.secondary)

            if viewModel.isDemoMode {
                Label("Demo modu aktif. Gerçek cihaz yerine örnek medya listesi kullanılıyor.", systemImage: "bolt.horizontal.circle")
                    .foregroundStyle(Color.orange)
            }

            DeviceStatusRow(
                deviceStateTitle: viewModel.deviceStateTitle,
                targetFolderPath: viewModel.targetFolderURL?.path(percentEncoded: false) ?? "Seçilmedi",
                isStacked: isNarrow
            )

            if let deviceHelpMessage = viewModel.deviceHelpMessage {
                helperHintCard(message: deviceHelpMessage)
            }

            Group {
                if isNarrow {
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Hedef Klasör Seç") {
                            viewModel.chooseTargetFolder()
                        }
                        .buttonStyle(.bordered)

                        Button("Seçimi Temizle") {
                            viewModel.clearTargetFolderSelection()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.targetFolderURL == nil)

                        Button("Yeniden Dene") {
                            viewModel.retryDeviceConnection()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    HStack(spacing: 12) {
                        Button("Hedef Klasör Seç") {
                            viewModel.chooseTargetFolder()
                        }
                        .buttonStyle(.bordered)

                        Button("Seçimi Temizle") {
                            viewModel.clearTargetFolderSelection()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.targetFolderURL == nil)

                        Button("Yeniden Dene") {
                            viewModel.retryDeviceConnection()
                        }
                        .buttonStyle(.bordered)

                        Spacer()
                    }
                }
            }

            Group {
                if isNarrow {
                    VStack(spacing: 12) {
                        primaryScanButton
                        primaryCopyButton
                    }
                } else {
                    HStack(spacing: 14) {
                        primaryScanButton
                        primaryCopyButton
                    }
                }
            }
        }
        .padding(22)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var primaryScanButton: some View {
        Button {
            viewModel.scanDevice()
        } label: {
            Label("Tara", systemImage: "waveform.magnifyingglass")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(Color(red: 0.12, green: 0.49, blue: 0.96))
        .disabled(!viewModel.canScan)
    }

    private var primaryCopyButton: some View {
        Button {
            viewModel.startCopy()
        } label: {
            Label("Kopyalamayı Başlat", systemImage: "arrow.down.circle.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .tint(Color(red: 0.06, green: 0.66, blue: 0.48))
        .disabled(!viewModel.canStartCopy || viewModel.screenState == .copying)
    }

    private var headerLogo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.48, blue: 0.96),
                            Color(red: 0.21, green: 0.76, blue: 0.83)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 68, height: 68)

            Image(systemName: "iphone.gen3")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)

            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))
                .offset(x: 20, y: 20)
        }
        .shadow(color: Color.black.opacity(0.10), radius: 12, x: 0, y: 6)
        .accessibilityHidden(true)
    }

    private func scanOverviewCard(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tarama Sonucu")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 12) {
                Text("Aktarım Seçenekleri")
                    .font(.headline)

                if isCompact {
                    VStack(alignment: .leading, spacing: 12) {
                        mediaTypeSection

                        Toggle("Yalnızca yeni dosyaları aktar", isOn: Binding(
                            get: { viewModel.onlyTransferNewFiles },
                            set: { viewModel.updateOnlyTransferNewFiles($0) }
                        ))

                        dateFilterSection
                    }
                } else {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            mediaTypeSection

                            Toggle("Yalnızca yeni dosyaları aktar", isOn: Binding(
                                get: { viewModel.onlyTransferNewFiles },
                                set: { viewModel.updateOnlyTransferNewFiles($0) }
                            ))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        dateFilterSection
                    }
                }
            }

            LazyVGrid(columns: metricColumns(isCompact: isCompact), alignment: .leading, spacing: 12) {
                metricCard(title: "Fotoğraflar", value: "\(viewModel.scanSummary.totalPhotos)")
                metricCard(title: "Videolar", value: "\(viewModel.scanSummary.totalVideos)")
                metricCard(title: "Toplam Boyut", value: FormattingHelpers.formattedByteCount(viewModel.scanSummary.totalBytes))
                metricCard(title: "Kaynak", value: viewModel.scanSummary.deviceLabel)
            }
        }
        .padding(22)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 14, x: 0, y: 6)
    }

    private var mediaTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Medya Türü")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Medya Türü", selection: Binding(
                get: { viewModel.mediaTransferFilter },
                set: { viewModel.updateMediaTransferFilter($0) }
            )) {
                ForEach(MediaTransferFilter.allCases, id: \.self) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dateFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tarih Aralığı")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.importDateFilter.mode == .all {
                VStack(alignment: .leading, spacing: 4) {
                    Picker("Tarih Aralığı", selection: Binding(
                        get: { viewModel.importDateFilter.mode },
                        set: { viewModel.updateImportDateFilterMode($0) }
                    )) {
                        ForEach(ImportDateFilterMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(minWidth: 120)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 14) {
                        Picker("Tarih Aralığı", selection: Binding(
                            get: { viewModel.importDateFilter.mode },
                            set: { viewModel.updateImportDateFilterMode($0) }
                        )) {
                            ForEach(ImportDateFilterMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(minWidth: 120)

                        if viewModel.importDateFilter.mode == .specificMonth {
                            Picker("Ay", selection: Binding(
                                get: { viewModel.importDateFilter.month },
                                set: { viewModel.updateImportDateFilterMonth($0) }
                            )) {
                                ForEach(viewModel.availableMonthsForSelectedYear, id: \.self) { month in
                                    Text(ImportDateFilter(mode: .specificMonth, year: viewModel.importDateFilter.year, month: month).monthTitle).tag(month)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(minWidth: 120)
                        }

                        if viewModel.importDateFilter.mode == .specificYear || viewModel.importDateFilter.mode == .specificMonth {
                            Picker("Yıl", selection: Binding(
                                get: { viewModel.importDateFilter.year },
                                set: { viewModel.updateImportDateFilterYear($0) }
                            )) {
                                ForEach(viewModel.availableAssetYears, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(minWidth: 100)
                        }

                        Spacer(minLength: 0)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(14)
        .background(Color(red: 0.96, green: 0.98, blue: 1.0), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var settingsSheet: some View {
        NavigationStack {
            settingsContent
                .padding(24)
                .frame(minWidth: 480, idealWidth: 560)
                .navigationTitle("Ayarlar")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Kapat") {
                            isSettingsPresented = false
                        }
                    }
                }
        }
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Aktarım bitince hedef klasörü otomatik aç", isOn: Binding(
                get: { viewModel.settings.autoOpenTargetFolderAfterTransfer },
                set: { newValue in
                    viewModel.updateSettings { $0.autoOpenTargetFolderAfterTransfer = newValue }
                }
            ))

            Toggle("Aktarım bitince bildirim göster", isOn: Binding(
                get: { viewModel.settings.showCompletionNotification },
                set: { newValue in
                    viewModel.updateSettings { $0.showCompletionNotification = newValue }
                }
            ))

            Toggle("JSON aktarım raporu kaydet", isOn: Binding(
                get: { viewModel.settings.saveTransferReports },
                set: { newValue in
                    viewModel.updateSettings { $0.saveTransferReports = newValue }
                }
            ))

            Toggle("Hata logu kaydet", isOn: Binding(
                get: { viewModel.settings.saveErrorLogs },
                set: { newValue in
                    viewModel.updateSettings { $0.saveErrorLogs = newValue }
                }
            ))

            Spacer(minLength: 0)
        }
    }

    private func transferCard(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Kopyalama Durumu")
                .font(.title2.weight(.semibold))

            HStack {
                transferTypeBadge(value: viewModel.currentTransferStatusText)
                Spacer()
            }

            ProgressView(value: viewModel.transferProgress.fractionCompleted)
                .progressViewStyle(.linear)
                .scaleEffect(y: 1.6)

            LazyVGrid(columns: metricColumns(isCompact: isCompact), alignment: .leading, spacing: 12) {
                metricCard(title: "Anlık Dosya", value: viewModel.transferProgress.currentFileName)
                metricCard(title: "Kopyalanan", value: "\(viewModel.transferProgress.copiedFiles)")
                metricCard(title: "Fotoğraf", value: "\(viewModel.transferProgress.copiedPhotos)")
                metricCard(title: "Video", value: "\(viewModel.transferProgress.copiedVideos)")
                metricCard(title: "Kalan", value: "\(viewModel.transferProgress.remainingFiles)")
                metricCard(title: "Kalan Boyut", value: FormattingHelpers.formattedByteCount(viewModel.transferProgress.remainingBytes))
                metricCard(title: "Hız", value: viewModel.transferSpeedText)
                metricCard(title: "Tahmini Süre", value: FormattingHelpers.formattedDuration(viewModel.transferProgress.estimatedRemainingTime))
            }

            HStack(spacing: 12) {
                Button("Duraklat") {
                    viewModel.pauseTransfer()
                }
                .disabled(viewModel.isTransferPaused || viewModel.screenState != .copying)

                Button("Devam Et") {
                    viewModel.resumeTransfer()
                }
                .disabled(!viewModel.isTransferPaused || viewModel.screenState != .copying)

                Button("İptal") {
                    viewModel.cancelTransfer()
                }
                .disabled(viewModel.screenState != .copying)
            }
            .buttonStyle(.bordered)
        }
        .padding(22)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 14, x: 0, y: 6)
    }

    private func transferTypeBadge(value: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(value.contains("video") ? Color.orange : Color.blue)
                .frame(width: 10, height: 10)

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.04), in: Capsule())
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aktarım Planı")
                .font(.title2.weight(.semibold))

            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 140), spacing: 12),
                GridItem(.flexible(minimum: 140), spacing: 12)
            ], alignment: .leading, spacing: 12) {
                metricCard(title: "Toplam Öğe", value: "\(viewModel.plannedImportSummary.totalItems)")
                metricCard(title: "Kopyalanacak", value: "\(viewModel.plannedImportSummary.itemsToCopy)")
                metricCard(title: "Atlanacak Duplicate", value: "\(viewModel.plannedImportSummary.duplicateItems)")
                metricCard(title: "Seçili Tür", value: viewModel.mediaTransferFilter.title)
                metricCard(title: "Tarih Aralığı", value: viewModel.importDateFilter.summaryText)
            }
        }
        .padding(22)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 14, x: 0, y: 6)
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.completionHeadlineText)
                    .font(.system(size: 30, weight: .bold))

                Text(viewModel.completionDetailText)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if viewModel.transferSummary.wasCancelled {
                Text("İşlem tamamlanmadan iptal edildi.")
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 16) {
                highlightedSummaryCard(
                    title: "Toplam Veri",
                    value: FormattingHelpers.formattedByteCount(viewModel.transferSummary.copiedBytes),
                    tint: Color(red: 0.12, green: 0.49, blue: 0.96)
                )
                highlightedSummaryCard(
                    title: "Toplam Süre",
                    value: FormattingHelpers.formattedDuration(viewModel.transferSummary.duration),
                    tint: Color(red: 0.06, green: 0.66, blue: 0.48)
                )
            }

            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 140), spacing: 12),
                GridItem(.flexible(minimum: 140), spacing: 12)
            ], alignment: .leading, spacing: 12) {
                metricCard(title: "Kopyalanan Veri", value: FormattingHelpers.formattedByteCount(viewModel.transferSummary.copiedBytes))
                metricCard(title: "Fotoğraf", value: "\(viewModel.transferSummary.copiedPhotos)")
                metricCard(title: "Video", value: "\(viewModel.transferSummary.copiedVideos)")
                metricCard(title: "Atlanan", value: "\(viewModel.transferSummary.skippedFiles)")
                metricCard(title: "Hata", value: "\(viewModel.transferSummary.failedFiles)")
                metricCard(title: "Süre", value: FormattingHelpers.formattedDuration(viewModel.transferSummary.duration))
            }

            HStack(spacing: 12) {
                Button("Hedef Klasörü Aç") {
                    viewModel.openTargetFolder()
                }
                .buttonStyle(.borderedProminent)

                Button("Hata Logunu Göster") {
                    viewModel.openErrorLog()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.transferSummary.logFileURL == nil)

                Button("Raporu Aç") {
                    viewModel.openTransferReport()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.transferSummary.reportFileURL == nil)
            }
        }
        .padding(22)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 14, x: 0, y: 6)
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Uyarı")
                .font(.headline)
            Text(message)
                .foregroundStyle(.red)
        }
        .padding(20)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func helperHintCard(message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "iphone.gen3")
                .foregroundStyle(Color(red: 0.12, green: 0.49, blue: 0.96))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color(red: 0.96, green: 0.98, blue: 1.0), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func highlightedSummaryCard(title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func historyRow(_ item: TransferHistoryItem) -> some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(FormattingHelpers.formattedDateTime(item.report.createdAt))
                    .font(.headline)
                Text(item.report.sourceDevice)
                    .foregroundStyle(.secondary)
                Text("Fotoğraf: \(item.report.copiedPhotos)  Video: \(item.report.copiedVideos)  Veri: \(FormattingHelpers.formattedByteCount(item.report.copiedBytes))")
                    .font(.subheadline)
                if item.report.wasCancelled {
                    Text("İptal edildi")
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            Button("Aç") {
                viewModel.openHistoryReport(item)
            }
            .buttonStyle(.bordered)
            Button("Sil") {
                viewModel.deleteHistoryItem(item)
            }
            .buttonStyle(.bordered)
        }
        .padding(16)
        .background(Color(red: 0.96, green: 0.98, blue: 1.0), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            viewModel.selectHistoryItem(item)
        }
    }

    private func historyDetailsCard(_ item: TransferHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seçili Rapor")
                .font(.headline)

            HStack(spacing: 16) {
                metricCard(title: "Tarih", value: FormattingHelpers.formattedDateTime(item.report.createdAt))
                metricCard(title: "Cihaz", value: item.report.sourceDevice)
                metricCard(title: "Süre", value: FormattingHelpers.formattedDuration(item.report.duration))
            }

            HStack(spacing: 16) {
                metricCard(title: "Fotoğraf", value: "\(item.report.copiedPhotos)")
                metricCard(title: "Video", value: "\(item.report.copiedVideos)")
                metricCard(title: "Atlanan", value: "\(item.report.skippedFiles)")
                metricCard(title: "Hata", value: "\(item.report.failedFiles)")
            }

            Text(item.report.targetFolderPath)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .padding(16)
        .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func infoPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.weight(.medium))
                .lineLimit(2)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 19, weight: .semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(red: 0.96, green: 0.98, blue: 1.0), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct DeviceStatusRow: View {
    let deviceStateTitle: String
    let targetFolderPath: String
    let isStacked: Bool

    var body: some View {
        Group {
            if isStacked {
                VStack(spacing: 12) {
                    infoPill(title: "Cihaz Durumu", value: deviceStateTitle)
                    infoPill(title: "Hedef Klasör", value: targetFolderPath)
                }
            } else {
                HStack(spacing: 16) {
                    infoPill(title: "Cihaz Durumu", value: deviceStateTitle)
                    infoPill(title: "Hedef Klasör", value: targetFolderPath)
                }
            }
        }
    }

    private func infoPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

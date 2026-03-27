import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: AppViewModel
    @State private var isSettingsPresented = false
    private let supportURL = URL(string: "https://www.paypal.me/YOgnyanov")

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

                            supportFooter
                        }
                        .frame(maxWidth: 1120)
                        .padding(isNarrow ? 20 : 28)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(AppLanguage.text("iPhone Medya Aktarıcı", "iPhone Media Importer"))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isSettingsPresented = true
                    } label: {
                        Label(AppLanguage.text("Ayarlar", "Settings"), systemImage: "gearshape.fill")
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

                Text(AppLanguage.text("iPhone'dan Mac'e kolay aktarım", "Easy transfer from iPhone to Mac"))
                    .font(.system(size: 28, weight: .semibold))
            }

            Text(AppLanguage.text("iPhone'unuzdaki fotoğraf ve video dosyalarını Mac'inize aktarır.", "Transfers photo and video files from your iPhone to your Mac."))
                .foregroundStyle(.secondary)

            if viewModel.isDemoMode {
                Label(AppLanguage.text("Demo modu aktif. Gerçek cihaz yerine örnek medya listesi kullanılıyor.", "Demo mode is active. Sample media is shown instead of a real device."), systemImage: "bolt.horizontal.circle")
                    .foregroundStyle(Color.orange)
            }

            DeviceStatusRow(
                deviceStateTitle: viewModel.deviceStateTitle,
                targetFolderPath: viewModel.targetFolderURL?.path(percentEncoded: false) ?? AppLanguage.text("Seçilmedi", "Not selected"),
                isStacked: isNarrow
            )
            .id("device-status-row-\(AppLanguage.localeIdentifier)")

            if let deviceHelpMessage = viewModel.deviceHelpMessage {
                helperHintCard(message: deviceHelpMessage)
            }

            Group {
                if isNarrow {
                    VStack(alignment: .leading, spacing: 12) {
                        Button(AppLanguage.text("Hedef Klasör Seç", "Choose Destination Folder")) {
                            viewModel.chooseTargetFolder()
                        }
                        .buttonStyle(.bordered)

                        Button(AppLanguage.text("Seçimi Temizle", "Clear Selection")) {
                            viewModel.clearTargetFolderSelection()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.targetFolderURL == nil)

                        Button(AppLanguage.text("Yeniden Dene", "Retry")) {
                            viewModel.retryDeviceConnection()
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    HStack(spacing: 12) {
                        Button(AppLanguage.text("Hedef Klasör Seç", "Choose Destination Folder")) {
                            viewModel.chooseTargetFolder()
                        }
                        .buttonStyle(.bordered)

                        Button(AppLanguage.text("Seçimi Temizle", "Clear Selection")) {
                            viewModel.clearTargetFolderSelection()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.targetFolderURL == nil)

                        Button(AppLanguage.text("Yeniden Dene", "Retry")) {
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
            Label(AppLanguage.text("Tara", "Scan"), systemImage: "waveform.magnifyingglass")
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
            Label(AppLanguage.text("Kopyalamayı Başlat", "Start Transfer"), systemImage: "arrow.down.circle.fill")
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

    private var supportFooter: some View {
        HStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .foregroundStyle(Color(red: 0.60, green: 0.37, blue: 0.18))

            Text(AppLanguage.text("Uygulamayı beğendiyseniz bir kahve ısmarlayabilirsiniz.", "If you enjoyed the app, you can buy me a coffee."))
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let supportURL {
                Link(AppLanguage.text("Destek Ol", "Support"), destination: supportURL)
                    .font(.footnote.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
    }

    private func scanOverviewCard(isCompact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppLanguage.text("Tarama Sonucu", "Scan Results"))
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 12) {
                Text(AppLanguage.text("Aktarım Seçenekleri", "Transfer Options"))
                    .font(.headline)

                if isCompact {
                    VStack(alignment: .leading, spacing: 12) {
                        mediaTypeSection

                        Toggle(AppLanguage.text("Yalnızca yeni dosyaları aktar", "Transfer only new files"), isOn: Binding(
                            get: { viewModel.onlyTransferNewFiles },
                            set: { viewModel.updateOnlyTransferNewFiles($0) }
                        ))

                        dateFilterSection
                    }
                } else {
                    HStack(alignment: .top, spacing: 16) {
                        VStack(alignment: .leading, spacing: 12) {
                            mediaTypeSection

                            Toggle(AppLanguage.text("Yalnızca yeni dosyaları aktar", "Transfer only new files"), isOn: Binding(
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
                metricCard(title: AppLanguage.text("Fotoğraflar", "Photos"), value: "\(viewModel.scanSummary.totalPhotos)")
                metricCard(title: AppLanguage.text("Videolar", "Videos"), value: "\(viewModel.scanSummary.totalVideos)")
                metricCard(title: AppLanguage.text("Toplam Boyut", "Total Size"), value: FormattingHelpers.formattedByteCount(viewModel.scanSummary.totalBytes))
                metricCard(title: AppLanguage.text("Kaynak", "Source"), value: FormattingHelpers.localizedDeviceName(viewModel.scanSummary.deviceLabel))
            }
        }
        .padding(22)
        .background(Color.white.opacity(0.86), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 14, x: 0, y: 6)
    }

    private var mediaTypeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLanguage.text("Medya Türü", "Media Type"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker(AppLanguage.text("Medya Türü", "Media Type"), selection: Binding(
                get: { viewModel.mediaTransferFilter },
                set: { viewModel.updateMediaTransferFilter($0) }
            )) {
                ForEach(MediaTransferFilter.allCases, id: \.self) { filter in
                    Text(filter.title).tag(filter)
                }
            }
            .id("media-transfer-filter-\(AppLanguage.localeIdentifier)")
            .pickerStyle(.segmented)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dateFilterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppLanguage.text("Tarih Aralığı", "Date Range"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.importDateFilter.mode == .all {
                VStack(alignment: .leading, spacing: 4) {
                    Picker(AppLanguage.text("Tarih Aralığı", "Date Range"), selection: Binding(
                        get: { viewModel.importDateFilter.mode },
                        set: { viewModel.updateImportDateFilterMode($0) }
                    )) {
                        ForEach(ImportDateFilterMode.allCases, id: \.self) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .id("date-filter-mode-all-\(AppLanguage.localeIdentifier)")
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(minWidth: 120)
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center, spacing: 14) {
                        Picker(AppLanguage.text("Tarih Aralığı", "Date Range"), selection: Binding(
                            get: { viewModel.importDateFilter.mode },
                            set: { viewModel.updateImportDateFilterMode($0) }
                        )) {
                            ForEach(ImportDateFilterMode.allCases, id: \.self) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .id("date-filter-mode-\(AppLanguage.localeIdentifier)")
                        .labelsHidden()
                        .pickerStyle(.menu)
                        .frame(minWidth: 120)

                        if viewModel.importDateFilter.mode == .specificMonth {
                            Picker(AppLanguage.text("Ay", "Month"), selection: Binding(
                                get: { viewModel.importDateFilter.month },
                                set: { viewModel.updateImportDateFilterMonth($0) }
                            )) {
                                ForEach(viewModel.availableMonthsForSelectedYear, id: \.self) { month in
                                    Text(ImportDateFilter(mode: .specificMonth, year: viewModel.importDateFilter.year, month: month).monthTitle).tag(month)
                                }
                            }
                            .id("date-filter-month-\(AppLanguage.localeIdentifier)-\(viewModel.importDateFilter.year)")
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(minWidth: 120)
                        }

                        if viewModel.importDateFilter.mode == .specificYear || viewModel.importDateFilter.mode == .specificMonth {
                            Picker(AppLanguage.text("Yıl", "Year"), selection: Binding(
                                get: { viewModel.importDateFilter.year },
                                set: { viewModel.updateImportDateFilterYear($0) }
                            )) {
                                ForEach(viewModel.availableAssetYears, id: \.self) { year in
                                    Text(String(year)).tag(year)
                                }
                            }
                            .id("date-filter-year-\(AppLanguage.localeIdentifier)-\(viewModel.availableAssetYears.map(String.init).joined(separator: "-"))")
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
                .navigationTitle(AppLanguage.text("Ayarlar", "Settings"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(AppLanguage.text("Kapat", "Close")) {
                            isSettingsPresented = false
                        }
                    }
                }
        }
    }

    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppLanguage.text("Uygulama Dili", "App Language"))
                    .font(.headline)

                    Picker(
                        AppLanguage.text("Uygulama Dili", "App Language"),
                        selection: Binding(
                            get: { viewModel.settings.languagePreference },
                            set: { newValue in
                            viewModel.updateSettings { $0.languagePreference = newValue }
                        }
                    )
                ) {
                        ForEach(AppLanguagePreference.allCases, id: \.self) { preference in
                            Text(preference.title).tag(preference)
                        }
                    }
                    .id("app-language-picker-\(AppLanguage.localeIdentifier)")
                    .pickerStyle(.segmented)
                }

            Toggle(AppLanguage.text("Aktarım bitince hedef klasörü otomatik aç", "Open destination folder automatically after transfer"), isOn: Binding(
                get: { viewModel.settings.autoOpenTargetFolderAfterTransfer },
                set: { newValue in
                    viewModel.updateSettings { $0.autoOpenTargetFolderAfterTransfer = newValue }
                }
            ))

            Toggle(AppLanguage.text("Aktarım bitince bildirim göster", "Show notification when transfer finishes"), isOn: Binding(
                get: { viewModel.settings.showCompletionNotification },
                set: { newValue in
                    viewModel.updateSettings { $0.showCompletionNotification = newValue }
                }
            ))

            Toggle(AppLanguage.text("JSON aktarım raporu kaydet", "Save JSON transfer report"), isOn: Binding(
                get: { viewModel.settings.saveTransferReports },
                set: { newValue in
                    viewModel.updateSettings { $0.saveTransferReports = newValue }
                }
            ))

            Toggle(AppLanguage.text("Hata logu kaydet", "Save error log"), isOn: Binding(
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
            Text(AppLanguage.text("Kopyalama Durumu", "Transfer Status"))
                .font(.title2.weight(.semibold))

            HStack {
                transferTypeBadge(value: viewModel.currentTransferStatusText)
                Spacer()
            }

            ProgressView(value: viewModel.transferProgress.fractionCompleted)
                .progressViewStyle(.linear)
                .scaleEffect(y: 1.6)

            LazyVGrid(columns: metricColumns(isCompact: isCompact), alignment: .leading, spacing: 12) {
                metricCard(title: AppLanguage.text("Anlık Dosya", "Current File"), value: viewModel.transferProgress.currentFileName)
                metricCard(title: AppLanguage.text("Kopyalanan", "Copied"), value: "\(viewModel.transferProgress.copiedFiles)")
                metricCard(title: AppLanguage.text("Fotoğraf", "Photos"), value: "\(viewModel.transferProgress.copiedPhotos)")
                metricCard(title: AppLanguage.text("Video", "Videos"), value: "\(viewModel.transferProgress.copiedVideos)")
                metricCard(title: AppLanguage.text("Kalan", "Remaining"), value: "\(viewModel.transferProgress.remainingFiles)")
                metricCard(title: AppLanguage.text("Kalan Boyut", "Remaining Size"), value: FormattingHelpers.formattedByteCount(viewModel.transferProgress.remainingBytes))
                metricCard(title: AppLanguage.text("Hız", "Speed"), value: viewModel.transferSpeedText)
                metricCard(title: AppLanguage.text("Tahmini Süre", "Estimated Time"), value: FormattingHelpers.formattedDuration(viewModel.transferProgress.estimatedRemainingTime))
            }

            HStack(spacing: 12) {
                Button(AppLanguage.text("Duraklat", "Pause")) {
                    viewModel.pauseTransfer()
                }
                .disabled(viewModel.isTransferPaused || viewModel.screenState != .copying)

                Button(AppLanguage.text("Devam Et", "Resume")) {
                    viewModel.resumeTransfer()
                }
                .disabled(!viewModel.isTransferPaused || viewModel.screenState != .copying)

                Button(AppLanguage.text("İptal", "Cancel")) {
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
            Text(AppLanguage.text("Aktarım Planı", "Transfer Plan"))
                .font(.title2.weight(.semibold))

            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 140), spacing: 12),
                GridItem(.flexible(minimum: 140), spacing: 12)
            ], alignment: .leading, spacing: 12) {
                metricCard(title: AppLanguage.text("Toplam Öğe", "Total Items"), value: "\(viewModel.plannedImportSummary.totalItems)")
                metricCard(title: AppLanguage.text("Kopyalanacak", "To Copy"), value: "\(viewModel.plannedImportSummary.itemsToCopy)")
                metricCard(title: AppLanguage.text("Atlanacak Duplicate", "Skipped Duplicates"), value: "\(viewModel.plannedImportSummary.duplicateItems)")
                metricCard(title: AppLanguage.text("Seçili Tür", "Selected Type"), value: viewModel.mediaTransferFilter.title)
                metricCard(title: AppLanguage.text("Tarih Aralığı", "Date Range"), value: viewModel.importDateFilter.summaryText)
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
                Text(AppLanguage.text("İşlem tamamlanmadan iptal edildi.", "The transfer was cancelled before completion."))
                    .foregroundStyle(.orange)
            }

            HStack(spacing: 16) {
                highlightedSummaryCard(
                    title: AppLanguage.text("Toplam Veri", "Total Data"),
                    value: FormattingHelpers.formattedByteCount(viewModel.transferSummary.copiedBytes),
                    tint: Color(red: 0.12, green: 0.49, blue: 0.96)
                )
                highlightedSummaryCard(
                    title: AppLanguage.text("Toplam Süre", "Total Time"),
                    value: FormattingHelpers.formattedDuration(viewModel.transferSummary.duration),
                    tint: Color(red: 0.06, green: 0.66, blue: 0.48)
                )
            }

            LazyVGrid(columns: [
                GridItem(.flexible(minimum: 140), spacing: 12),
                GridItem(.flexible(minimum: 140), spacing: 12)
            ], alignment: .leading, spacing: 12) {
                metricCard(title: AppLanguage.text("Kopyalanan Veri", "Copied Data"), value: FormattingHelpers.formattedByteCount(viewModel.transferSummary.copiedBytes))
                metricCard(title: AppLanguage.text("Fotoğraf", "Photos"), value: "\(viewModel.transferSummary.copiedPhotos)")
                metricCard(title: AppLanguage.text("Video", "Videos"), value: "\(viewModel.transferSummary.copiedVideos)")
                metricCard(title: AppLanguage.text("Atlanan", "Skipped"), value: "\(viewModel.transferSummary.skippedFiles)")
                metricCard(title: AppLanguage.text("Hata", "Errors"), value: "\(viewModel.transferSummary.failedFiles)")
                metricCard(title: AppLanguage.text("Süre", "Duration"), value: FormattingHelpers.formattedDuration(viewModel.transferSummary.duration))
            }

            HStack(spacing: 12) {
                Button(AppLanguage.text("Hedef Klasörü Aç", "Open Destination Folder")) {
                    viewModel.openTargetFolder()
                }
                .buttonStyle(.borderedProminent)

                Button(AppLanguage.text("Hata Logunu Göster", "Show Error Log")) {
                    viewModel.openErrorLog()
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.transferSummary.logFileURL == nil)

                Button(AppLanguage.text("Raporu Aç", "Open Report")) {
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
            Text(AppLanguage.text("Uyarı", "Notice"))
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
                Text(
                    AppLanguage.isTurkish
                    ? "Fotoğraf: \(item.report.copiedPhotos)  Video: \(item.report.copiedVideos)  Veri: \(FormattingHelpers.formattedByteCount(item.report.copiedBytes))"
                    : "Photos: \(item.report.copiedPhotos)  Videos: \(item.report.copiedVideos)  Data: \(FormattingHelpers.formattedByteCount(item.report.copiedBytes))"
                )
                    .font(.subheadline)
                if item.report.wasCancelled {
                    Text(AppLanguage.text("İptal edildi", "Cancelled"))
                        .foregroundStyle(.orange)
                }
            }
            Spacer()
            Button(AppLanguage.text("Aç", "Open")) {
                viewModel.openHistoryReport(item)
            }
            .buttonStyle(.bordered)
            Button(AppLanguage.text("Sil", "Delete")) {
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
            Text(AppLanguage.text("Seçili Rapor", "Selected Report"))
                .font(.headline)

            HStack(spacing: 16) {
                metricCard(title: AppLanguage.text("Tarih", "Date"), value: FormattingHelpers.formattedDateTime(item.report.createdAt))
                metricCard(title: AppLanguage.text("Cihaz", "Device"), value: item.report.sourceDevice)
                metricCard(title: AppLanguage.text("Süre", "Duration"), value: FormattingHelpers.formattedDuration(item.report.duration))
            }

            HStack(spacing: 16) {
                metricCard(title: AppLanguage.text("Fotoğraf", "Photos"), value: "\(item.report.copiedPhotos)")
                metricCard(title: AppLanguage.text("Video", "Videos"), value: "\(item.report.copiedVideos)")
                metricCard(title: AppLanguage.text("Atlanan", "Skipped"), value: "\(item.report.skippedFiles)")
                metricCard(title: AppLanguage.text("Hata", "Errors"), value: "\(item.report.failedFiles)")
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
                    infoPill(title: AppLanguage.text("Cihaz Durumu", "Device Status"), value: deviceStateTitle)
                    infoPill(title: AppLanguage.text("Hedef Klasör", "Destination Folder"), value: targetFolderPath)
                }
            } else {
                HStack(spacing: 16) {
                    infoPill(title: AppLanguage.text("Cihaz Durumu", "Device Status"), value: deviceStateTitle)
                    infoPill(title: AppLanguage.text("Hedef Klasör", "Destination Folder"), value: targetFolderPath)
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

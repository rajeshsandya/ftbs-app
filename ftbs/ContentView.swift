//
//  ContentView.swift
//  ftbs
//
//  Created by Rajesh Sandya on 7/6/26.
//

import SwiftUI
#if os(macOS)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var viewModel = BibleViewModel()
    @State private var currentScreen: AppScreen = .home

    private var theme: FTBSTheme { FTBSTheme(colorScheme) }

    var body: some View {
        Group {
            if currentScreen == .home {
                HomePageView(
                    viewModel: viewModel,
                    onEnterBible: { currentScreen = .bible },
                    onHome: { currentScreen = .home }
                )
            } else {
                BibleReaderRoot(viewModel: viewModel, onHome: { currentScreen = .home })
            }
        }
        .tint(theme.accent)
        .task {
            await viewModel.loadIfNeeded()
        }
        .alert("Unable to Load Bible", isPresented: errorAlertIsPresented) {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
    }

    private var errorAlertIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    viewModel.errorMessage = nil
                }
            }
        )
    }
}

private enum AppScreen {
    case home
    case bible
}

private struct BibleReaderRoot: View {
    @ObservedObject var viewModel: BibleViewModel
    let onHome: () -> Void

    var body: some View {
        BibleReaderDetail(viewModel: viewModel, onHome: onHome)
    }
}

private struct BibleSidebar: View {
    @ObservedObject var viewModel: BibleViewModel

    var body: some View {
        List {
            Section(BibleBook.Testament.old.rawValue) {
                ForEach(viewModel.oldTestamentBooks) { book in
                    SidebarBookRow(
                        title: book.bname,
                        isSelected: viewModel.selectedBookNumber == book.bnumber
                    ) {
                        viewModel.selectBook(book)
                    }
                }
            }

            Section(BibleBook.Testament.new.rawValue) {
                ForEach(viewModel.newTestamentBooks) { book in
                    SidebarBookRow(
                        title: book.bname,
                        isSelected: viewModel.selectedBookNumber == book.bnumber
                    ) {
                        viewModel.selectBook(book)
                    }
                }
            }
        }
#if os(macOS)
        .navigationSplitViewColumnWidth(min: 240, ideal: 280)
#endif
        .navigationTitle("FTBS Bible")
    }
}

private struct BibleCompactSidebar: View {
    @ObservedObject var viewModel: BibleViewModel
    let onSelectBook: (BibleBook) -> Void

    var body: some View {
        List {
            Section(BibleBook.Testament.old.rawValue) {
                ForEach(viewModel.oldTestamentBooks) { book in
                    SidebarBookRow(
                        title: book.bname,
                        isSelected: viewModel.selectedBookNumber == book.bnumber
                    ) {
                        onSelectBook(book)
                    }
                }
            }

            Section(BibleBook.Testament.new.rawValue) {
                ForEach(viewModel.newTestamentBooks) { book in
                    SidebarBookRow(
                        title: book.bname,
                        isSelected: viewModel.selectedBookNumber == book.bnumber
                    ) {
                        onSelectBook(book)
                    }
                }
            }
        }
        .navigationTitle("FTBS Bible")
    }
}

private struct SidebarBookRow: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

private struct BibleReaderDetail: View {
    @ObservedObject var viewModel: BibleViewModel
    let onHome: () -> Void
    @State private var showingAboutUs = false
    @State private var showingContactUs = false
    @State private var showingBookPicker = false
    @State private var showingSearchPanel = false
    @State private var showingSettingsPanel = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.books.isEmpty {
                    ProgressView("Loading Bible...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.books.isEmpty {
                    ContentUnavailableView(
                        "Bible data unavailable",
                        systemImage: "book.closed",
                        description: Text("Bundle the Bible JSON files and `crossReferences.json` inside the app target.")
                    )
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        ReaderHeader(
                            viewModel: viewModel,
                            onHome: onHome,
                            onBooks: {
                                showingBookPicker = true
                            },
                            onSearch: {
                                showingSearchPanel = true
                            },
                            onAboutUs: {
                                showingAboutUs = true
                            },
                            onContactUs: {
                                showingContactUs = true
                            }
                        )

                        if viewModel.showingSearchResults {
                            SearchResultsView(viewModel: viewModel)
                        } else {
                            ChapterReaderView(viewModel: viewModel)
                        }

                        SelectedVersesShareBar(viewModel: viewModel)

#if !os(macOS)
                        HStack(spacing: 12) {
                            Button {
                                viewModel.showPreviousChapter()
                            } label: {
                                Label("Prev", systemImage: "chevron.left")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                showingBookPicker = true
                            } label: {
                                Image(systemName: "books.vertical")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)

                            Button {
                                viewModel.showNextChapter()
                            } label: {
                                Label("Next", systemImage: "chevron.right")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)

                            Button {
                                showingSettingsPanel = true
                            } label: {
                                Image(systemName: "gearshape")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Settings")
                        }
#endif
                    }
                    .padding()
                }
            }
            .navigationDestination(isPresented: $showingAboutUs) {
                AboutUsPage()
            }
            .navigationDestination(isPresented: $showingContactUs) {
                ContactUsPage()
            }
            .navigationDestination(isPresented: $showingBookPicker) {
                BookChapterPickerView(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showingSearchPanel) {
                SearchPage(viewModel: viewModel)
            }
            .navigationDestination(isPresented: $showingSettingsPanel) {
                NavigationStack {
                    SettingsPanel(viewModel: viewModel)
                }
            }
        }
    }
}

private struct ReaderHeader: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var viewModel: BibleViewModel
    let onHome: () -> Void
    let onBooks: () -> Void
    let onSearch: () -> Void
    let onAboutUs: () -> Void
    let onContactUs: () -> Void
    @State private var activePopover: AppPopover?

    private var theme: FTBSTheme { FTBSTheme(colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if horizontalSizeClass == .compact {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 12) {
                        titleBlock
                        Spacer(minLength: 8)
                        compactUtilityButtons
                    }
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        titleBlock
                        Spacer(minLength: 8)
                        actionButtons
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        titleBlock
                        actionButtons
                    }
                }
            }

        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .popover(item: $activePopover, arrowEdge: .top) { popover in
            NavigationStack {
                Group {
                    switch popover {
                    case .settings:
                        SettingsPanel(viewModel: viewModel)
                    }
                }
            }
            .frame(minWidth: 320, idealWidth: 360, minHeight: 480, idealHeight: 540)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(headerTitle)
                .font(titleFont)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            Button {
                onHome()
            } label: {
                Image(systemName: "house")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Home")

            Button {
                onBooks()
            } label: {
                Image(systemName: "books.vertical")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .accessibilityLabel("Books & Chapters")

            Button {
                onSearch()
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Search")

            Button {
                viewModel.goBack()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!viewModel.canGoBack)
            .accessibilityLabel("Go back")

            Button {
                viewModel.goForward()
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!viewModel.canGoForward)
            .accessibilityLabel("Go forward")

            Button {
                activePopover = .settings
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Settings")

            Button {
                onAboutUs()
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("About Us")

            Button {
                onContactUs()
            } label: {
                Image(systemName: "envelope")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Contact Us")
        }
    }

    private var compactUtilityButtons: some View {
        HStack(spacing: 4) {
            Button {
                onHome()
            } label: {
                Image(systemName: "house")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Home")

            Button {
                onSearch()
            } label: {
                Image(systemName: "magnifyingglass")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Search")

            Button {
                viewModel.goBack()
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!viewModel.canGoBack)
            .accessibilityLabel("Go back")

            Button {
                viewModel.goForward()
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(!viewModel.canGoForward)
            .accessibilityLabel("Go forward")
        }
    }

    private var titleFont: Font {
        horizontalSizeClass == .compact ? .title2.weight(.semibold) : .largeTitle.weight(.semibold)
    }

    private var headerTitle: String {
        let bookName = viewModel.selectedBook?.bname ?? "Bible"
        return "\(bookName) \(viewModel.selectedChapterNumber)"
    }
}

private struct BookChapterPickerView: View {
    @ObservedObject var viewModel: BibleViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var expandedBookNumber: Int?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Select a book and chapter")
                    .font(.title2.weight(.semibold))

                bookSection(title: BibleBook.Testament.old.rawValue, books: viewModel.oldTestamentBooks)
                bookSection(title: BibleBook.Testament.new.rawValue, books: viewModel.newTestamentBooks)
            }
            .padding()
            .frame(maxWidth: 900, alignment: .leading)
        }
        .navigationTitle("Books & Chapters")
    }

    private func bookSection(title: String, books: [BibleBook]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(books) { book in
                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            toggleBookExpansion(book)
                        } label: {
                            HStack(spacing: 10) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(book.bname)
                                        .font(.subheadline.weight(.semibold))
                                    Text("\(book.chapters.count) chapters")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 8)
                                Text(expandedBookNumber == book.bnumber ? "Collapse" : "Expand")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Image(systemName: expandedBookNumber == book.bnumber ? "chevron.up" : "chevron.down")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 1)
                        .padding(.vertical, 1)
                        .background {
                            Capsule()
                                .fill(viewModel.selectedBookNumber == book.bnumber ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.10))
                        }
                        .overlay {
                            Capsule()
                                .stroke(viewModel.selectedBookNumber == book.bnumber ? Color.accentColor.opacity(0.55) : Color.secondary.opacity(0.35), lineWidth: 1)
                        }

                        if expandedBookNumber == book.bnumber {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Chapters in \(book.bname)")
                                    .font(.subheadline.weight(.semibold))

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 8)], spacing: 8) {
                                    ForEach(book.chapters) { chapter in
                                        Button {
                                            selectChapter(book, chapterNumber: chapter.cnumber)
                                        } label: {
                                            Text("\(chapter.cnumber)")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(viewModel.selectedBookNumber == book.bnumber && viewModel.selectedChapterNumber == chapter.cnumber ? .white : .primary)
                                                .frame(width: 52, height: 40)
                                                .background {
                                                    Capsule()
                                                        .fill(viewModel.selectedBookNumber == book.bnumber && viewModel.selectedChapterNumber == chapter.cnumber ? Color.accentColor : Color.secondary.opacity(0.12))
                                                }
                                                .overlay {
                                                    Capsule()
                                                        .stroke(viewModel.selectedBookNumber == book.bnumber && viewModel.selectedChapterNumber == chapter.cnumber ? Color.accentColor : Color.secondary.opacity(0.35), lineWidth: 1)
                                                }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.leading, 4)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func toggleBookExpansion(_ book: BibleBook) {
        if expandedBookNumber == book.bnumber {
            expandedBookNumber = nil
        } else {
            expandedBookNumber = book.bnumber
            viewModel.selectBook(book)
        }
    }

    private func selectChapter(_ book: BibleBook, chapterNumber: Int) {
        viewModel.selectBook(book, chapterNumber: chapterNumber)
        dismiss()
    }
}

private struct SelectedVersesShareBar: View {
    @ObservedObject var viewModel: BibleViewModel

    var body: some View {
        if viewModel.selectedVerseCount > 0, let selectedVersesText = viewModel.selectedVersesText() {
            HStack(spacing: 12) {
                Text("\(viewModel.selectedVerseCount) selected")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                ShareLink(item: selectedVersesText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

private struct VerseAnnotationLegend: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var isExpanded = false

    private var theme: FTBSTheme { FTBSTheme(colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            DisclosureGroup(isExpanded: $isExpanded) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(VerseHighlightColor.allCases) { color in
                            legendChip(title: color.displayName, swatch: verseHighlightSwatch(for: color, colorScheme: colorScheme))
                        }

                        legendChip(title: "Note", swatch: .secondary)
                    }
                    .padding(.vertical, 2)
                }
                .padding(.top, 4)
            } label: {
                Text("Verse Colors")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(theme.stroke.opacity(0.75), lineWidth: 1)
        }
    }

    private func legendChip(title: String, swatch: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(swatch)
                .frame(width: 12, height: 12)

            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.secondaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(theme.muted, in: Capsule())
        .overlay {
            Capsule()
                .stroke(theme.stroke.opacity(0.35), lineWidth: 1)
        }
    }
}

private struct SearchPage: View {
    @ObservedObject var viewModel: BibleViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                SearchControls(viewModel: viewModel)

                SelectedVersesShareBar(viewModel: viewModel)

                if viewModel.showingSearchResults {
                    SearchResultsView(viewModel: viewModel) { result in
                        viewModel.openSearchResult(result)
                        dismiss()
                    }
                } else {
                    ContentUnavailableView(
                        "Search the Bible",
                        systemImage: "magnifyingglass",
                        description: Text("Enter at least 3 characters to search the current book or the full Bible.")
                    )
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Search")
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onDisappear {
            if viewModel.showingSearchResults {
                viewModel.clearSearch()
            }
        }
    }
}

private enum AppPopover: String, Identifiable {
    case settings

    var id: String { rawValue }
}

private struct SettingsPanel: View {
    @ObservedObject var viewModel: BibleViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var theme: FTBSTheme { FTBSTheme(colorScheme) }

    var body: some View {
        Group {
            let panel = VStack(alignment: .leading, spacing: 14) {
                Text("Settings")
                    .font(.title2.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Reading Settings")
                        .font(.headline.weight(.bold))
                    Text("Adjust the current language, default language, parallel text, and font size.")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                settingsRow(title: "Current Language") {
                    Picker("Current Language", selection: languageBinding) {
                        ForEach(BibleLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                }

                settingsRow(title: "Default Language") {
                    Picker("Default Language", selection: defaultLanguageBinding) {
                        ForEach(BibleLanguage.allCases) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Text("Used when the app opens or when no language has been selected yet.")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                settingsRow(title: "Parallel Text") {
                    Toggle("", isOn: $viewModel.showParallelText)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                settingsRow(title: "Parallel Language") {
                    Picker("Parallel Language", selection: parallelLanguageBinding) {
                        ForEach(viewModel.availableParallelLanguages) { language in
                            Text(language.displayName).tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .disabled(!viewModel.showParallelText || viewModel.availableParallelLanguages.isEmpty)
                }

                settingsRow(title: "Font Size") {
                    Stepper(value: $viewModel.fontSize, in: 14...34, step: 1) {
                        Text("\(Int(viewModel.fontSize))")
                            .monospacedDigit()
                    }
                    .labelsHidden()
                }
            }

            if horizontalSizeClass == .compact {
                panel
                    .padding(16)
                    .frame(maxWidth: 360, maxHeight: .infinity, alignment: .topLeading)
                    .background(theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                panel
                    .padding(16)
                    .frame(maxWidth: 360, alignment: .leading)
                    .background(theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }

    private func settingsRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.secondaryText)
                .frame(width: 130, alignment: .leading)

            Spacer(minLength: 8)

            content()
        }
        .padding(.vertical, 2)
    }

    private var languageBinding: Binding<BibleLanguage> {
        Binding(
            get: { viewModel.selectedLanguage },
            set: { viewModel.selectLanguage($0) }
        )
    }

    private var parallelLanguageBinding: Binding<BibleLanguage> {
        Binding(
            get: { viewModel.parallelLanguage },
            set: { viewModel.selectParallelLanguage($0) }
        )
    }

    private var defaultLanguageBinding: Binding<BibleLanguage> {
        Binding(
            get: { viewModel.defaultLanguage },
            set: { viewModel.selectDefaultLanguage($0) }
        )
    }
}

private struct HomePageView: View {
    @ObservedObject var viewModel: BibleViewModel
    let onEnterBible: () -> Void
    let onHome: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAboutUs = false
    @State private var showingContactUs = false
    @State private var activePopover: AppPopover?

    private var theme: FTBSTheme { FTBSTheme(colorScheme) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Spacer(minLength: 0)
                        homeActions
                    }

                    heroCard

                    VStack(alignment: .leading, spacing: 14) {
                        infoCard(
                            title: "OUR EFFORTS TO GUIDE EVERYONE TO THE KINGDOM OF CHRIST",
                            body: "Round the clock and across the globe, to save the mankind, we preach the crucified Christ alone (focusing on the message of Jesus Christ after being crucified. We reach people right from country side to the most modern of communities. We strive to lessen religious conflicts by educating people in the way of God and enhance moral values, humanity and divinity in the hearts of the people. We answer the questions raised on Bible by Muslims, Hindus, Atheists and others. We conduct Spiritual camps spreading the need to control anti social activities. We take the help of Electronic and Print media to broadcast the necessity of education irrespective of Gender, Age, Caste, Creed, Sect, and Region etc. We conduct regular Bible Research Seminars throughout the year clarifying controversial doctrines/claims prevailing amongst the divided sects or denominations of Christianity. Since the inauguration of the Institute premises (on 15 th August, 2002) we have conducted 59 Seminars from the word of God (including a seminar on ALIENS / UFOs held on 17 th December 2010 and a seminar on 7 year trials, when and where is the 3 and ½ year food festival held on 15 th July 2012) on Biblical, Social, Historical, Scientific – Engineering & Medical and Law related topics. For further details on our Seminars and other works, please visit the Books CDs and Messages page. We train people as full-fledged Bible Technicians / Evangelists / Pastors to preach or teach the Gospel of Christ, to answer question(s) challenging our professed faith and to clear the doubts of anyone from any part of the world without charging any fee for our services."
                        )

                        twoColumnCardGrid

                        infoCard(
                            title: "OUR FAITH",
                            body: "We believe that Lord JESUS CHRIST is Son of GOD. We condemn the human created belief in man made doctrines and Charismatic gospels."
                        )

                        quoteCard
                    }

                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                LinearGradient(
                    colors: [theme.background, theme.warmBackground],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .navigationTitle("Full Truth Bible Society")
            .navigationDestination(isPresented: $showingAboutUs) {
                AboutUsPage()
            }
            .navigationDestination(isPresented: $showingContactUs) {
                ContactUsPage()
            }
            .popover(item: $activePopover, arrowEdge: .top) { popover in
                NavigationStack {
                    Group {
                        switch popover {
                        case .settings:
                            SettingsPanel(viewModel: viewModel)
                        }
                    }
                }
                .frame(minWidth: 320, idealWidth: 360, minHeight: 480, idealHeight: 540)
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Full Truth Bible Society", systemImage: "cross.fill")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text("OUR EFFORTS TO GUIDE EVERYONE TO THE KINGDOM OF CHRIST")
                .font(.headline)
                .foregroundStyle(theme.secondaryText)

            Text("A Bible reading and ministry companion designed to help you study, search, compare, and share the Word of God.")
                .foregroundStyle(theme.secondaryText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(theme.stroke, lineWidth: 1)
        }
    }

    private var twoColumnCardGrid: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 14) {
                infoCard(
                    title: "OUR VISION",
                    body: "Unite all Christian denominations in accordance with the Word of God (John 17:21)."
                )

                infoCard(
                    title: "OUR MISSION",
                    body: "To preach the Gospel of crucified Christ starting from remote villages to Metropolitan cities for no cost. (Matt 28: 19, 20. Mark 16:15)."
                )
            }

            VStack(alignment: .leading, spacing: 14) {
                infoCard(
                    title: "OUR VISION",
                    body: "Unite all Christian denominations in accordance with the Word of God (John 17:21)."
                )

                infoCard(
                    title: "OUR MISSION",
                    body: "To preach the Gospel of crucified Christ starting from remote villages to Metropolitan cities for no cost. (Matt 28: 19, 20. Mark 16:15)."
                )
            }
        }
    }

    private var quoteCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\" Kulamu Kullu – Matham Matthu – Dhanam Dhagha – Manishi Maaya – Devude Dikku \"")
                .font(.headline)
                .italic()
            Text("A message of faith and conviction guiding the ministry’s mission.")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.muted, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func infoCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.body)
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.stroke, lineWidth: 1)
        }
    }

    private var homeActions: some View {
        HStack(spacing: 8) {
            Button {
                onEnterBible()
            } label: {
                Image(systemName: "book")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .accessibilityLabel("Open Bible")

            Button {
                onHome()
            } label: {
                Image(systemName: "house")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(true)
            .accessibilityLabel("Home")

            Button {
                activePopover = .settings
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Settings")

            Button {
                showingAboutUs = true
            } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("About Us")

            Button {
                showingContactUs = true
            } label: {
                Image(systemName: "envelope")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("Contact Us")
        }
    }

}

private struct AboutUsPage: View {
    @Environment(\.colorScheme) private var colorScheme

    private var theme: FTBSTheme { FTBSTheme(colorScheme) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("OUR EFFORTS TO GUIDE EVERYONE TO THE KINGDOM OF CHRIST")
                        .font(.title2.weight(.semibold))

                    Text("Round the clock and across the globe, to save the mankind, we preach the crucified Christ alone (focusing on the message of Jesus Christ after being crucified. We reach people right from country side to the most modern of communities. We strive to lessen religious conflicts by educating people in the way of God and enhance moral values, humanity and divinity in the hearts of the people. We answer the questions raised on Bible by Muslims, Hindus, Atheists and others. We conduct Spiritual camps spreading the need to control anti social activities. We take the help of Electronic and Print media to broadcast the necessity of education irrespective of Gender, Age, Caste, Creed, Sect, and Region etc. We conduct regular Bible Research Seminars throughout the year clarifying controversial doctrines/claims prevailing amongst the divided sects or denominations of Christianity. Since the inauguration of the Institute premises (on 15 th August, 2002) we have conducted 59 Seminars from the word of God (including a seminar on ALIENS / UFOs held on 17 th December 2010 and a seminar on 7 year trials, when and where is the 3 and ½ year food festival held on 15 th July 2012) on Biblical, Social, Historical, Scientific – Engineering & Medical and Law related topics. For further details on our Seminars and other works, please visit the Books CDs and Messages page. We train people as full-fledged Bible Technicians / Evangelists / Pastors to preach or teach the Gospel of Christ, to answer question(s) challenging our professed faith and to clear the doubts of anyone from any part of the world without charging any fee for our services.")
                        .font(.body)
                        .foregroundStyle(theme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                aboutSection(title: "OUR VISION", body: "Unite all Christian denominations in accordance with the Word of God (John 17:21).")
                aboutSection(title: "OUR MISSION", body: "To preach the Gospel of crucified Christ starting from remote villages to Metropolitan cities for no cost. (Matt 28: 19, 20. Mark 16:15).")
                aboutSection(title: "OUR FAITH", body: "We believe that Lord JESUS CHRIST is Son of GOD. We condemn the human created belief in man made doctrines and Charismatic gospels.")

                VStack(alignment: .leading, spacing: 10) {
                    Text("\" Kulamu Kullu – Matham Matthu – Dhanam Dhagha – Manishi Maaya – Devude Dikku \"")
                        .font(.headline)
                        .italic()
                    Text("A message of faith and conviction guiding the ministry’s mission.")
                        .foregroundStyle(theme.secondaryText)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.muted.opacity(0.9), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding()
            .frame(maxWidth: 900, alignment: .leading)
        }
        .navigationTitle("About Us")
    }

    private func aboutSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(body)
                .foregroundStyle(theme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.stroke, lineWidth: 1)
        }
    }
}

private struct ContactUsPage: View {
    @Environment(\.colorScheme) private var colorScheme

    private var theme: FTBSTheme { FTBSTheme(colorScheme) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Contact Us")
                        .font(.title2.weight(.semibold))

                    Text("Get in touch with our team and board members.")
                        .foregroundStyle(theme.secondaryText)
                }

                contactPod(title: "Office Address") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Dr. JOHN BONKURI,")
                        Text("Director & Founder.")
                        Text("Institute of Bible Technology, Hyderabad & Temples of God Church Building")
                        Text("H.No:06 - 264 / 13 / 1 / 6H, HAL/Raghavendra Colony,")
                        Text("Suchitra X Road to Quthbullapur Road, Behind Indian Oil Petrol bunk,")
                        Text("Quthbullapur (GHMC), HYDERABAD - 500067, INDIA.")
                        Text("Mob: +91 9440142887.")
                        Text("www.bibletechnology.net")
                        Text("E-mail: john@bibletechnology.com, bibletechnology@gmail.com")
                    }
                            .foregroundStyle(theme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                }

                contactPod(title: "Board Member") {
                    boardMemberCard(
                        name: "John Bonkuri",
                        role: "Director",
                        location: "Located in India.",
                        imageAssetName: "john-bonkuri"
                    )
                }

                contactPod(title: "Board Member") {
                    boardMemberCard(
                        name: "Rajesh Sandya",
                        role: "Joint Director",
                        location: "Located in United States.",
                        imageAssetName: "rajesh-sandya"
                    )
                }
            }
            .padding()
            .frame(maxWidth: 900, alignment: .leading)
        }
        .navigationTitle("Contact Us")
    }

    private func contactPod<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            content()
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(theme.stroke, lineWidth: 1)
        }
    }

    private func boardMemberCard(name: String, role: String, location: String, imageAssetName: String) -> some View {
        HStack(alignment: .center, spacing: 14) {
            boardMemberPhoto(name: name, imageAssetName: imageAssetName)

            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.headline)
                Text(role)
                    .font(.subheadline.weight(.semibold))
                Text(location)
                    .foregroundStyle(theme.secondaryText)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func boardMemberPhoto(name: String, imageAssetName: String) -> some View {
        let image = platformImage(named: imageAssetName)

        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.muted)

            if let image {
                image
                    .resizable()
                    .scaledToFill()
                    .clipped()
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "person.crop.square")
                        .font(.system(size: 28, weight: .regular))
                    Text(initials(for: name))
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(theme.secondaryText)
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let last = parts.count > 1 ? parts.last?.first.map(String.init) ?? "" : ""
        return (first + last).uppercased()
    }

    private func platformImage(named name: String) -> Image? {
#if os(macOS)
        guard let nsImage = NSImage(named: name) else { return nil }
        return Image(nsImage: nsImage)
#elseif canImport(UIKit)
        guard let uiImage = UIImage(named: name) else { return nil }
        return Image(uiImage: uiImage)
#else
        return nil
#endif
    }
}

private struct SearchControls: View {
    @ObservedObject var viewModel: BibleViewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @FocusState private var isSearchFieldFocused: Bool

    private var theme: FTBSTheme { FTBSTheme(colorScheme) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isCompactLayout {
                compactSearchHeader
            } else {
                ViewThatFits(in: .vertical) {
                    HStack(spacing: 10) {
                        searchLabelAndField
                        scopePicker
                        actionButtons
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        searchLabelAndField
                        scopePicker
                        actionButtons
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        searchLabelAndField
                        HStack(spacing: 10) {
                            scopePicker
                            actionButtons
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(theme.muted, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onAppear {
            isSearchFieldFocused = true
        }
    }

    private var compactSearchHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Search at least 2 characters", text: $viewModel.searchQuery)
                .textFieldStyle(.plain)
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(theme.stroke.opacity(0.85), lineWidth: 1)
                }
                .focused($isSearchFieldFocused)
                .submitLabel(.search)
                .onChange(of: viewModel.searchQuery) { _, _ in
                    viewModel.performSearch()
                }
                .onSubmit {
                    viewModel.performSearch()
                }

            compactFilterBar

            Button {
                viewModel.performSearch()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.04, green: 0.04, blue: 0.06),
                            Color(red: 0.10, green: 0.10, blue: 0.12),
                            Color(red: 0.16, green: 0.16, blue: 0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 3)
    }

    private var compactFilterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Filter by scope")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.white.opacity(0.80))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SearchScope.allCases) { scope in
                        Button {
                            viewModel.searchScope = scope
                            viewModel.performSearch()
                        } label: {
                            Text(scope.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(viewModel.searchScope == scope ? .black : .white.opacity(0.88))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background {
                                    Capsule()
                                        .fill(viewModel.searchScope == scope ? Color.white : Color.white.opacity(0.10))
                                }
                                .overlay {
                                    Capsule()
                                        .stroke(viewModel.searchScope == scope ? Color.white.opacity(0.15) : Color.white.opacity(0.18), lineWidth: 1)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var searchLabelAndField: some View {
        HStack(alignment: .center, spacing: 10) {
            Text("Search")
                .font(.subheadline.weight(.semibold))

            searchField
        }
    }

    private var searchField: some View {
        TextField("Search at least 2 characters", text: $viewModel.searchQuery)
            .textFieldStyle(.roundedBorder)
            .padding(8)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .frame(maxWidth: .infinity)
            .layoutPriority(1)
            .focused($isSearchFieldFocused)
            .submitLabel(.search)
            .onChange(of: viewModel.searchQuery) { _, _ in
                viewModel.performSearch()
            }
            .onSubmit {
                viewModel.performSearch()
            }
    }

    private var scopePicker: some View {
        Picker("Scope", selection: $viewModel.searchScope) {
            ForEach(SearchScope.allCases) { scope in
                Text(scope.rawValue).tag(scope)
            }
        }
        .pickerStyle(.menu)
        .fixedSize()
        .onChange(of: viewModel.searchScope) { _, _ in
            viewModel.performSearch()
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            if viewModel.showingSearchResults || !viewModel.searchQuery.isEmpty {
                Button {
                    viewModel.clearSearch()
                } label: {
                    Image(systemName: "xmark.circle")
                }
                .buttonStyle(.bordered)
                .fixedSize()
                .accessibilityLabel("Clear")
            }

            if !isCompactLayout {
                Button {
                    viewModel.performSearch()
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(.borderedProminent)
                .fixedSize()
                .accessibilityLabel("Search")
            }
        }
    }

    private var isCompactLayout: Bool {
        horizontalSizeClass == .compact
    }
}

private struct SearchResultsView: View {
    @ObservedObject var viewModel: BibleViewModel
    let onSelectResult: ((BibleSearchResult) -> Void)?

    init(viewModel: BibleViewModel, onSelectResult: ((BibleSearchResult) -> Void)? = nil) {
        self.viewModel = viewModel
        self.onSelectResult = onSelectResult
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(resultSummary)
                .font(.headline)

            if viewModel.searchResults.isEmpty {
                ContentUnavailableView(
                    "No matches found",
                    systemImage: "magnifyingglass",
                    description: Text("Try a different word or search the entire Bible.")
                )
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.searchResults) { result in
                            Button {
                                if let onSelectResult {
                                    onSelectResult(result)
                                } else {
                                    viewModel.openSearchResult(result)
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(result.bookName) \(result.chapterNumber):\(result.verseNumber)")
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Spacer(minLength: 8)
                                    }

                                    Text(result.verseText)
                                        .font(.system(size: viewModel.fontSize))
                                        .foregroundStyle(.primary)
                                        .multilineTextAlignment(.leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var resultSummary: String {
        if viewModel.searchResults.isEmpty {
            return "Search Results"
        }
        return "Search Results (\(viewModel.searchResults.count))"
    }
}

private struct ChapterReaderView: View {
    @ObservedObject var viewModel: BibleViewModel

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 6) {
                    if let chapter = viewModel.selectedChapter {
                        ForEach(chapter.verses) { verse in
                            VerseRow(viewModel: viewModel, verse: verse)
                                .id(verse.vnumber)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .onChange(of: viewModel.highlightedVerseNumber) { _, verseNumber in
                guard let verseNumber else { return }
                Task { @MainActor in
                    await Task.yield()
                    withAnimation(.snappy(duration: 0.25)) {
                        proxy.scrollTo(verseNumber, anchor: .top)
                    }
                }
            }
        }
    }
}

private struct VerseRow: View {
    @ObservedObject var viewModel: BibleViewModel
    let verse: BibleVerse

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var showsCrossReferences = false
    @State private var showingAnnotationEditor = false
    @State private var annotationEditorColor: VerseHighlightColor?
    @State private var annotationEditorNote = ""

    private var theme: FTBSTheme { FTBSTheme(colorScheme) }

    var body: some View {
        let references = viewModel.crossReferences(for: verse.vnumber)
        let isHighlighted = viewModel.isHighlighted(verse.vnumber)
        let annotation = viewModel.annotation(for: verse.vnumber)
        let showsReferenceRangeBadge = isHighlighted && viewModel.selectedVerseNumbers.count > 1
        let isCompactLayout = horizontalSizeClass == .compact
        let verseTint = verseTintColor(for: verse.vnumber)
        let annotationFill = annotationBackgroundColor(for: annotation?.highlightColor)
        let annotationStroke = annotationBorderColor(for: annotation?.highlightColor)
        let indicatorWidth: CGFloat = isCompactLayout ? 4 : 5
        let trimmedAnnotationNote = annotation?.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let annotationNote = trimmedAnnotationNote?.isEmpty == false ? trimmedAnnotationNote : nil

        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: isCompactLayout ? 2 : 6) {
                Capsule()
                    .fill(isHighlighted ? verseTint : Color.clear)
                    .frame(width: indicatorWidth, height: 28)
                    .padding(.top, 2)

                if isCompactLayout {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(compactVerseText(isHighlighted: isHighlighted, verseTint: verseTint))
                            .font(.system(size: viewModel.fontSize))
                            .textSelection(.enabled)

                        if showsReferenceRangeBadge {
                            Text("Reference")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(theme.accent.opacity(0.14), in: Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(theme.accent.opacity(0.55), lineWidth: 1)
                                }
                                .accessibilityLabel("Reference verse")
                        }

                        if let parallelText = viewModel.parallelText(for: verse.vnumber) {
                            Text(parallelText)
                                .font(.system(size: max(viewModel.fontSize - 2, 12)))
                                .foregroundStyle(theme.secondaryText)
                                .textSelection(.enabled)
                        }

                        if let annotationNote {
                            annotationNoteBadge(text: annotationNote)
                        }
                    }
                } else {
                    Text("\(verse.vnumber)")
                        .font(.headline.monospacedDigit().weight(isHighlighted ? .bold : .regular))
                        .foregroundStyle(verseTint)
                        .frame(minWidth: 28, alignment: .leading)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(verse.displayText)
                            .font(.system(size: viewModel.fontSize))
                            .foregroundStyle(verseTint)
                            .textSelection(.enabled)

                        if showsReferenceRangeBadge {
                            Text("Reference")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(theme.accent.opacity(0.14), in: Capsule())
                                .overlay {
                                    Capsule()
                                        .stroke(theme.accent.opacity(0.55), lineWidth: 1)
                                }
                                .accessibilityLabel("Reference verse")
                        }

                        if let parallelText = viewModel.parallelText(for: verse.vnumber) {
                            Text(parallelText)
                                .font(.system(size: max(viewModel.fontSize - 2, 12)))
                                .foregroundStyle(theme.secondaryText)
                                .textSelection(.enabled)
                        }

                        if let annotationNote {
                            annotationNoteBadge(text: annotationNote)
                        }
                    }
                }

                Spacer(minLength: 2)

                annotationActionButton(annotation: annotation)
            }

            if !verse.resolvedFootnotes.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Label("Footnotes", systemImage: "info.circle")
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(verse.resolvedFootnotes.enumerated()), id: \.offset) { index, note in
                        Text("\(index + 1). \(note)")
                            .font(.subheadline)
                            .foregroundStyle(theme.secondaryText)
                            .textSelection(.enabled)
                    }
                }
                .padding(.leading, 30)
            }

            if let comment = verse.resolvedComment {
                VStack(alignment: .leading, spacing: 3) {
                    Label("Comment", systemImage: "text.bubble")
                        .font(.subheadline.weight(.semibold))
                    Text(comment)
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)
                        .textSelection(.enabled)
                }
                .padding(.leading, 30)
            }

            if !references.isEmpty {
                DisclosureGroup(isExpanded: $showsCrossReferences) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(references) { reference in
                            VStack(alignment: .leading, spacing: 4) {
                                Button(reference.label) {
                                    viewModel.openReference(reference)
                                }
                                .buttonStyle(.plain)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.tint)

                                if !reference.preview.isEmpty {
                                    Text(reference.preview)
                                        .font(.subheadline)
                                        .foregroundStyle(theme.secondaryText)
                                        .textSelection(.enabled)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(theme.muted.opacity(0.85), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                } label: {
                    Label("Cross References (\(references.count))", systemImage: "link")
                        .font(.subheadline.weight(.semibold))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 30)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            isHighlighted ? verseTint.opacity(0.16) : annotationFill ?? theme.surface,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .shadow(color: isHighlighted ? verseTint.opacity(0.12) : .clear, radius: isHighlighted ? 4 : 0, x: 0, y: 1)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isHighlighted ? verseTint : annotationStroke, lineWidth: isHighlighted ? 2.25 : (annotation != nil ? 1.75 : 1.5))
        }
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contextMenu {
            Menu("Highlight Color") {
                Button {
                    viewModel.setHighlightColor(nil, for: verse.vnumber)
                } label: {
                    Label("None", systemImage: annotation?.highlightColor == nil ? "checkmark" : "circle")
                }

                ForEach(VerseHighlightColor.allCases) { color in
                    Button {
                        viewModel.setHighlightColor(color, for: verse.vnumber)
                    } label: {
                        Label(color.displayName, systemImage: annotation?.highlightColor == color ? "checkmark" : "circle.fill")
                    }
                }
            }

            Button {
                openAnnotationEditor(existingAnnotation: annotation)
            } label: {
                Label(annotation?.note == nil ? "Add Note" : "Edit Note", systemImage: "note.text")
            }

            if annotation != nil {
                Button(role: .destructive) {
                    viewModel.clearAnnotation(for: verse.vnumber)
                } label: {
                    Label("Clear Annotation", systemImage: "trash")
                }
            }
        }
        .modifier(
            VerseAnnotationEditorPresenter(
                isPresented: $showingAnnotationEditor,
                prefersFullScreen: horizontalSizeClass == .regular,
                editor: {
                    VerseAnnotationEditor(
                        verseLabel: "\(viewModel.selectedBook?.bname ?? "Bible") \(viewModel.selectedChapterNumber):\(verse.vnumber)",
                        highlightColor: $annotationEditorColor,
                        noteText: $annotationEditorNote,
                        onSave: {
                            viewModel.setHighlightColor(annotationEditorColor, for: verse.vnumber)
                            viewModel.setNote(annotationEditorNote, for: verse.vnumber)
                        },
                        onClear: {
                            viewModel.clearAnnotation(for: verse.vnumber)
                        }
                    )
                }
            )
        )
        .onTapGesture {
            viewModel.selectVerse(verse.vnumber)
        }
    }

    private func compactVerseText(isHighlighted: Bool, verseTint: Color) -> AttributedString {
        var text = AttributedString("\(verse.vnumber). \(verse.displayText)")
        text.foregroundColor = verseTint
        if let range = text.range(of: "\(verse.vnumber).") {
            text[range].font = .system(size: viewModel.fontSize, weight: .regular)
        }
        return text
    }

    private func annotationNoteBadge(text: String) -> some View {
        Label {
            Text(text)
                .font(.caption)
                .lineLimit(2)
        } icon: {
            Image(systemName: "note.text")
                .font(.caption2)
        }
        .font(.caption2.weight(.medium))
        .foregroundStyle(theme.secondaryText)
        .padding(.horizontal, 7)
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func annotationActionButton(annotation: VerseAnnotation?) -> some View {
        Button {
            openAnnotationEditor(existingAnnotation: annotation)
        } label: {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.secondary.opacity(0.10))

                Image(systemName: annotationButtonSymbolName(annotation))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(annotationButtonColor(for: annotation?.highlightColor))

                Circle()
                    .fill(annotationButtonColor(for: annotation?.highlightColor))
                    .frame(width: 5, height: 5)
                    .offset(x: 2, y: -2)
                    .opacity(annotation == nil ? 0.55 : 1)
            }
            .frame(width: 22, height: 22)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(annotationButtonColor(for: annotation?.highlightColor).opacity(annotation == nil ? 0.20 : 0.32), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(annotation == nil ? "Add annotation" : "Edit annotation")
        .accessibilityHint("Add a highlight color or note for this verse")
    }

    private func openAnnotationEditor(existingAnnotation: VerseAnnotation?) {
        annotationEditorColor = existingAnnotation?.highlightColor
        annotationEditorNote = existingAnnotation?.note ?? ""
        showingAnnotationEditor = true
    }

    private func annotationBackgroundColor(for highlightColor: VerseHighlightColor?) -> Color? {
        guard let highlightColor else { return nil }
        return verseHighlightSwatch(for: highlightColor, colorScheme: colorScheme).opacity(colorScheme == .dark ? 0.30 : 0.18)
    }

    private func annotationBorderColor(for highlightColor: VerseHighlightColor?) -> Color {
        guard let highlightColor else { return Color.clear }
        return verseHighlightSwatch(for: highlightColor, colorScheme: colorScheme).opacity(colorScheme == .dark ? 0.60 : 0.45)
    }

    private func annotationButtonColor(for highlightColor: VerseHighlightColor?) -> Color {
        guard let highlightColor else { return theme.secondaryText.opacity(0.7) }
        return verseHighlightSwatch(for: highlightColor, colorScheme: colorScheme)
    }

    private func annotationButtonSymbolName(_ annotation: VerseAnnotation?) -> String {
        if annotation?.note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            return "note.text"
        }

        if annotation?.highlightColor != nil {
            return "highlighter"
        }

        return "highlighter"
    }

    private func verseTintColor(for verseNumber: Int) -> Color {
        if colorScheme == .dark {
            return .white
        }

        return .black
    }
}

private struct VerseAnnotationEditorPresenter: ViewModifier {
    @Binding var isPresented: Bool
    let prefersFullScreen: Bool
    let editor: () -> VerseAnnotationEditor

    func body(content: Content) -> some View {
        #if os(macOS)
        content.sheet(isPresented: $isPresented) {
            editor()
        }
        #else
        if prefersFullScreen {
            content.fullScreenCover(isPresented: $isPresented) {
                editor()
            }
        } else {
            content.sheet(isPresented: $isPresented) {
                editor()
            }
        }
        #endif
    }
}

private struct VerseAnnotationEditor: View {
    let verseLabel: String
    @Binding var highlightColor: VerseHighlightColor?
    @Binding var noteText: String
    let onSave: () -> Void
    let onClear: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let colorChoices: [VerseHighlightColor?] = [nil] + VerseHighlightColor.allCases.map(Optional.some)

    private var editorPadding: CGFloat {
#if os(macOS)
        20
#else
        14
#endif
    }

    private var noteEditorMinHeight: CGFloat {
        horizontalSizeClass == .regular ? 360 : 180
    }

    var body: some View {
        NavigationStack {
            editorContent
            .navigationTitle("Verse Note")
            #if os(macOS)
            .frame(minWidth: 560, idealWidth: 640, minHeight: 560, idealHeight: 680)
            #elseif canImport(UIKit)
            .frame(minHeight: horizontalSizeClass == .regular ? 740 : 560)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave()
                        dismiss()
                    }
                }
            }
        }
    }

    #if os(macOS)
    @ViewBuilder
    private var editorContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                editorSections
            }
            .frame(maxWidth: 620, alignment: .leading)
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(NSColor.windowBackgroundColor))
    }
    #else
    @ViewBuilder
    private var editorContent: some View {
        Form {
            editorSections
        }
        .padding(.horizontal, editorPadding)
        .padding(.vertical, 8)
    }
    #endif

    @ViewBuilder
    private var editorSections: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Verse")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(verseLabel)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }

        VStack(alignment: .leading, spacing: 12) {
            Text("Highlight Color")
                .font(.headline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 10)], spacing: 10) {
                ForEach(colorChoices, id: \.self) { color in
                    Button {
                        highlightColor = color
                    } label: {
                        ZStack(alignment: .topTrailing) {
                            Circle()
                                .fill(color.map { verseHighlightSwatch(for: $0, colorScheme: colorScheme) } ?? Color.secondary.opacity(0.20))
                                .frame(width: 18, height: 18)

                            if highlightColor == color {
                                Image(systemName: "checkmark")
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(.primary)
                                    .offset(x: 6, y: -6)
                            }
                        }
                        .frame(width: 44, height: 44)
                        .background(highlightColor == color ? Color.accentColor.opacity(0.14) : Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(highlightColor == color ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(color?.displayName ?? "None")
                }
            }
        }

        VStack(alignment: .leading, spacing: 10) {
            Text("Note")
                .font(.headline)
                .foregroundStyle(.secondary)

            TextEditor(text: $noteText)
                .frame(minHeight: noteEditorMinHeight)
                .padding(12)
                .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            if noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Write a note to save with this verse.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }

        if highlightColor != nil || !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Button(role: .destructive) {
                onClear()
                dismiss()
            } label: {
                Label("Clear Annotation", systemImage: "trash")
            }
        }
    }
}

private func verseHighlightSwatch(for color: VerseHighlightColor, colorScheme: ColorScheme) -> Color {
    let opacity: Double = colorScheme == .dark ? 0.35 : 0.28

    switch color {
    case .yellow:
        return Color.yellow.opacity(opacity)
    case .green:
        return Color.green.opacity(opacity)
    case .blue:
        return Color.blue.opacity(opacity)
    case .pink:
        return Color.pink.opacity(opacity)
    case .orange:
        return Color.orange.opacity(opacity)
    case .purple:
        return Color.purple.opacity(opacity)
    case .red:
        return Color.red.opacity(opacity)
    case .gray:
        return Color.gray.opacity(opacity)
    }
}

private struct FTBSTheme {
    let background: Color
    let warmBackground: Color
    let surface: Color
    let muted: Color
    let stroke: Color
    let accent: Color
    let secondaryText: Color

    init(_ colorScheme: ColorScheme) {
        switch colorScheme {
        case .dark:
            background = .black
            warmBackground = Color(red: 0.06, green: 0.06, blue: 0.06)
            surface = Color(red: 0.10, green: 0.10, blue: 0.10)
            muted = Color(red: 0.14, green: 0.14, blue: 0.14)
            stroke = Color(red: 0.32, green: 0.32, blue: 0.32)
            accent = .white
            secondaryText = Color.white.opacity(0.82)
        default:
            background = .white
            warmBackground = Color(red: 0.975, green: 0.975, blue: 0.975)
            surface = .white
            muted = Color(red: 0.94, green: 0.94, blue: 0.94)
            stroke = Color(red: 0.80, green: 0.80, blue: 0.80)
            accent = .black
            secondaryText = Color.black.opacity(0.78)
        }
    }
}

#Preview("iPhone") {
    ContentView()
}

#Preview("iPad") {
    ContentView()
}

#Preview("Mac") {
    ContentView()
}

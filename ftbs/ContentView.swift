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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @StateObject private var viewModel = BibleViewModel()
    @State private var currentScreen: AppScreen = .home

    var body: some View {
        Group {
            if currentScreen == .home {
                HomePageView(
                    viewModel: viewModel,
                    onEnterBible: { currentScreen = .bible },
                    onHome: { currentScreen = .home }
                )
            } else if horizontalSizeClass == .compact {
                BibleCompactRoot(viewModel: viewModel, onHome: { currentScreen = .home })
            } else {
                BibleSplitRoot(viewModel: viewModel, onHome: { currentScreen = .home })
            }
        }
        .tint(.ivoryAccent)
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

private struct BibleSplitRoot: View {
    @ObservedObject var viewModel: BibleViewModel
    let onHome: () -> Void

    var body: some View {
        NavigationSplitView {
            BibleSidebar(viewModel: viewModel)
        } detail: {
            BibleReaderDetail(viewModel: viewModel, onHome: onHome)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

private struct BibleCompactRoot: View {
    @ObservedObject var viewModel: BibleViewModel
    let onHome: () -> Void
    @State private var showingReader = false

    var body: some View {
        NavigationStack {
            BibleCompactSidebar(
                viewModel: viewModel,
                onSelectBook: { book in
                    viewModel.selectBook(book)
                    showingReader = true
                }
            )
            .navigationDestination(isPresented: $showingReader) {
                BibleReaderDetail(viewModel: viewModel, onHome: onHome)
            }
        }
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
                        ReaderHeader(viewModel: viewModel, onHome: onHome) {
                            showingAboutUs = true
                        } onContactUs: {
                            showingContactUs = true
                        }
                        SearchControls(viewModel: viewModel)

                        if viewModel.showingSearchResults {
                            SearchResultsView(viewModel: viewModel)
                        } else {
                            ChapterReaderView(viewModel: viewModel)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Full Truth Bible Society")
            .navigationDestination(isPresented: $showingAboutUs) {
                AboutUsPage()
            }
            .navigationDestination(isPresented: $showingContactUs) {
                ContactUsPage()
            }
        }
    }
}

private struct ReaderHeader: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var viewModel: BibleViewModel
    let onHome: () -> Void
    let onAboutUs: () -> Void
    let onContactUs: () -> Void
    @State private var activePopover: AppPopover?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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

            HStack(spacing: 12) {
                Button {
                    viewModel.showPreviousChapter()
                } label: {
                    Label("Previous", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)

                Menu {
                    if let selectedBook = viewModel.selectedBook {
                        ForEach(selectedBook.chapters) { chapter in
                            Button("Chapter \(chapter.cnumber)") {
                                viewModel.selectChapter(chapter.cnumber)
                            }
                        }
                    }
                } label: {
                    Label("Chapter \(viewModel.selectedChapterNumber)", systemImage: "list.number")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    viewModel.showNextChapter()
                } label: {
                    Label("Next", systemImage: "chevron.right")
                }
                .buttonStyle(.bordered)

                Spacer(minLength: 0)
            }

#if !os(macOS)
            if viewModel.selectedVerseCount > 0, let selectedVersesText = viewModel.selectedVersesText() {
                HStack(spacing: 12) {
                    Text("\(viewModel.selectedVerseCount) selected")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 0)

                    Button {
                        copyToClipboard(selectedVersesText)
                    } label: {
                        Label("Copy Selected", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    ShareLink(item: selectedVersesText) {
                        Label("Share Selected", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
#endif
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
                            .navigationTitle("Settings")
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { activePopover = nil }
                    }
                }
            }
            .frame(minWidth: 320, idealWidth: 360, minHeight: 360, idealHeight: 420)
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

    private var titleFont: Font {
        horizontalSizeClass == .compact ? .title2.weight(.semibold) : .largeTitle.weight(.semibold)
    }

    private var headerTitle: String {
        let bookName = viewModel.selectedBook?.bname ?? "Bible"
        return "\(bookName) \(viewModel.selectedChapterNumber)"
    }
}

private enum AppPopover: String, Identifiable {
    case settings

    var id: String { rawValue }
}

private struct SettingsPanel: View {
    @ObservedObject var viewModel: BibleViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Reading Settings")
                    .font(.headline)
                Text("Adjust language, parallel text, and font size.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            settingsRow(title: "Language") {
                Picker("Language", selection: languageBinding) {
                    ForEach(BibleLanguage.allCases) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(.menu)
            }

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
        .padding(16)
        .frame(maxWidth: 360, alignment: .leading)
    }

    private func settingsRow<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
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
}

private struct HomePageView: View {
    @ObservedObject var viewModel: BibleViewModel
    let onEnterBible: () -> Void
    let onHome: () -> Void
    @State private var showingAboutUs = false
    @State private var showingContactUs = false
    @State private var activePopover: AppPopover?

    private let appStoreURL = URL(string: "https://apps.apple.com/us/genre/ios/id36")!

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

                    Button {
                        onEnterBible()
                    } label: {
                        Label("Open Bible", systemImage: "book.closed")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: 280)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(
                LinearGradient(
                    colors: [Color.ivoryBackground, Color.ivoryWarmBackground],
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
                                .navigationTitle("Settings")
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Done") { activePopover = nil }
                        }
                    }
                }
                .frame(minWidth: 320, idealWidth: 360, minHeight: 360, idealHeight: 420)
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
                .foregroundStyle(.secondary)

            Text("A Bible reading and ministry companion designed to help you study, search, compare, and share the Word of God.")
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ivorySurface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.ivoryStroke, lineWidth: 1)
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
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ivoryMuted, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func infoCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            Text(body)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.ivorySurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.ivoryStroke, lineWidth: 1)
        }
    }

    private var homeActions: some View {
        HStack(spacing: 8) {
            Link(destination: appStoreURL) {
                appStoreIcon
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityLabel("App Store")

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

    @ViewBuilder
    private var appStoreIcon: some View {
#if os(macOS)
        if let nsImage = NSImage(named: "ftbs-logo") {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        } else {
            FTBSAppStoreBadge()
                .frame(width: 18, height: 18)
        }
#elseif canImport(UIKit)
        if let uiImage = UIImage(named: "ftbs-logo") {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        } else {
            FTBSAppStoreBadge()
                .frame(width: 18, height: 18)
        }
#else
        FTBSAppStoreBadge()
            .frame(width: 18, height: 18)
#endif
    }
}

private struct FTBSAppStoreBadge: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color(red: 0.96, green: 0.97, blue: 0.99)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    Circle()
                        .stroke(Color(red: 0.17, green: 0.22, blue: 0.62), lineWidth: 0.8)
                }

            VStack(spacing: 0) {
                Text("FTBS")
                    .font(.system(size: 3.1, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.16, green: 0.16, blue: 0.55))
                    .padding(.top, 1)

                Image(systemName: "tree.fill")
                    .font(.system(size: 4.5, weight: .semibold))
                    .foregroundStyle(Color.green)
                    .padding(.top, 0.3)

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 4.2, weight: .semibold))
                    .foregroundStyle(Color.red)
                    .padding(.top, -0.3)

                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.55, green: 0.0, blue: 0.05), Color(red: 0.76, green: 0.0, blue: 0.08)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 9, height: 2.1)
                    .padding(.top, 0.3)

                Text("FTBS")
                    .font(.system(size: 2.4, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(red: 0.15, green: 0.15, blue: 0.45))
                    .padding(.top, 0.1)
            }
            .minimumScaleFactor(0.5)
            .lineLimit(1)
        }
    }
}

private struct AboutUsPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("OUR EFFORTS TO GUIDE EVERYONE TO THE KINGDOM OF CHRIST")
                        .font(.title2.weight(.semibold))

                    Text("Round the clock and across the globe, to save the mankind, we preach the crucified Christ alone (focusing on the message of Jesus Christ after being crucified. We reach people right from country side to the most modern of communities. We strive to lessen religious conflicts by educating people in the way of God and enhance moral values, humanity and divinity in the hearts of the people. We answer the questions raised on Bible by Muslims, Hindus, Atheists and others. We conduct Spiritual camps spreading the need to control anti social activities. We take the help of Electronic and Print media to broadcast the necessity of education irrespective of Gender, Age, Caste, Creed, Sect, and Region etc. We conduct regular Bible Research Seminars throughout the year clarifying controversial doctrines/claims prevailing amongst the divided sects or denominations of Christianity. Since the inauguration of the Institute premises (on 15 th August, 2002) we have conducted 59 Seminars from the word of God (including a seminar on ALIENS / UFOs held on 17 th December 2010 and a seminar on 7 year trials, when and where is the 3 and ½ year food festival held on 15 th July 2012) on Biblical, Social, Historical, Scientific – Engineering & Medical and Law related topics. For further details on our Seminars and other works, please visit the Books CDs and Messages page. We train people as full-fledged Bible Technicians / Evangelists / Pastors to preach or teach the Gospel of Christ, to answer question(s) challenging our professed faith and to clear the doubts of anyone from any part of the world without charging any fee for our services.")
                        .font(.body)
                        .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }
}

private struct ContactUsPage: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Contact Us")
                        .font(.title2.weight(.semibold))

                    Text("Get in touch with our team and board members.")
                        .foregroundStyle(.secondary)
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
                    .foregroundStyle(.secondary)
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
        .background(Color.ivorySurface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.ivoryStroke, lineWidth: 1)
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
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func boardMemberPhoto(name: String, imageAssetName: String) -> some View {
        let image = platformImage(named: imageAssetName)

        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.ivoryMuted)

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
                .foregroundStyle(.secondary)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search")
                .font(.headline)

            ViewThatFits(in: .vertical) {
                HStack(spacing: 12) {
                    searchField
                    scopePicker
                    actionButtons
                }

                VStack(alignment: .leading, spacing: 10) {
                    searchField
                    scopePicker
                    actionButtons
                }

                VStack(alignment: .leading, spacing: 10) {
                    searchField
                    HStack(spacing: 12) {
                        scopePicker
                        actionButtons
                    }
                }
            }
        }
        .padding()
        .background(Color.ivoryMuted, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var searchField: some View {
        TextField("Search at least 3 characters", text: $viewModel.searchQuery)
            .textFieldStyle(.roundedBorder)
            .padding(8)
            .background(Color.ivorySurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .frame(maxWidth: .infinity)
            .layoutPriority(1)
            .submitLabel(.search)
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
    }

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button("Search") {
                viewModel.performSearch()
            }
            .buttonStyle(.borderedProminent)
            .fixedSize()

            if viewModel.showingSearchResults || !viewModel.searchQuery.isEmpty {
                Button("Clear") {
                    viewModel.clearSearch()
                }
                .buttonStyle(.bordered)
                .fixedSize()
            }
        }
    }

    @ViewBuilder
    private var appStoreIcon: some View {
#if os(macOS)
        if let nsImage = NSImage(named: "ftbs-logo") {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        } else {
            Image(systemName: "apple.logo")
        }
#elseif canImport(UIKit)
        if let uiImage = UIImage(named: "ftbs-logo") {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
        } else {
            Image(systemName: "apple.logo")
        }
#else
        Image(systemName: "apple.logo")
#endif
    }
}

private struct SearchResultsView: View {
    @ObservedObject var viewModel: BibleViewModel

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
                                viewModel.openSearchResult(result)
                            } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(result.bookName) \(result.chapterNumber):\(result.verseNumber)")
                                            .font(.headline)
                                            .foregroundStyle(.primary)

                                        Spacer(minLength: 8)

#if !os(macOS)
                                        Button {
                                            copyToClipboard(copyText(for: result))
                                        } label: {
                                            Label("Copy", systemImage: "doc.on.doc")
                                                .labelStyle(.iconOnly)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                        .accessibilityLabel("Copy verse")

                                        ShareLink(item: copyText(for: result)) {
                                            Label("Share", systemImage: "square.and.arrow.up")
                                                .labelStyle(.iconOnly)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                        .accessibilityLabel("Share verse")
#endif
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

    @State private var showsCrossReferences = false

    var body: some View {
        let references = viewModel.crossReferences(for: verse.vnumber)
        let isSelected = viewModel.isSelectedVerse(verse.vnumber)
        let isHighlighted = viewModel.isHighlighted(verse.vnumber)
        let showsReferenceRangeBadge = isHighlighted && viewModel.selectedVerseNumbers.count > 1

        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 6) {
                if isHighlighted {
                    Capsule()
                        .fill(Color.ivoryAccent)
                        .frame(width: 5, height: 28)
                        .padding(.top, 2)
                }

                Text("\(verse.vnumber)")
                    .font(.headline.monospacedDigit().weight(isHighlighted ? .bold : .regular))
                    .foregroundStyle(isHighlighted ? Color.ivoryAccent : Color.accentColor)
                    .frame(minWidth: 28, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text(verse.displayText)
                        .font(.system(size: viewModel.fontSize))
                        .textSelection(.enabled)

                    if showsReferenceRangeBadge {
                        Text("Reference")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.ivoryAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.ivoryAccent.opacity(0.12), in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(Color.ivoryAccent.opacity(0.5), lineWidth: 1)
                            }
                            .accessibilityLabel("Reference verse")
                    }

                    if let parallelText = viewModel.parallelText(for: verse.vnumber) {
                        Text(parallelText)
                            .font(.system(size: max(viewModel.fontSize - 2, 12)))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }

                Spacer(minLength: 2)

#if !os(macOS)
                Button {
                    copyToClipboard(copyText)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Copy verse")

                ShareLink(item: viewModel.verseText(for: verse.vnumber)) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Share verse")

                Button {
                    viewModel.selectVerse(verse.vnumber)
                } label: {
                    Label(isSelected ? "Deselect" : "Select", systemImage: isSelected ? "checkmark.circle.fill" : "checkmark.circle")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel(isSelected ? "Deselect verse" : "Select verse")
#endif
            }

            if !verse.resolvedFootnotes.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    Label("Footnotes", systemImage: "info.circle")
                        .font(.subheadline.weight(.semibold))
                    ForEach(Array(verse.resolvedFootnotes.enumerated()), id: \.offset) { index, note in
                        Text("\(index + 1). \(note)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
                        .foregroundStyle(.secondary)
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
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                            .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    .padding(.top, 4)
                } label: {
                    Label("Cross References (\(references.count))", systemImage: "link")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.leading, 30)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            isHighlighted
            ? Color.ivoryHighlight.opacity(0.98)
            : Color.ivorySurface,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .shadow(color: isHighlighted ? Color.ivoryAccent.opacity(0.10) : .clear, radius: isHighlighted ? 4 : 0, x: 0, y: 1)
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isHighlighted ? Color.ivoryAccent : Color.clear, lineWidth: isHighlighted ? 2.25 : 1.5)
        }
    }

    private var copyText: String {
        let bookName = viewModel.selectedBook?.bname ?? "Bible"
        return "\(bookName) \(viewModel.selectedChapterNumber):\(verse.vnumber) \(verse.displayText)"
    }
}

private func copyToClipboard(_ text: String) {
#if os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
#elseif canImport(UIKit)
    UIPasteboard.general.string = text
#endif
}

private func copyText(for result: BibleSearchResult) -> String {
    "\(result.bookName) \(result.chapterNumber):\(result.verseNumber) \(result.verseText)"
}

private extension Color {
    static let ivoryBackground = Color(red: 0.988, green: 0.981, blue: 0.968)
    static let ivoryWarmBackground = Color(red: 0.967, green: 0.958, blue: 0.944)
    static let ivorySurface = Color(red: 0.997, green: 0.995, blue: 0.989)
    static let ivoryMuted = Color(red: 0.952, green: 0.947, blue: 0.936)
    static let ivoryHighlight = Color(red: 0.975, green: 0.970, blue: 0.958)
    static let ivoryStroke = Color(red: 0.806, green: 0.794, blue: 0.776)
    static let ivoryAccent = Color(red: 0.258, green: 0.301, blue: 0.338)
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

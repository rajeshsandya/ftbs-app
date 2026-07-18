import Combine
import Foundation

@MainActor
final class BibleViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedLanguage: BibleLanguage
    @Published var defaultLanguage: BibleLanguage
    @Published var selectedBookNumber: Int = 1
    @Published var selectedChapterNumber: Int = 1
    @Published var searchQuery = ""
    @Published var searchScope: SearchScope = .currentBook
    @Published var searchResults: [BibleSearchResult] = []
    @Published var showingSearchResults = false
    @Published var fontSize: Double = 17
    @Published var showParallelText = false
    @Published var selectedParallelLanguage: BibleLanguage = .english
    @Published var highlightedVerseNumber: Int?
    @Published var selectedVerseNumbers: Set<Int> = []
    @Published private(set) var verseAnnotations: [String: VerseAnnotation] = [:]

    private var didLoad = false
    private var bibles: [BibleLanguage: BibleDocument] = [:]
    private var verseLookup: [BibleLanguage: [String: BibleVerse]] = [:]
    private var bookNameLookup: [BibleLanguage: [Int: String]] = [:]
    private var crossReferences: [String: [String]] = [:]
    private var backHistory: [NavigationLocation] = []
    private var forwardHistory: [NavigationLocation] = []

    init() {
        let storedDefaultLanguage = Self.loadDefaultLanguage()
        selectedLanguage = storedDefaultLanguage
        defaultLanguage = storedDefaultLanguage
        verseAnnotations = Self.loadVerseAnnotations()
    }

    var books: [BibleBook] {
        bibles[selectedLanguage]?.books ?? []
    }

    var oldTestamentBooks: [BibleBook] {
        books.filter { $0.testament == .old }
    }

    var newTestamentBooks: [BibleBook] {
        books.filter { $0.testament == .new }
    }

    var selectedBook: BibleBook? {
        books.first(where: { $0.bnumber == selectedBookNumber }) ?? books.first
    }

    var selectedChapter: BibleChapter? {
        selectedBook?.chapters.first(where: { $0.cnumber == selectedChapterNumber }) ?? selectedBook?.chapters.first
    }

    var currentTitle: String {
        guard let selectedBook, let selectedChapter else {
            return "FTBS Bible"
        }
        return "\(selectedBook.bname) \(selectedChapter.cnumber)"
    }

    var availableParallelLanguages: [BibleLanguage] {
        BibleLanguage.allCases.filter { $0 != selectedLanguage && bibles[$0] != nil }
    }

    var parallelLanguage: BibleLanguage {
        if availableParallelLanguages.contains(selectedParallelLanguage) {
            return selectedParallelLanguage
        }

        return availableParallelLanguages.first ?? selectedLanguage
    }

    var canGoBack: Bool {
        !backHistory.isEmpty
    }

    var canGoForward: Bool {
        !forwardHistory.isEmpty
    }

    func loadIfNeeded() async {
        guard !didLoad else { return }

        isLoading = true
        errorMessage = nil

        do {
            async let referenceMap = Self.loadCrossReferences()
            let loadedBibles = try await Self.loadAllBibles()
            let loadedCrossReferences = try await referenceMap

            bibles = loadedBibles
            crossReferences = loadedCrossReferences

            verseLookup = Dictionary(uniqueKeysWithValues: loadedBibles.map { language, document in
                (language, Self.makeVerseLookup(for: document))
            })
            bookNameLookup = Dictionary(uniqueKeysWithValues: loadedBibles.map { language, document in
                (language, Self.makeBookNameLookup(for: document))
            })

            didLoad = true
            updateParallelLanguageSelection()

            if let firstBook = bibles[selectedLanguage]?.books.first,
               let firstChapter = firstBook.chapters.first {
                selectedBookNumber = firstBook.bnumber
                selectedChapterNumber = firstChapter.cnumber
                clearNavigationHistory()
            }
        } catch {
            errorMessage = "Unable to load the Bible data. \(error.localizedDescription)"
        }

        isLoading = false
    }

    func selectLanguage(_ language: BibleLanguage) {
        guard selectedLanguage != language else { return }
        selectedLanguage = language
        updateParallelLanguageSelection()
        showingSearchResults = false
        searchResults = []
        clearNavigationHistory()
        clearVerseSelections()
        ensureValidSelection()
    }

    func selectDefaultLanguage(_ language: BibleLanguage) {
        guard defaultLanguage != language else { return }
        defaultLanguage = language
        Self.saveDefaultLanguage(language)
    }

    func selectParallelLanguage(_ language: BibleLanguage) {
        guard language != selectedLanguage, availableParallelLanguages.contains(language) else { return }
        selectedParallelLanguage = language
    }

    func selectBook(_ book: BibleBook, chapterNumber: Int? = nil) {
        let resolvedChapterNumber = chapterNumber ?? book.chapters.first?.cnumber ?? 1
        navigate(
            to: NavigationLocation(
                language: selectedLanguage,
                bookNumber: book.bnumber,
                chapterNumber: resolvedChapterNumber,
                verseNumber: nil,
                selectedVerseNumbers: [],
                highlightedVerseNumber: nil,
                showingSearchResults: false,
                searchQuery: searchQuery,
                searchScope: searchScope
            ),
            recordHistory: true
        )
    }

    func selectChapter(_ chapterNumber: Int) {
        guard selectedBook?.chapters.contains(where: { $0.cnumber == chapterNumber }) == true else { return }
        navigate(
            to: NavigationLocation(
                language: selectedLanguage,
                bookNumber: selectedBookNumber,
                chapterNumber: chapterNumber,
                verseNumber: nil,
                selectedVerseNumbers: [],
                highlightedVerseNumber: nil,
                showingSearchResults: false,
                searchQuery: searchQuery,
                searchScope: searchScope
            ),
            recordHistory: true
        )
    }

    func showPreviousChapter() {
        guard let book = selectedBook, let chapter = selectedChapter else { return }

        if let previousChapter = book.chapters.last(where: { $0.cnumber < chapter.cnumber }) {
            navigate(
                to: NavigationLocation(
                    language: selectedLanguage,
                    bookNumber: book.bnumber,
                    chapterNumber: previousChapter.cnumber,
                    verseNumber: nil,
                    selectedVerseNumbers: [],
                    highlightedVerseNumber: nil,
                    showingSearchResults: false,
                    searchQuery: searchQuery,
                    searchScope: searchScope
                ),
                recordHistory: true
            )
        } else if let previousBook = books.last(where: { $0.bnumber < book.bnumber }),
                  let lastChapter = previousBook.chapters.last {
            navigate(
                to: NavigationLocation(
                    language: selectedLanguage,
                    bookNumber: previousBook.bnumber,
                    chapterNumber: lastChapter.cnumber,
                    verseNumber: nil,
                    selectedVerseNumbers: [],
                    highlightedVerseNumber: nil,
                    showingSearchResults: false,
                    searchQuery: searchQuery,
                    searchScope: searchScope
                ),
                recordHistory: true
            )
        }
    }

    func showNextChapter() {
        guard let book = selectedBook, let chapter = selectedChapter else { return }

        if let nextChapter = book.chapters.first(where: { $0.cnumber > chapter.cnumber }) {
            navigate(
                to: NavigationLocation(
                    language: selectedLanguage,
                    bookNumber: book.bnumber,
                    chapterNumber: nextChapter.cnumber,
                    verseNumber: nil,
                    selectedVerseNumbers: [],
                    highlightedVerseNumber: nil,
                    showingSearchResults: false,
                    searchQuery: searchQuery,
                    searchScope: searchScope
                ),
                recordHistory: true
            )
        } else if let nextBook = books.first(where: { $0.bnumber > book.bnumber }),
                  let firstChapter = nextBook.chapters.first {
            navigate(
                to: NavigationLocation(
                    language: selectedLanguage,
                    bookNumber: nextBook.bnumber,
                    chapterNumber: firstChapter.cnumber,
                    verseNumber: nil,
                    selectedVerseNumbers: [],
                    highlightedVerseNumber: nil,
                    showingSearchResults: false,
                    searchQuery: searchQuery,
                    searchScope: searchScope
                ),
                recordHistory: true
            )
        }
    }

    func performSearch() {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidSearchQuery(trimmedQuery) else {
            searchResults = []
            showingSearchResults = false
            return
        }

        navigate(
            to: NavigationLocation(
                language: selectedLanguage,
                bookNumber: selectedBookNumber,
                chapterNumber: selectedChapterNumber,
                verseNumber: nil,
                selectedVerseNumbers: [],
                highlightedVerseNumber: nil,
                showingSearchResults: true,
                searchQuery: searchQuery,
                searchScope: searchScope
            ),
            recordHistory: true
        )
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
        showingSearchResults = false
        clearVerseSelections()
    }

    func openSearchResult(_ result: BibleSearchResult) {
        guard result.language == selectedLanguage else {
            selectLanguage(result.language)
            return openSearchResult(result)
        }

        navigate(
            to: NavigationLocation(
                language: selectedLanguage,
                bookNumber: result.bookNumber,
                chapterNumber: result.chapterNumber,
                verseNumber: result.verseNumber,
                selectedVerseNumbers: [result.verseNumber],
                highlightedVerseNumber: result.verseNumber,
                showingSearchResults: false,
                searchQuery: searchQuery,
                searchScope: searchScope
            ),
            recordHistory: true
        )
    }

    func parallelText(for verseNumber: Int) -> String? {
        guard showParallelText,
              let verse = verse(for: parallelLanguage, bookNumber: selectedBookNumber, chapterNumber: selectedChapterNumber, verseNumber: verseNumber)
        else {
            return nil
        }

        let text = verse.displayText
        return text.isEmpty ? nil : text
    }

    func crossReferences(for verseNumber: Int) -> [BibleReference] {
        let key = Self.verseKey(bookNumber: selectedBookNumber, chapterNumber: selectedChapterNumber, verseNumber: verseNumber)
        let references = crossReferences[key] ?? []

        return references.compactMap { reference in
            let parts = reference.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
            guard parts.count >= 3,
                  let bookNumber = Int(parts[0]),
                  let chapterNumber = Int(parts[1])
            else {
                return nil
            }

            let verseSpec = parts[2]
            let bookName = bookName(for: bookNumber, language: selectedLanguage)
            let label = "\(bookName) \(chapterNumber):\(verseSpec)"
            let preview = versePreview(bookNumber: bookNumber, chapterNumber: chapterNumber, verseSpec: verseSpec, language: selectedLanguage)
            return BibleReference(bookNumber: bookNumber, chapterNumber: chapterNumber, verseSpec: verseSpec, label: label, preview: preview)
        }
    }

    func openReference(_ reference: BibleReference) {
        let resolvedVerseNumbers = reference.verseNumbers.filter { verseNumber in
            verse(for: selectedLanguage, bookNumber: reference.bookNumber, chapterNumber: reference.chapterNumber, verseNumber: verseNumber) != nil
        }

        navigate(
            to: NavigationLocation(
                language: selectedLanguage,
                bookNumber: reference.bookNumber,
                chapterNumber: reference.chapterNumber,
                verseNumber: resolvedVerseNumbers.first,
                selectedVerseNumbers: Set(resolvedVerseNumbers),
                highlightedVerseNumber: resolvedVerseNumbers.first,
                showingSearchResults: false,
                searchQuery: searchQuery,
                searchScope: searchScope
            ),
            recordHistory: true
        )
    }

    func goBack() {
        guard let previous = backHistory.popLast() else { return }
        if let current = currentLocation {
            forwardHistory.append(current)
        }
        apply(location: previous)
    }

    func goForward() {
        guard let next = forwardHistory.popLast() else { return }
        if let current = currentLocation {
            backHistory.append(current)
        }
        apply(location: next)
    }

    func selectVerse(_ verseNumber: Int) {
        let updatedSelection: Set<Int>
        let updatedHighlightedVerseNumber: Int?

        if selectedVerseNumbers.contains(verseNumber) {
            updatedSelection = selectedVerseNumbers.subtracting([verseNumber])
            updatedHighlightedVerseNumber = updatedSelection.max()
        } else {
            updatedSelection = selectedVerseNumbers.union([verseNumber])
            updatedHighlightedVerseNumber = verseNumber
        }

        navigate(
            to: NavigationLocation(
                language: selectedLanguage,
                bookNumber: selectedBookNumber,
                chapterNumber: selectedChapterNumber,
                verseNumber: updatedHighlightedVerseNumber,
                selectedVerseNumbers: updatedSelection,
                highlightedVerseNumber: updatedHighlightedVerseNumber,
                showingSearchResults: showingSearchResults,
                searchQuery: searchQuery,
                searchScope: searchScope
            ),
            recordHistory: true
        )
    }

    func annotation(for verseNumber: Int) -> VerseAnnotation? {
        annotation(
            language: selectedLanguage,
            bookNumber: selectedBookNumber,
            chapterNumber: selectedChapterNumber,
            verseNumber: verseNumber
        )
    }

    func annotation(
        language: BibleLanguage,
        bookNumber: Int,
        chapterNumber: Int,
        verseNumber: Int
    ) -> VerseAnnotation? {
        verseAnnotations[Self.annotationKey(language: language, bookNumber: bookNumber, chapterNumber: chapterNumber, verseNumber: verseNumber)]
    }

    func highlightColor(for verseNumber: Int) -> VerseHighlightColor? {
        annotation(for: verseNumber)?.highlightColor
    }

    func note(for verseNumber: Int) -> String? {
        annotation(for: verseNumber)?.note
    }

    func setHighlightColor(_ color: VerseHighlightColor?, for verseNumber: Int) {
        updateAnnotation(for: verseNumber) { annotation in
            annotation.highlightColor = color
        }
    }

    func setNote(_ note: String?, for verseNumber: Int) {
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        updateAnnotation(for: verseNumber) { annotation in
            annotation.note = trimmed?.isEmpty == true ? nil : trimmed
        }
    }

    func clearAnnotation(for verseNumber: Int) {
        let key = Self.annotationKey(
            language: selectedLanguage,
            bookNumber: selectedBookNumber,
            chapterNumber: selectedChapterNumber,
            verseNumber: verseNumber
        )
        guard verseAnnotations[key] != nil else { return }
        verseAnnotations[key] = nil
        Self.saveVerseAnnotations(verseAnnotations)
    }

    func isHighlighted(_ verseNumber: Int) -> Bool {
        selectedVerseNumbers.contains(verseNumber) || highlightedVerseNumber == verseNumber
    }

    func isSelectedVerse(_ verseNumber: Int) -> Bool {
        selectedVerseNumbers.contains(verseNumber)
    }

    var selectedVerseCount: Int {
        selectedVerseNumbers.count
    }

    func selectedVersesText() -> String? {
        guard let selectedBook, let selectedChapter else { return nil }

        let orderedVerses = selectedChapter.verses.filter { selectedVerseNumbers.contains($0.vnumber) }
        guard !orderedVerses.isEmpty else { return nil }

        let verseLines = orderedVerses.map { verse in
            "\(verse.vnumber). \(verse.displayText)"
        }

        return (["\(selectedBook.bname) \(selectedChapter.cnumber)"] + verseLines)
            .joined(separator: "\n")
    }

    func verseText(for verseNumber: Int) -> String {
        let bookName = selectedBook?.bname ?? "Bible"
        return "\(bookName) \(selectedChapterNumber):\(verseNumber) \(verseTextBody(for: verseNumber) ?? "")".trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func ensureValidSelection() {
        guard let book = books.first(where: { $0.bnumber == selectedBookNumber }) ?? books.first else {
            return
        }

        selectedBookNumber = book.bnumber
        if let currentChapter = book.chapters.first(where: { $0.cnumber == selectedChapterNumber }) {
            selectedChapterNumber = currentChapter.cnumber
        } else {
            selectedChapterNumber = book.chapters.first?.cnumber ?? 1
        }
    }

    private func clearVerseSelections() {
        selectedVerseNumbers.removeAll()
        highlightedVerseNumber = nil
    }

    private func clearNavigationHistory() {
        backHistory.removeAll()
        forwardHistory.removeAll()
    }

    private func updateAnnotation(for verseNumber: Int, mutate: (inout VerseAnnotation) -> Void) {
        let key = Self.annotationKey(
            language: selectedLanguage,
            bookNumber: selectedBookNumber,
            chapterNumber: selectedChapterNumber,
            verseNumber: verseNumber
        )

        var annotation = verseAnnotations[key] ?? VerseAnnotation(
            language: selectedLanguage,
            bookNumber: selectedBookNumber,
            chapterNumber: selectedChapterNumber,
            verseNumber: verseNumber
        )
        mutate(&annotation)
        annotation.updatedAt = .now

        if annotation.highlightColor == nil, (annotation.note?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) {
            verseAnnotations[key] = nil
        } else {
            verseAnnotations[key] = annotation
        }

        Self.saveVerseAnnotations(verseAnnotations)
    }

    private var currentLocation: NavigationLocation? {
        guard books.contains(where: { $0.bnumber == selectedBookNumber }) else { return nil }
        return NavigationLocation(
            language: selectedLanguage,
            bookNumber: selectedBookNumber,
            chapterNumber: selectedChapterNumber,
            verseNumber: highlightedVerseNumber ?? selectedVerseNumbers.max(),
            selectedVerseNumbers: selectedVerseNumbers,
            highlightedVerseNumber: highlightedVerseNumber,
            showingSearchResults: showingSearchResults,
            searchQuery: searchQuery,
            searchScope: searchScope
        )
    }

    private func navigate(to location: NavigationLocation, recordHistory: Bool) {
        guard let resolvedLocation = resolved(location) else { return }
        guard resolvedLocation != currentLocation else { return }

        if recordHistory, let current = currentLocation {
            backHistory.append(current)
            forwardHistory.removeAll()
        }

        apply(location: resolvedLocation)
    }

    private func apply(location: NavigationLocation) {
        if selectedLanguage != location.language {
            selectedLanguage = location.language
            updateParallelLanguageSelection()
        }

        selectedBookNumber = location.bookNumber
        selectedChapterNumber = location.chapterNumber
        showingSearchResults = location.showingSearchResults
        searchQuery = location.searchQuery
        searchScope = location.searchScope
        searchResults = location.showingSearchResults ? searchResults(for: location.searchQuery, scope: location.searchScope, language: location.language) : []
        clearVerseSelections()

        selectedVerseNumbers = location.selectedVerseNumbers
        highlightedVerseNumber = location.highlightedVerseNumber ?? location.verseNumber ?? selectedVerseNumbers.max()
    }

    private func resolved(_ location: NavigationLocation) -> NavigationLocation? {
        guard let books = bibles[location.language]?.books,
              let book = books.first(where: { $0.bnumber == location.bookNumber }) ?? books.first,
              let chapter = book.chapters.first(where: { $0.cnumber == location.chapterNumber }) ?? book.chapters.first
        else {
            return nil
        }

        return NavigationLocation(
            language: location.language,
            bookNumber: book.bnumber,
            chapterNumber: chapter.cnumber,
            verseNumber: location.verseNumber.flatMap { verse(for: location.language, bookNumber: book.bnumber, chapterNumber: chapter.cnumber, verseNumber: $0) != nil ? $0 : nil },
            selectedVerseNumbers: location.selectedVerseNumbers.filter {
                verse(for: location.language, bookNumber: book.bnumber, chapterNumber: chapter.cnumber, verseNumber: $0) != nil
            },
            highlightedVerseNumber: location.highlightedVerseNumber.flatMap {
                verse(for: location.language, bookNumber: book.bnumber, chapterNumber: chapter.cnumber, verseNumber: $0) != nil ? $0 : nil
            },
            showingSearchResults: location.showingSearchResults,
            searchQuery: location.searchQuery,
            searchScope: location.searchScope
        )
    }

    private func searchResults(for query: String, scope: SearchScope, language: BibleLanguage) -> [BibleSearchResult] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let tokens = trimmedQuery
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .filter { !$0.isEmpty }

        guard isValidSearchQuery(trimmedQuery) else {
            return []
        }

        let languageBooks = bibles[language]?.books ?? []
        let targetBooks: [BibleBook]
        switch scope {
        case .currentBook:
            targetBooks = languageBooks.first(where: { $0.bnumber == selectedBookNumber }).map { [$0] } ?? []
        case .oldTestament:
            targetBooks = languageBooks.filter { $0.testament == .old }
        case .newTestament:
            targetBooks = languageBooks.filter { $0.testament == .new }
        case .entireBible:
            targetBooks = languageBooks
        }

        return targetBooks.flatMap { book in
            book.chapters.flatMap { chapter in
                chapter.verses.compactMap { verse in
                    let candidate = verse.plainText.lowercased()
                    guard tokens.allSatisfy(candidate.contains) else { return nil }
                    return BibleSearchResult(
                        language: language,
                        bookNumber: book.bnumber,
                        bookName: book.bname,
                        chapterNumber: chapter.cnumber,
                        verseNumber: verse.vnumber,
                        verseText: verse.displayText
                    )
                }
            }
        }
    }

    private func isValidSearchQuery(_ trimmedQuery: String) -> Bool {
        let tokens = trimmedQuery
            .lowercased()
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
            .filter { !$0.isEmpty }

        return trimmedQuery.count >= 3 && !tokens.isEmpty
    }

    private func verseTextBody(for verseNumber: Int) -> String? {
        verse(for: selectedLanguage, bookNumber: selectedBookNumber, chapterNumber: selectedChapterNumber, verseNumber: verseNumber)?.displayText
    }

    private func updateParallelLanguageSelection() {
        let options = availableParallelLanguages
        guard !options.isEmpty else {
            selectedParallelLanguage = selectedLanguage
            return
        }

        if !options.contains(selectedParallelLanguage) {
            if selectedLanguage != .english, options.contains(.english) {
                selectedParallelLanguage = .english
            } else if options.contains(.telugu) {
                selectedParallelLanguage = .telugu
            } else {
                selectedParallelLanguage = options[0]
            }
        }
    }

    private func versePreview(bookNumber: Int, chapterNumber: Int, verseSpec: String, language: BibleLanguage) -> String {
        verseNumbers(from: verseSpec)
            .compactMap { verse(for: language, bookNumber: bookNumber, chapterNumber: chapterNumber, verseNumber: $0) }
            .map { verse in
                verse.displayText
            }
            .joined(separator: " ")
    }

    private func verseNumbers(from spec: String) -> [Int] {
        spec
            .split(separator: ",")
            .flatMap { part -> [Int] in
                let trimmed = part.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.contains("-") {
                    let rangeParts = trimmed.split(separator: "-").compactMap { Int($0) }
                    guard rangeParts.count == 2, rangeParts[0] <= rangeParts[1] else { return [] }
                    return Array(rangeParts[0]...rangeParts[1])
                }

                return Int(trimmed).map { [$0] } ?? []
            }
    }

    private func verse(for language: BibleLanguage, bookNumber: Int, chapterNumber: Int, verseNumber: Int) -> BibleVerse? {
        verseLookup[language]?[Self.verseKey(bookNumber: bookNumber, chapterNumber: chapterNumber, verseNumber: verseNumber)]
    }

    private func bookName(for bookNumber: Int, language: BibleLanguage) -> String {
        bookNameLookup[language]?[bookNumber] ?? "Book \(bookNumber)"
    }

    private nonisolated static func verseKey(bookNumber: Int, chapterNumber: Int, verseNumber: Int) -> String {
        "\(bookNumber):\(chapterNumber):\(verseNumber)"
    }

    private nonisolated static func makeVerseLookup(for document: BibleDocument) -> [String: BibleVerse] {
        var lookup: [String: BibleVerse] = [:]
        for book in document.books {
            for chapter in book.chapters {
                for verse in chapter.verses {
                    lookup[verseKey(bookNumber: book.bnumber, chapterNumber: chapter.cnumber, verseNumber: verse.vnumber)] = verse
                }
            }
        }
        return lookup
    }

    private nonisolated static func makeBookNameLookup(for document: BibleDocument) -> [Int: String] {
        Dictionary(uniqueKeysWithValues: document.books.map { ($0.bnumber, $0.bname) })
    }

    private nonisolated static func annotationKey(
        language: BibleLanguage,
        bookNumber: Int,
        chapterNumber: Int,
        verseNumber: Int
    ) -> String {
        "\(language.rawValue)-\(bookNumber)-\(chapterNumber)-\(verseNumber)"
    }

    private nonisolated static func loadDefaultLanguage() -> BibleLanguage {
        guard let rawValue = UserDefaults.standard.string(forKey: "defaultBibleLanguage"),
              let language = BibleLanguage(rawValue: rawValue) else {
            return .telugu
        }

        return language
    }

    private nonisolated static func saveDefaultLanguage(_ language: BibleLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: "defaultBibleLanguage")
    }

    private nonisolated static func loadVerseAnnotations() -> [String: VerseAnnotation] {
        guard let url = verseAnnotationsURL(),
              FileManager.default.fileExists(atPath: url.path)
        else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([String: VerseAnnotation].self, from: data)
        } catch {
            return [:]
        }
    }

    private nonisolated static func saveVerseAnnotations(_ annotations: [String: VerseAnnotation]) {
        do {
            let url = try ensureVerseAnnotationsURL()
            let data = try JSONEncoder().encode(annotations)
            try data.write(to: url, options: .atomic)
        } catch {
            // Silently ignore persistence failures so reading remains usable.
        }
    }

    private nonisolated static func verseAnnotationsURL() -> URL? {
        try? ensureVerseAnnotationsURL()
    }

    private nonisolated static func ensureVerseAnnotationsURL() throws -> URL {
        let fileManager = FileManager.default
        guard let baseDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw CocoaError(.fileNoSuchFile)
        }

        let supportDirectory = baseDirectory.appendingPathComponent("FTBS", isDirectory: true)

        try fileManager.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        return supportDirectory.appendingPathComponent("verse-annotations.json")
    }

    private struct NavigationLocation: Hashable {
        let language: BibleLanguage
        let bookNumber: Int
        let chapterNumber: Int
        let verseNumber: Int?
        let selectedVerseNumbers: Set<Int>
        let highlightedVerseNumber: Int?
        let showingSearchResults: Bool
        let searchQuery: String
        let searchScope: SearchScope

        init(
            language: BibleLanguage,
            bookNumber: Int,
            chapterNumber: Int,
            verseNumber: Int?,
            selectedVerseNumbers: Set<Int>,
            highlightedVerseNumber: Int?,
            showingSearchResults: Bool = false,
            searchQuery: String = "",
            searchScope: SearchScope = .currentBook
        ) {
            self.language = language
            self.bookNumber = bookNumber
            self.chapterNumber = chapterNumber
            self.verseNumber = verseNumber
            self.selectedVerseNumbers = selectedVerseNumbers
            self.highlightedVerseNumber = highlightedVerseNumber
            self.showingSearchResults = showingSearchResults
            self.searchQuery = searchQuery
            self.searchScope = searchScope
        }
    }

    private nonisolated static func loadAllBibles() async throws -> [BibleLanguage: BibleDocument] {
        try await withThrowingTaskGroup(of: (BibleLanguage, BibleDocument).self) { group in
            for language in BibleLanguage.allCases {
                let fileName = language.fileName
                group.addTask {
                    let document = try await MainActor.run {
                        try loadBible(fileName: fileName)
                    }
                    return (language, document)
                }
            }

            var loaded: [BibleLanguage: BibleDocument] = [:]
            for try await (language, document) in group {
                loaded[language] = document
            }
            return loaded
        }
    }

    @MainActor
    private static func loadBible(fileName: String) throws -> BibleDocument {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json", subdirectory: "BibleData")
            ?? Bundle.main.url(forResource: fileName, withExtension: "json")
        else {
            throw BibleDataError.missingResource(fileName)
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(BibleDocument.self, from: data)
    }

    private nonisolated static func loadCrossReferences() async throws -> [String: [String]] {
        try await Task.detached(priority: .userInitiated) {
            try loadCrossReferencesSync()
        }.value
    }

    private nonisolated static func loadCrossReferencesSync() throws -> [String: [String]] {
        guard let url = Bundle.main.url(forResource: "crossReferences", withExtension: "json", subdirectory: "BibleData")
            ?? Bundle.main.url(forResource: "crossReferences", withExtension: "json")
        else {
            throw BibleDataError.missingResource("crossReferences")
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([String: [String]].self, from: data)
    }
}

enum BibleDataError: LocalizedError {
    case missingResource(String)

    var errorDescription: String? {
        switch self {
        case .missingResource(let name):
            return "Missing bundled resource: \(name).json"
        }
    }
}

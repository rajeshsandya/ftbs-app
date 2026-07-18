import Foundation

enum BibleLanguage: String, CaseIterable, Identifiable, Codable, Sendable {
    case telugu
    case english
    case hindi
    case kannada
    case malayalam
    case tamil

    nonisolated var id: String { rawValue }

    nonisolated var displayName: String {
        switch self {
        case .telugu:
            return "Telugu"
        case .english:
            return "English"
        case .hindi:
            return "Hindi"
        case .kannada:
            return "Kannada"
        case .malayalam:
            return "Malayalam"
        case .tamil:
            return "Tamil"
        }
    }

    nonisolated var fileName: String {
        switch self {
        case .telugu:
            return "telugu"
        case .english:
            return "english"
        case .hindi:
            return "hindi"
        case .kannada:
            return "kannada"
        case .malayalam:
            return "malayalam"
        case .tamil:
            return "tamil"
        }
    }
}

enum SearchScope: String, CaseIterable, Identifiable {
    case currentBook = "This Book"
    case oldTestament = "Old Testament"
    case newTestament = "New Testament"
    case entireBible = "Entire Bible"

    var id: String { rawValue }
}

enum VerseHighlightColor: String, CaseIterable, Identifiable, Codable, Sendable {
    case yellow
    case green
    case blue
    case pink
    case orange
    case purple
    case red
    case gray

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .blue: return "Blue"
        case .pink: return "Pink"
        case .orange: return "Orange"
        case .purple: return "Purple"
        case .red: return "Red"
        case .gray: return "Gray"
        }
    }
}

struct VerseAnnotation: Codable, Hashable, Sendable {
    let language: BibleLanguage
    let bookNumber: Int
    let chapterNumber: Int
    let verseNumber: Int
    var highlightColor: VerseHighlightColor?
    var note: String?
    var updatedAt: Date

    init(
        language: BibleLanguage,
        bookNumber: Int,
        chapterNumber: Int,
        verseNumber: Int,
        highlightColor: VerseHighlightColor? = nil,
        note: String? = nil,
        updatedAt: Date = .now
    ) {
        self.language = language
        self.bookNumber = bookNumber
        self.chapterNumber = chapterNumber
        self.verseNumber = verseNumber
        self.highlightColor = highlightColor
        self.note = note
        self.updatedAt = updatedAt
    }

    var id: String { key }

    var key: String {
        "\(language.rawValue)-\(bookNumber)-\(chapterNumber)-\(verseNumber)"
    }
}

struct BibleDocument: Codable, Sendable {
    let books: [BibleBook]
}

struct BibleBook: Codable, Identifiable, Hashable, Sendable {
    let bname: String
    let bnumber: Int
    let chapters: [BibleChapter]

    var id: Int { bnumber }
    var testament: Testament { bnumber <= 39 ? .old : .new }

    enum Testament: String, Sendable {
        case old = "Old Testament"
        case new = "New Testament"
    }
}

struct BibleChapter: Codable, Identifiable, Hashable, Sendable {
    let cnumber: Int
    let verses: [BibleVerse]

    var id: Int { cnumber }
}

struct BibleVerse: Codable, Identifiable, Hashable, Sendable {
    let vnumber: Int
    let text: String
    let comment: String?
    let footnotes: [String]?
    let footnote: String?
    let crossReference: String?

    var id: Int { vnumber }

    var displayText: String {
        BibleTextSanitizer.displayText(from: text)
    }

    var plainText: String {
        BibleTextSanitizer.plainText(from: text)
    }

    var resolvedFootnotes: [String] {
        if let footnotes, !footnotes.isEmpty {
            return footnotes.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }

        if let footnote {
            let trimmed = footnote.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return [trimmed]
            }
        }

        return []
    }

    var resolvedComment: String? {
        guard let comment else { return nil }
        let trimmed = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct BibleSearchResult: Identifiable, Hashable, Sendable {
    let language: BibleLanguage
    let bookNumber: Int
    let bookName: String
    let chapterNumber: Int
    let verseNumber: Int
    let verseText: String

    var id: String {
        "\(language.rawValue)-\(bookNumber)-\(chapterNumber)-\(verseNumber)"
    }
}

struct BibleReference: Identifiable, Hashable, Sendable {
    let bookNumber: Int
    let chapterNumber: Int
    let verseSpec: String
    let label: String
    let preview: String

    var id: String {
        "\(bookNumber)-\(chapterNumber)-\(verseSpec)"
    }

    var firstVerseNumber: Int? {
        verseNumbers.first
    }

    var verseNumbers: [Int] {
        verseSpec
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
}

enum BibleTextSanitizer {
    static func plainText(from text: String) -> String {
        text
            .replacingOccurrences(of: "<sup>fn</sup>", with: "")
            .replacingOccurrences(of: "<sup>cmt</sup>", with: "")
            .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func displayText(from text: String) -> String {
        text
            .replacingOccurrences(of: "<sup>fn</sup>", with: " †")
            .replacingOccurrences(of: "<sup>cmt</sup>", with: " ✚")
            .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

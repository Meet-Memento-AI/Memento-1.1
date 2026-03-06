
import Foundation
import Supabase

class JournalService {
    static let shared = JournalService()

    private var client: SupabaseClient {
        SupabaseService.shared.client
    }

    /// Fetches all non-deleted journal entries for the current user, ordered by creation date (newest first).
    func fetchEntries() async throws -> [JournalEntry] {
        let response: [JournalEntryDTO] = try await client
            .from("journal_entries")
            .select()
            .eq("is_deleted", value: false)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response.compactMap { $0.toDomain() }
    }

    /// Creates a new journal entry and returns the created entry with server-assigned values.
    @discardableResult
    func createEntry(_ entry: JournalEntry) async throws -> JournalEntry {
        let dto = JournalEntryDTO(from: entry)
        let response: [JournalEntryDTO] = try await client
            .from("journal_entries")
            .insert(dto)
            .select()
            .execute()
            .value

        guard let createdDTO = response.first, let created = createdDTO.toDomain() else {
            throw NSError(domain: "JournalService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse created entry"])
        }

        // Trigger embedding generation (fire-and-forget)
        Task {
            do {
                try await ChatService.shared.triggerEmbedding(entryId: created.id)
            } catch {
                #if DEBUG
                print("⚠️ [JournalService] Failed to trigger embedding: \(error)")
                #endif
            }
        }

        return created
    }

    /// Updates an existing journal entry.
    func updateEntry(_ entry: JournalEntry) async throws {
        let dto = JournalEntryDTO(from: entry)
        try await client
            .from("journal_entries")
            .update(dto)
            .eq("id", value: entry.id)
            .execute()

        // Trigger embedding regeneration (fire-and-forget)
        Task {
            do {
                try await ChatService.shared.triggerEmbedding(entryId: entry.id)
            } catch {
                #if DEBUG
                print("⚠️ [JournalService] Failed to trigger embedding: \(error)")
                #endif
            }
        }
    }

    struct SoftDeleteUpdate: Encodable {
        let is_deleted: Bool
        let deleted_at: String // Use String for ISO date
    }

    /// Soft deletes a journal entry by setting is_deleted = true.
    func deleteEntry(id: UUID) async throws {
        // Formatter for deleted_at
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: Date())
        
        let updatePayload = SoftDeleteUpdate(is_deleted: true, deleted_at: dateString)
        
        try await client
            .from("journal_entries")
            .update(updatePayload)
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - DTO
// Private Data Transfer Object to handle string-based dates from Supabase
private struct JournalEntryDTO: Codable {
    let id: UUID
    let user_id: UUID
    let title: String
    let content: String
    let word_count: Int?
    let sentiment_score: Double?
    let is_deleted: Bool
    let deleted_at: String?
    let content_hash: String?
    let created_at: String
    let updated_at: String
    
    // Mapping from Domain to DTO
    init(from domain: JournalEntry) {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        self.id = domain.id
        self.user_id = domain.userId
        self.title = domain.title
        self.content = domain.content
        self.word_count = domain.wordCount
        self.sentiment_score = domain.sentimentScore
        self.is_deleted = domain.isDeleted
        self.deleted_at = domain.deletedAt.map { formatter.string(from: $0) }
        self.content_hash = domain.contentHash
        self.created_at = formatter.string(from: domain.createdAt)
        self.updated_at = formatter.string(from: domain.updatedAt)
    }
    
    // Mapping from DTO to Domain
    func toDomain() -> JournalEntry? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try parsing with fractional seconds first, fallback to standard if needed
        guard let created = formatter.date(from: created_at),
              let updated = formatter.date(from: updated_at) else {
            // Fallback for dates without fractional seconds (rare in Postgres but possible)
            let simpleFormatter = ISO8601DateFormatter()
            if let simpleCreated = simpleFormatter.date(from: created_at),
               let simpleUpdated = simpleFormatter.date(from: updated_at) {
                return JournalEntry(
                    id: id,
                    userId: user_id,
                    title: title,
                    content: content,
                    wordCount: word_count,
                    sentimentScore: sentiment_score,
                    isDeleted: is_deleted,
                    deletedAt: deleted_at.flatMap { simpleFormatter.date(from: $0) },
                    contentHash: content_hash,
                    createdAt: simpleCreated,
                    updatedAt: simpleUpdated
                )
            }
            return nil
        }
        
        return JournalEntry(
            id: id,
            userId: user_id,
            title: title,
            content: content,
            wordCount: word_count,
            sentimentScore: sentiment_score,
            isDeleted: is_deleted,
            deletedAt: deleted_at.flatMap { formatter.date(from: $0) },
            contentHash: content_hash,
            createdAt: created,
            updatedAt: updated
        )
    }
}

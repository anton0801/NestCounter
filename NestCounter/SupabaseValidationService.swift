import Foundation
import Supabase

final class SupabaseValidationService: ValidationService {
    private let client: SupabaseClient
    
    init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: "https://smucguxhvwtnzvnspdzy.supabase.co")!,
            supabaseKey: "sb_publishable_xVS4rTekPO3GXrIiu43uRA_80USLzXm"
        )
    }
    
    func validate() async throws -> Bool {
        do {
            let response: [ValidationRow] = try await client
                .from("validation")
                .select()
                .limit(1)
                .execute()
                .value
            
            guard let firstRow = response.first else {
                return false
            }
            
            return firstRow.isValid
        } catch {
            print("🥚 [NestCounter] Validation error: \(error)")
            throw error
        }
    }
}

struct ValidationRow: Codable {
    let id: Int?
    let isValid: Bool
    let createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case isValid = "is_valid"
        case createdAt = "created_at"
    }
}

import Foundation
import Supabase

class RemoteConfigService {
    static let shared = RemoteConfigService()
    
    private var client: SupabaseClient {
        SupabaseService.shared.client
    }
    
    private init() {}
    
    /// Fetches the max number of entries to send for insight generation.
    /// Defaults to 20 if fetch fails or key is missing.
    func fetchInsightEntryLimit() async -> Int {
        do {
            let response: [ConfigDTO] = try await client
                .from("app_config")
                .select()
                .eq("key", value: "insight_entry_limit")
                .limit(1)
                .execute()
                .value
            
            if let config = response.first {
                // Handle JSONB value which could be a number directly
                if let intVal = config.value.value as? Int {
                    return intVal
                }
                // Handle if it somehow came as a string
                if let strVal = config.value.value as? String, let intVal = Int(strVal) {
                    return intVal
                }
                // Handle double
                if let doubleVal = config.value.value as? Double {
                    return Int(doubleVal)
                }
            }
        } catch {
            print("⚠️ [RemoteConfigService] Failed to fetch limit, using default. Error: \(error)")
        }
        
        return 20 // Default fallback
    }
    
    /// Fetches the default time frame (e.g., "Week", "Month")
    func fetchDefaultTimeFrame() async -> String {
        do {
            let response: [ConfigDTO] = try await client
                .from("app_config")
                .select()
                .eq("key", value: "default_insight_timeframe")
                .limit(1)
                .execute()
                .value
            
            if let config = response.first, let strVal = config.value.value as? String {
                return strVal
            }
        } catch {
            print("⚠️ [RemoteConfigService] Failed to fetch default timeframe. Error: \(error)")
        }
        
        return "Month" // Default fallback
    }
}

// DTO for fetching from app_config
private struct ConfigDTO: Decodable {
    let key: String
    let value: AnyCodable
}

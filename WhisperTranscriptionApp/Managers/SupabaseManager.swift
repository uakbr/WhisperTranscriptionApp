import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: "https://your-project-ref.supabase.co")! // Replace with your Supabase URL
        let supabaseKey = "your-anon-key" // Replace with your Supabase Anon/Public API Key
        client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
} 
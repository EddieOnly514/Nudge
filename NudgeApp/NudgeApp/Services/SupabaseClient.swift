import Foundation
import Supabase

class SupabaseClient {
    static let shared = SupabaseClient()

    let client: SupabaseClient

    private init() {
        guard let url = URL(string: SupabaseConfig.url) else {
            fatalError("Invalid Supabase URL")
        }

        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: SupabaseConfig.anonKey
        )
    }

    // Database access
    var database: PostgrestClient {
        client.database
    }

    // Auth access
    var auth: AuthClient {
        client.auth
    }

    // Storage access
    var storage: StorageClient {
        client.storage
    }

    // Realtime access
    var realtime: RealtimeClient {
        client.realtime
    }
}

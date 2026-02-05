//
//  SupabaseService.swift
//  life-encyclopedia
//
//  Service for CRUD operations with Supabase
//

import Foundation

@Observable
final class SupabaseService {
    
    // MARK: - Errors
    
    enum SupabaseError: LocalizedError {
        case invalidURL
        case invalidResponse
        case networkError(Error)
        case notConfigured
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid Supabase URL"
            case .invalidResponse:
                return "Invalid response from database"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .notConfigured:
                return "Supabase is not configured. Please add your credentials."
            }
        }
    }
    
    // MARK: - Properties
    
    private var isConfigured: Bool {
        APIConfig.supabaseURL != "YOUR_SUPABASE_URL" &&
        APIConfig.supabaseAnonKey != "YOUR_SUPABASE_ANON_KEY"
    }
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    
    // MARK: - Public Methods
    
    /// Search for existing people by name (case-insensitive partial match)
    /// - Parameter query: The name to search for
    /// - Returns: Array of matching Person objects
    func searchPeople(byName query: String) async throws -> [Person] {
        guard isConfigured else {
            return []
        }
        
        // Encode the query for URL, using ilike for case-insensitive partial matching
        let trimmedQuery = query.trimmingCharacters(in: .whitespaces)
        guard !trimmedQuery.isEmpty else { return [] }
        
        // URL encode the query
        guard let encodedQuery = trimmedQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return []
        }
        
        // Use ilike for case-insensitive matching with wildcards
        guard let url = URL(string: "\(APIConfig.supabaseURL)/rest/v1/people?name=ilike.*\(encodedQuery)*&order=created_at.desc") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(APIConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SupabaseError.invalidResponse
            }
            
            let supabasePeople = try decoder.decode([SupabasePerson].self, from: data)
            return supabasePeople.map { $0.toPerson() }
            
        } catch let error as SupabaseError {
            throw error
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Fetch all people from the database
    /// - Returns: Array of Person objects sorted by creation date (newest first)
    func fetchPeople() async throws -> [Person] {
        guard isConfigured else {
            // Return empty array if not configured (for development)
            return []
        }
        
        guard let url = URL(string: "\(APIConfig.supabaseURL)/rest/v1/people?order=created_at.desc") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(APIConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SupabaseError.invalidResponse
            }
            
            let supabasePeople = try decoder.decode([SupabasePerson].self, from: data)
            return supabasePeople.map { $0.toPerson() }
            
        } catch let error as SupabaseError {
            throw error
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Fetch people with server-side filtering by domain
    /// - Parameter domain: The domain to filter by
    /// - Returns: Array of Person objects with matching primary domain
    func fetchPeople(byDomain domain: Domain) async throws -> [Person] {
        guard isConfigured else { return [] }
        
        // Use JSONB filtering: filter_metadata->>'primaryDomain' = 'science'
        let domainFilter = "filter_metadata->>primaryDomain=eq.\(domain.rawValue)"
        guard let url = URL(string: "\(APIConfig.supabaseURL)/rest/v1/people?\(domainFilter)&order=created_at.desc") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(APIConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SupabaseError.invalidResponse
            }
            
            let supabasePeople = try decoder.decode([SupabasePerson].self, from: data)
            return supabasePeople.map { $0.toPerson() }
            
        } catch let error as SupabaseError {
            throw error
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Update a person's filter metadata
    /// - Parameters:
    ///   - id: The person's ID
    ///   - metadata: The new filter metadata
    func updateFilterMetadata(id: UUID, metadata: FilterMetadata) async throws {
        guard isConfigured else { return }
        
        guard let url = URL(string: "\(APIConfig.supabaseURL)/rest/v1/people?id=eq.\(id.uuidString)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(APIConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        // Encode just the filter_metadata field
        struct MetadataUpdate: Codable {
            let filterMetadata: FilterMetadata
            
            enum CodingKeys: String, CodingKey {
                case filterMetadata = "filter_metadata"
            }
        }
        
        let updateData = MetadataUpdate(filterMetadata: metadata)
        request.httpBody = try encoder.encode(updateData)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 || httpResponse.statusCode == 204 else {
                throw SupabaseError.invalidResponse
            }
        } catch let error as SupabaseError {
            throw error
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Save a new person to the database
    func savePerson(_ person: Person) async throws -> Person {
        guard isConfigured else {
            // Return the person as-is if not configured (for development)
            return person
        }
        
        guard let url = URL(string: "\(APIConfig.supabaseURL)/rest/v1/people") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(APIConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let insertData = PersonInsert(from: person)
        request.httpBody = try encoder.encode(insertData)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 201 else {
                throw SupabaseError.invalidResponse
            }
            
            let savedPeople = try decoder.decode([SupabasePerson].self, from: data)
            guard let savedPerson = savedPeople.first else {
                throw SupabaseError.invalidResponse
            }
            
            return savedPerson.toPerson()
            
        } catch let error as SupabaseError {
            throw error
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Delete a person from the database
    func deletePerson(id: UUID) async throws {
        guard isConfigured else { return }
        
        guard let url = URL(string: "\(APIConfig.supabaseURL)/rest/v1/people?id=eq.\(id.uuidString)") else {
            throw SupabaseError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(APIConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 204 || httpResponse.statusCode == 200 else {
                throw SupabaseError.invalidResponse
            }
        } catch let error as SupabaseError {
            throw error
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
    
    /// Increment the view count for a person
    /// Called when a user views a person's detail page
    func incrementViewCount(id: UUID) async throws {
        guard isConfigured else { return }
        
        // Use Supabase RPC to atomically increment view_count
        // First, we need to fetch current value, then update
        guard let url = URL(string: "\(APIConfig.supabaseURL)/rest/v1/people?id=eq.\(id.uuidString)") else {
            throw SupabaseError.invalidURL
        }
        
        // First fetch the current view count
        var getRequest = URLRequest(url: url)
        getRequest.httpMethod = "GET"
        getRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        getRequest.setValue(APIConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
        getRequest.setValue("Bearer \(APIConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (getData, getResponse) = try await URLSession.shared.data(for: getRequest)
            
            guard let httpResponse = getResponse as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw SupabaseError.invalidResponse
            }
            
            let people = try decoder.decode([SupabasePerson].self, from: getData)
            guard let person = people.first else {
                throw SupabaseError.invalidResponse
            }
            
            let newViewCount = (person.viewCount ?? 0) + 1
            
            // Now update with incremented count
            var patchRequest = URLRequest(url: url)
            patchRequest.httpMethod = "PATCH"
            patchRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            patchRequest.setValue(APIConfig.supabaseAnonKey, forHTTPHeaderField: "apikey")
            patchRequest.setValue("Bearer \(APIConfig.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
            
            let updateData: [String: Any] = [
                "view_count": newViewCount,
                "last_viewed_at": ISO8601DateFormatter().string(from: Date())
            ]
            patchRequest.httpBody = try JSONSerialization.data(withJSONObject: updateData)
            
            let (_, patchResponse) = try await URLSession.shared.data(for: patchRequest)
            
            guard let patchHttpResponse = patchResponse as? HTTPURLResponse,
                  patchHttpResponse.statusCode == 200 || patchHttpResponse.statusCode == 204 else {
                throw SupabaseError.invalidResponse
            }
            
        } catch let error as SupabaseError {
            throw error
        } catch {
            throw SupabaseError.networkError(error)
        }
    }
}

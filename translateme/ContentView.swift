import SwiftUI
import Firebase

// MARK: - Translation Model
struct Translation: Identifiable {
    var id: String
    var original: String
    var translated: String
}

// MARK: - ContentView for Displaying and Managing Translations
struct ContentView: View {
    @State private var inputText: String = ""
    @State private var translatedText: String = ""
    @State private var translations: [Translation] = []

    var body: some View {
        NavigationView {
            VStack {
                // Input Text Field
                TextField("Enter text", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // Translate Button
                Button(action: {
                    translateText(inputText) { translation in
                        if let translation = translation {
                            translatedText = translation
                            saveTranslation(original: inputText, translated: translation)
                        } else {
                            translatedText = "Translation failed"
                        }
                    }
                }) {
                    Text("Translate Me")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }

                // Display Translated Text
                Text("Translated: \(translatedText)")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)

                // View Saved Translations Button
                NavigationLink(destination: TranslationsListView()) {
                    Text("View Saved Translations")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }

                // Erase History Button
                Button(action: deleteAllTranslations) {
                    Text("Erase All History")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Translate Me")
        }
    }

    // MARK: - Translate Text Function (Using MyMemory API)
    func translateText(_ text: String, completion: @escaping (String?) -> Void) {
        let urlString = "https://api.mymemory.translated.net/get?q=\(text)&langpair=en|es"
        guard let url = URL(string: urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error making API request: \(error.localizedDescription)")
                completion(nil)
                return
            }
            guard let data = data else {
                print("No data received")
                completion(nil)
                return
            }

            do {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON response: \(jsonString)")
                }

                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let responseData = jsonResponse["responseData"] as? [String: Any],
                   let translatedText = responseData["translatedText"] as? String {
                    print("Extracted translated text: \(translatedText)")
                    completion(translatedText)
                } else {
                    print("Translation failed: Invalid response data")
                    completion(nil)
                }
            } catch {
                print("Failed to decode response: \(error.localizedDescription)")
                completion(nil)
            }
        }.resume()
    }

    // MARK: - Save Translation to Firestore
    func saveTranslation(original: String, translated: String) {
        let db = Firestore.firestore()
        let data: [String: Any] = [
            "original": original,
            "translated": translated,
            "timestamp": Timestamp()
        ]
        db.collection("translations").addDocument(data: data) { error in
            if let error = error {
                print("Error saving translation: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Delete All Translations Function
    func deleteAllTranslations() {
        let db = Firestore.firestore()
        db.collection("translations").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching documents for deletion: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            for document in documents {
                db.collection("translations").document(document.documentID).delete { error in
                    if let error = error {
                        print("Error deleting document: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}

// MARK: - TranslationsListView for Displaying Saved Translations
struct TranslationsListView: View {
    @State private var translations: [Translation] = []

    var body: some View {
        List(translations) { translation in
            VStack(alignment: .leading) {
                Text("Original: \(translation.original)")
                    .font(.headline)
                Text("Translated: \(translation.translated)")
                    .font(.subheadline)
            }
        }
        .onAppear {
            fetchTranslations()
        }
        .navigationTitle("Saved Translations")
    }

    // MARK: - Fetch Translations from Firestore
    func fetchTranslations() {
        let db = Firestore.firestore()
        db.collection("translations").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents else {
                print("Error fetching documents: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            translations = documents.map { doc in
                Translation(
                    id: doc.documentID,
                    original: doc["original"] as? String ?? "",
                    translated: doc["translated"] as? String ?? ""
                )
            }
        }
    }
}


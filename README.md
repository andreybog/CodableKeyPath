# CodableKeyPath
KeyPath support for Codable types in Swift via extensions.

Assume we have json:
```swift
{
    "id": 1,
    "name": "Tomas",
    "meta_info": {
        "player_id": 1,
        "link": "http://profile.com.ua",
        "avatar": {
            "id": 1,
            "url": "http://someimage.jpg"
        }
    }
}
```

and Person struct:

```swift
struct Person {
    let id: Int
    let name: String
    var avatarURL: URL?
    var avatarId: Int?
}
```

#### Decoding

We can decode json in Person by adding follow extensions:

```swift
extension Person {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case avatar
        case url
        case metaInfo = "meta_info"
    }
}

extension Person: Decodable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
    
        id = try container.decode(.id)
        name = try container.decode(.name)
        
        avatarURL = try container.decodeIfPresent([.metaInfo, .avatar, .url])
        avatarId = try container.decodeIfPresent([.metaInfo, .avatar, .id])
    }
}


let json: Data = "mentioned above json string".data(using: .utf8)
let decoder = JSONDecoder()
let person = try decoder.decode(Person.self, from: json)
```

#### Encoding

Encoding process the same:

```swift
extension Person: Encodable {
    func encode(to encoder: Encoder) throws {
        var containers: [String: KeyedEncodingContainer<Person.CodingKeys>] = [:]
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        try container.encode(avatarId, keyPath: [.metaInfo, .avatar, .id], containers: &containers)
        try container.encode(avatarURL, keyPath: [.metaInfo, .avatar, .url], containers: &containers)
    }
}

let encoder = JSONEncoder()
let personData = try encoder.encoder(person)
```

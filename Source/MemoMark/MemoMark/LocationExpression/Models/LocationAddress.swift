import Foundation

struct LocationAddress:
    Hashable,
    Codable {

    var country: String?

    var province: String?

    var city: String?

    var district: String?

    var name: String?

    init(
        country: String? = nil,
        province: String? = nil,
        city: String? = nil,
        district: String? = nil,
        name: String? = nil
    ) {
        self.country = country
        self.province = province
        self.city = city
        self.district = district
        self.name = name
    }
}

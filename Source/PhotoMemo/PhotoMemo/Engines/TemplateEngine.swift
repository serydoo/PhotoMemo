import Foundation

struct TemplateEngine {

    static func render(
        template: String,
        values: [String:String]
    ) -> String {

        var result = template

        for (key,value) in values {

            result = result.replacingOccurrences(
                of: "{{\(key)}}",
                with: value
            )
        }

        return result
    }

}

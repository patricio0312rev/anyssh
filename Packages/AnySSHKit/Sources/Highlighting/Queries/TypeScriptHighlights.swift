enum TypeScriptHighlights {
    static let source =
        #"""
        [
          (type_identifier)
          (predefined_type)
        ] @type

        (required_parameter
          pattern: (identifier) @variable)

        (optional_parameter
          pattern: (identifier) @variable)

        (property_signature
          name: (property_identifier) @variable)

        (enum_assignment
          name: (property_identifier) @variable)

        [
          "abstract"
          "declare"
          "enum"
          "implements"
          "interface"
          "keyof"
          "namespace"
          "private"
          "protected"
          "public"
          "type"
          "readonly"
          "override"
          "satisfies"
          "is"
          "infer"
        ] @keyword

        [
          "?"
          ":"
        ] @operator

        """# + JavaScriptHighlights.source
}

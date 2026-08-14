enum SwiftHighlights {
    static let source = #"""
        (modifiers
          (attribute
            "@" @attribute
            (user_type
              (type_identifier) @attribute)))

        (function_declaration
          (simple_identifier) @function)

        (protocol_function_declaration
          name: (simple_identifier) @function)

        (init_declaration
          "init" @function)

        (call_expression
          (simple_identifier) @function)

        (call_expression
          (navigation_expression
            (navigation_suffix
              (simple_identifier) @function)))

        (call_expression
          (prefix_expression
            (simple_identifier) @function))

        (parameter
          external_name: (simple_identifier) @variable)

        (parameter
          name: (simple_identifier) @variable)

        (property_declaration
          (pattern
            (simple_identifier) @variable))

        (navigation_expression
          (navigation_suffix
            (simple_identifier) @variable))

        (value_argument
          name: (value_argument_label
            (simple_identifier) @variable))

        [
          (self_expression)
          (super_expression)
        ] @variable

        (type_identifier) @type

        [
          (comment)
          (multiline_comment)
        ] @comment

        [
          (line_str_text)
          (str_escaped_char)
          (multi_line_str_text)
          (raw_str_part)
          (raw_str_end_part)
          "\""
          "\"\"\""
        ] @string

        (regex_literal) @string

        [
          (integer_literal)
          (hex_literal)
          (oct_literal)
          (bin_literal)
          (real_literal)
          (boolean_literal)
          "nil"
        ] @number

        [
          (visibility_modifier)
          (member_modifier)
          (function_modifier)
          (property_modifier)
          (parameter_modifier)
          (inheritance_modifier)
          (mutation_modifier)
          (throws)
          (where_keyword)
          (getter_specifier)
          (setter_specifier)
          (modify_specifier)
          (else)
          (default_keyword)
          (try_operator)
          (throw_keyword)
          (catch_keyword)
          (directive)
          "func"
          "deinit"
          "protocol"
          "extension"
          "indirect"
          "nonisolated"
          "override"
          "convenience"
          "required"
          "some"
          "any"
          "weak"
          "unowned"
          "didSet"
          "willSet"
          "subscript"
          "let"
          "var"
          "enum"
          "struct"
          "class"
          "typealias"
          "async"
          "await"
          "import"
          "while"
          "repeat"
          "continue"
          "break"
          "guard"
          "if"
          "switch"
          "case"
          "fallthrough"
          "return"
          "for"
          "in"
          "do"
        ] @keyword

        (custom_operator) @operator

        [
          "+"
          "-"
          "*"
          "/"
          "%"
          "="
          "+="
          "-="
          "*="
          "/="
          "<"
          ">"
          "<<"
          ">>"
          "<="
          ">="
          "^"
          "&"
          "&&"
          "|"
          "||"
          "~"
          "%="
          "!="
          "=="
          "==="
          "?"
          "??"
          "->"
          "..<"
          "..."
          (bang)
        ] @operator
        """#
}

enum GoHighlights {
    static let source = #"""
        (function_declaration
          name: (identifier) @function)

        (method_declaration
          name: (field_identifier) @function)

        (call_expression
          function: (identifier) @function)

        (call_expression
          function: (selector_expression
            field: (field_identifier) @function))

        (type_identifier) @type

        (field_identifier) @variable

        (parameter_declaration
          name: (identifier) @variable)

        (comment) @comment

        [
          (interpreted_string_literal)
          (raw_string_literal)
          (rune_literal)
          (escape_sequence)
        ] @string

        [
          (int_literal)
          (float_literal)
          (imaginary_literal)
          (true)
          (false)
          (nil)
          (iota)
        ] @number

        [
          "break"
          "case"
          "chan"
          "const"
          "continue"
          "default"
          "defer"
          "else"
          "fallthrough"
          "for"
          "func"
          "go"
          "goto"
          "if"
          "import"
          "interface"
          "map"
          "package"
          "range"
          "return"
          "select"
          "struct"
          "switch"
          "type"
          "var"
        ] @keyword

        [
          "--"
          "-"
          "-="
          ":="
          "!"
          "!="
          "..."
          "*"
          "*="
          "/"
          "/="
          "&"
          "&&"
          "&="
          "%"
          "%="
          "^"
          "^="
          "+"
          "++"
          "+="
          "<-"
          "<"
          "<<"
          "<<="
          "<="
          "="
          "=="
          ">"
          ">="
          ">>"
          ">>="
          "|"
          "|="
          "||"
          "~"
        ] @operator
        """#
}

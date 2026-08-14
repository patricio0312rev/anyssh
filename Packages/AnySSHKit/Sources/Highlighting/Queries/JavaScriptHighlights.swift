enum JavaScriptHighlights {
    static let source = #"""
        (function_declaration
          name: (identifier) @function)

        (function_expression
          name: (identifier) @function)

        (method_definition
          name: (property_identifier) @function)

        (variable_declarator
          name: (identifier) @function
          value: [(function_expression) (arrow_function)])

        (pair
          key: (property_identifier) @function
          value: [(function_expression) (arrow_function)])

        (call_expression
          function: (identifier) @function)

        (call_expression
          function: (member_expression
            property: (property_identifier) @function))

        (property_identifier) @variable

        [
          (shorthand_property_identifier)
          (shorthand_property_identifier_pattern)
        ] @variable

        [
          (this)
          (super)
        ] @variable

        (comment) @comment

        [
          (string)
          (template_string)
          (regex)
        ] @string

        (escape_sequence) @string

        (number) @number

        [
          (true)
          (false)
          (null)
          (undefined)
        ] @number

        [
          "as"
          "async"
          "await"
          "break"
          "case"
          "catch"
          "class"
          "const"
          "continue"
          "debugger"
          "default"
          "delete"
          "do"
          "else"
          "export"
          "extends"
          "finally"
          "for"
          "from"
          "function"
          "get"
          "if"
          "import"
          "in"
          "instanceof"
          "let"
          "new"
          "of"
          "return"
          "set"
          "static"
          "switch"
          "target"
          "throw"
          "try"
          "typeof"
          "var"
          "void"
          "while"
          "with"
          "yield"
        ] @keyword

        [
          "-"
          "--"
          "-="
          "+"
          "++"
          "+="
          "*"
          "*="
          "**"
          "**="
          "/"
          "/="
          "%"
          "%="
          "<"
          "<="
          "<<"
          "<<="
          "="
          "=="
          "==="
          "!"
          "!="
          "!=="
          "=>"
          ">"
          ">="
          ">>"
          ">>="
          ">>>"
          ">>>="
          "~"
          "^"
          "&"
          "|"
          "^="
          "&="
          "|="
          "&&"
          "||"
          "??"
          "&&="
          "||="
          "??="
        ] @operator
        """#
}

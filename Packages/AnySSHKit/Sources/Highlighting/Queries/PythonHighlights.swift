enum PythonHighlights {
    static let source = #"""
        (decorator) @attribute

        (function_definition
          name: (identifier) @function)

        (call
          function: (identifier) @function)

        (call
          function: (attribute
            attribute: (identifier) @function))

        (class_definition
          name: (identifier) @type)

        (type (identifier) @type)

        (attribute
          attribute: (identifier) @variable)

        (parameters
          (identifier) @variable)

        (default_parameter
          name: (identifier) @variable)

        (keyword_argument
          name: (identifier) @variable)

        (comment) @comment

        [
          (string)
          (escape_sequence)
        ] @string

        [
          (integer)
          (float)
          (none)
          (true)
          (false)
        ] @number

        [
          "as"
          "assert"
          "async"
          "await"
          "break"
          "class"
          "continue"
          "def"
          "del"
          "elif"
          "else"
          "except"
          "finally"
          "for"
          "from"
          "global"
          "if"
          "import"
          "lambda"
          "nonlocal"
          "pass"
          "raise"
          "return"
          "try"
          "while"
          "with"
          "yield"
          "match"
          "case"
        ] @keyword

        [
          "-"
          "-="
          "!="
          "*"
          "**"
          "**="
          "*="
          "/"
          "//"
          "//="
          "/="
          "&"
          "&="
          "%"
          "%="
          "^"
          "^="
          "+"
          "->"
          "+="
          "<"
          "<<"
          "<<="
          "<="
          "<>"
          "="
          ":="
          "=="
          ">"
          ">="
          ">>"
          ">>="
          "|"
          "|="
          "~"
          "@="
          "and"
          "in"
          "is"
          "not"
          "or"
        ] @operator
        """#
}

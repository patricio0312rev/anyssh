enum DataHighlights {
    static let json = #"""
        (pair
          key: (_) @variable)

        (string) @string

        (escape_sequence) @string

        (number) @number

        [
          (null)
          (true)
          (false)
        ] @number

        (comment) @comment
        """#

    static let yaml = #"""
        (block_mapping_pair
          key: (flow_node
            [
              (double_quote_scalar)
              (single_quote_scalar)
            ] @variable))

        (block_mapping_pair
          key: (flow_node
            (plain_scalar
              (string_scalar) @variable)))

        (flow_mapping
          (_
            key: (flow_node
              [
                (double_quote_scalar)
                (single_quote_scalar)
              ] @variable)))

        (flow_mapping
          (_
            key: (flow_node
              (plain_scalar
                (string_scalar) @variable))))

        (comment) @comment

        [
          (double_quote_scalar)
          (single_quote_scalar)
          (block_scalar)
          (string_scalar)
        ] @string

        [
          (integer_scalar)
          (float_scalar)
          (boolean_scalar)
          (null_scalar)
        ] @number

        (tag) @type

        [
          (anchor_name)
          (alias_name)
          (yaml_directive)
          (tag_directive)
          (reserved_directive)
        ] @attribute
        """#

    static let markdown = #"""
        (atx_heading
          (inline) @function)

        (setext_heading
          (paragraph) @function)

        [
          (atx_h1_marker)
          (atx_h2_marker)
          (atx_h3_marker)
          (atx_h4_marker)
          (atx_h5_marker)
          (atx_h6_marker)
          (setext_h1_underline)
          (setext_h2_underline)
          (thematic_break)
        ] @keyword

        (info_string) @attribute

        [
          (indented_code_block)
          (code_fence_content)
          (link_title)
        ] @string

        (link_destination) @type

        (link_label) @variable

        (block_quote_marker) @comment

        (backslash_escape) @string
        """#
}

enum HostileInput {
    static let path = #"it's a "trap"; rm -rf tmp; $(whoami) `id` \ | & > < * ? ~ñ🎉.txt"#

    static let composed = "espan\u{00F1}ol.txt"
    static let decomposed = "espan\u{006E}\u{0303}ol.txt"

    static let corpus: [String] = [
        path,
        "plain.txt",
        "two words.txt",
        "'",
        "''''",
        #"back\slash and "double" and 'single'.txt"#,
        "$HOME ${PATH} $(id) `whoami` $((1+1))",
        "semi;colon && pipe | amp & redirect > < glob * ? [a-z] {a,b}",
        "new\nline\ttab\rcarriage",
        "trailing newline\n",
        "🎉ñ🇵🇪 中文 \u{200B}",
        composed,
        decomposed,
        "-rf",
        "--",
        "",
        String(repeating: "'", count: 64),
    ]
}

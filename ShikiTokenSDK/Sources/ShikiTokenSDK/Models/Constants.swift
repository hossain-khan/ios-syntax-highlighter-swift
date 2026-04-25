import Foundation

/// String constants for languages supported by the Shiki Token Service.
///
/// Use these with request types instead of raw strings. The server may support additional
/// languages beyond those listed here — use ``all`` or fetch dynamically via ``ShikiClient/languages()``.
public enum ShikiLanguage {
    public static let text = "text"
    public static let kotlin = "kotlin"
    public static let java = "java"
    public static let python = "python"
    public static let javascript = "javascript"
    public static let typescript = "typescript"
    public static let swift = "swift"
    public static let go = "go"
    public static let rust = "rust"
    public static let json = "json"
    public static let yaml = "yaml"
    public static let bash = "bash"
    public static let sql = "sql"
    public static let html = "html"
    public static let css = "css"
    public static let c = "c"
    public static let cpp = "cpp"
    public static let ruby = "ruby"
    public static let php = "php"
    public static let markdown = "markdown"
    public static let xml = "xml"
    public static let toml = "toml"
    public static let dockerfile = "dockerfile"
    public static let graphql = "graphql"
    public static let csharp = "csharp"
    public static let scala = "scala"
    public static let r = "r"
    public static let dart = "dart"
    public static let powershell = "powershell"
    public static let lua = "lua"
    public static let perl = "perl"
    public static let shellscript = "shellscript"

    public static let all: [String] = [
        text, kotlin, java, python, javascript, typescript, swift, go, rust,
        json, yaml, bash, sql, html, css, c, cpp, ruby, php, markdown,
        xml, toml, dockerfile, graphql, csharp, scala, r, dart, powershell,
        lua, perl, shellscript
    ]
}

/// String constants for themes supported by the Shiki Token Service.
///
/// Use these with request types instead of raw strings. Fetch dynamically via ``ShikiClient/languages()``
/// for the most up-to-date list.
public enum ShikiTheme {
    public static let githubDark = "github-dark"
    public static let githubLight = "github-light"
    public static let oneDarkPro = "one-dark-pro"
    public static let dracula = "dracula"
    public static let minLight = "min-light"
    public static let darkPlus = "dark-plus"
    public static let lightPlus = "light-plus"

    public static let all: [String] = [
        githubDark, githubLight, oneDarkPro, dracula, minLight, darkPlus, lightPlus
    ]
}

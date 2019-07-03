module Themes
using Documenter.Writers: HTMLWriter
using Sass

"""
    compile(src[, dst])

Compile an input Sass/SCSS file `src` into a CSS file. The standard Documenter Sass/SCSS
files are available in the include path.

The optional `dst` argument can be used to specify the output file. Otherwise, the file
extension of the `src` file is simply replaced by `.css`.
"""
function compile(src, dst=nothing)
    isfile(src) || error("$name not at $src")
    if dst === nothing
        s = (endswith(src, ".scss") || endswith(src, ".sass")) ? first(splitext(src)) : src
        dst = "$(s).css"
    end
    Sass.compile_file(src, dst; include_paths=HTMLWriter.ASSETS_SASS)
end

"""
    compile_native_theme(name; dst=nothing)

Compiles a native Documenter theme and places it into Documenter's assets directory.

Optionally, the `dst` keyword argument can be used to specify the output file.
"""
function compile_native_theme(name; dst = nothing)
    name in HTMLWriter.THEMES || error("Bad theme name. Valid themes: $(HTMLWriter.THEMES)")
    src = joinpath(HTMLWriter.ASSETS_SASS, "$(name).scss")
    dst = (dst === nothing) ? joinpath(HTMLWriter.ASSETS_THEMES, "$(name).css") : dst
    compile(src, dst)
    return dst
end

end

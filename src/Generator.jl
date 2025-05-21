"""
Provides the functions related to generating documentation stubs.
"""
module Generator

using DocStringExtensions
using UUIDs: uuid4

"""
$(SIGNATURES)

Attempts to save a file at `\$(root)/\$(filename)`. `f` will be called with file
stream (see [`open`](https://docs.julialang.org/en/v1/base/io-network/#Base.open)).

`filename` can also be a file in a subdirectory (e.g. `src/index.md`), and then
then subdirectories will be created automatically.
"""
function savefile(f, root, filename)
    filepath = joinpath(root, filename)
    if ispath(filepath) error("$(filepath) already exists") end
    @info("Generating $filename at $filepath")
    mkpath(dirname(filepath))
    open(f,filepath,"w")
end

"""
$(SIGNATURES)

Contents of the default `make.jl` file.
"""
function make(pkgname; format = :html)
    fmtpkg = format === :markdown ? ", DocumenterMarkdown" :
             format === :pdf      ? ", DocumenterLaTeX" : ""
    fmtstr = format === :html ? "Documenter.HTML()" :
             format === :markdown  ? "Markdown()" :
             format === :pdf  ? "LaTeX()" : ""

    sitename = format !== :markdown ? "\n    sitename = \"$(pkgname)\"," : ""
    """
    using Documenter$(fmtpkg)
    using $(pkgname)

    makedocs($(sitename)
        format = $(fmtstr),
        modules = [$(pkgname)],
        # The generated stub will not be in a Git repo usually,
        # so we want to disable the remote URL generation (which otherwise
        # tries to automatically determine the remote repo by inspecting
        # the Git repo's remotes)
        remotes=nothing
    )

    # Documenter can also automatically deploy documentation to gh-pages.
    # See "Hosting Documentation" and deploydocs() in the Documenter manual
    # for more information.
    #=deploydocs(
        repo = "<repository url>"
    )=#
    """
end

"""
$(SIGNATURES)

Contents of the default `.gitignore` file.
"""
function gitignore()
    """
    build/
    site/
    """
end

"""
$(SIGNATURES)

Contents of the default `Project.toml` file.
"""
function project(;format = :html)
    deps = Dict("Documenter" => "e30172f5-a6a5-5a46-863b-614d45cd2de4")
    if format === :markdown
        deps["DocumenterMarkdown"] = "997ab1e6-3595-5248-9280-8efb232c3433"
    elseif format === :pdf
        deps["DocumenterLaTeX"] = "cd674d7a-5f81-5cf3-af33-235ef1834b99"
    end
    io = IOBuffer()
    print(io, "[deps]\n")
    for dep in deps
        print(io, dep.first, " = \"", dep.second, "\"\n")
    end

    return String(take!(io))
end

mkdocs_default(name, value, default) = value == nothing ? "#$name$default" : "$name$value"

"""
$(SIGNATURES)

Contents of the default `mkdocs.yml` file.
"""
function mkdocs(pkgname;
        description = nothing,
        author = nothing,
        url = nothing
    )
    s = """
    # See the mkdocs user guide for more information on these settings.
    #   http://www.mkdocs.org/user-guide/configuration/

    site_name:        $(pkgname).jl
    $(mkdocs_default("repo_url:         ", url, "https://github.com/USER_NAME/PACKAGE_NAME.jl"))
    $(mkdocs_default("site_description: ", description, "Description..."))
    $(mkdocs_default("site_author:      ", author, "USER_NAME"))

    theme: readthedocs

    extra_css:
      - assets/Documenter.css

    extra_javascript:
      - https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS_HTML
      - assets/mathjaxhelper.js

    markdown_extensions:
      - extra
      - tables
      - fenced_code
      - mdx_math

    docs_dir: 'build'

    pages:
      - Home: index.md
    """
end

"""
$(SIGNATURES)

Contents of the default `src/index.md` file.
"""
function index(pkgname)
    """
    # $(pkgname).jl

    Documentation for $(pkgname).jl
    """
end

"""

"""
function genpackage(name::AbstractString; destination::AbstractString=pwd(), force::Bool=false)
    package_root = joinpath(destination, name)
    package_uuid = string(uuid4())

    mktempdir() do tmp_root
        # Generate a basic Julia Project.toml for this package
        open(joinpath(tmp_root, "Project.toml"), "w") do io
            write(io, """
            name = "$(name)"
            uuid = "$(package_uuid)"
            version = "0.0.0"
            """)
        end

        open(joinpath(tmp_root, "Makefile"), "w") do io
            write(io, """
            .PHONY: docs
            docs: docs/Manifest.toml
            \tjulia --project=docs docs/make.jl

            docs/Manifest.toml: docs/Project.toml Project.toml
            \tjulia --project=docs -e 'using Pkg; Pkg.instantiate()'
            """)
        end

        let src = joinpath(tmp_root, "src")
            mkpath(src)
            open(joinpath(src, "$(name).jl"); write=true) do io
                write(io, "module $(name)\n\nend")
            end
        end

        let docs = joinpath(tmp_root, "docs")
            mkpath(docs)
            open(joinpath(docs, "Project.toml"); write=true) do io
                write(io, """
                [deps]
                Documenter = "e30172f5-a6a5-5a46-863b-614d45cd2de4"
                $(name) = "$(package_uuid)"

                [sources]
                $(name) = { path = ".." }
                """)
            end
            open(joinpath(docs, "make.jl"); write=true) do io
                write(io, make(name))
            end
            let docs_src = joinpath(docs, "src")
                mkpath(docs_src)
                open(joinpath(docs_src, "index.md"); write=true) do io
                    write(io, index(name))
                end
            end
        end

        if ispath(package_root)
            if force && isdir(package_root)
                @warn "Removing existing directory" package_root
                rm(package_root; recursive=true)
            else
                error("Something exists at: $(package_root)")
            end
        end
        @info "Generating $(name)" package_root
        mv(tmp_root, package_root)
    end

    return nothing
end

end

module DocumenterTools

using DocStringExtensions

export Travis

"""
    DocumenterTools.generate(path::String; name = nothing, format = :html)

Create a documentation stub in `path`, which is usually a sub folder in
the package root. The name of the package is determined automatically,
but can be given with the `name` keyword argument.

`generate` creates the following files in `path`:

```
.gitignore
src/index.md
make.jl
mkdocs.yml
Project.toml
```

# Arguments

**`path`** file path to the documentation directory.

# Keywords Arguments

**`name`** is the name of the package (without `.jl`). If `name` is not given
`generate` tries to detect it automatically.

**`format`** can be either `:html` (default), `:markdown` or `:pdf` corresponding
to the `format` keyword to Documenter's `makedocs` function, see
[Documenter's manual](https://juliadocs.github.io/Documenter.jl/latest/man/other-formats/).

# Examples
```julia-repl
julia> using DocumenterTools

julia> Documenter.generate("path/to/MyPackage/docs")
[ ... output ... ]
```
"""
function generate(path::AbstractString; name::Union{AbstractString,Nothing}=nothing,
                  format = :html)
    # TODO:
    #   - set up deployment to `gh-pages`
    #   - fetch url and username automatically (e.g from git remote.origin.url)

    if !(format in (:html, :markdown, :pdf))
        throw(ArgumentError("format `$(repr(format))` not supported."))
    end

    path = abspath(path)
    if isdir(path)
        throw(ArgumentError("directory `$(Base.contractuser(path))` already exists."))
    end

    # determine name of package unless it is given
    if name === nothing
        srcdir = normpath(joinpath(path, "..", "src"))
        candidates = String[]
        if isdir(srcdir)
            for file in readdir(srcdir)
                if isfile(joinpath(srcdir, file))
                    modulename = splitext(file)[1]
                    str = read(joinpath(srcdir, file), String)
                    i = findfirst(Regex("module\\s+" * modulename), str)
                    i !== nothing && push!(candidates, modulename)
                end
            end
        end
        if length(candidates) != 1 # || name === nothing
            throw(ArgumentError(string("could not determine name of package located ",
                "in `$(Base.contractuser(normpath(joinpath(path, ".."))))`. ",
                "Please specify the `name` keyword argument to `DocumenterTools.generate`.")))
        end
        name = candidates[1]
        @info("name of package automatically determined to be `$(name)`.")
    end
    @assert name !== nothing

    # deploy the stub
    try
        @info("deploying documentation to `$(Base.contractuser(path))`")
        mkdir(path)

        # create the root doc files
        Generator.savefile(path, ".gitignore") do io
            write(io, Generator.gitignore())
        end
        Generator.savefile(path, "make.jl") do io
            write(io, Generator.make(name; format = format))
        end
        if format === :markdown
            Generator.savefile(path, "mkdocs.yml") do io
                write(io, Generator.mkdocs(name))
            end
        end
        Generator.savefile(path, "Project.toml") do io
            write(io, Generator.project(; format = format))
        end

        # Create the default documentation source files
        Generator.savefile(path, "src/index.md") do io
            write(io, Generator.index(name))
        end
    catch
        rm(path, recursive=true)
        rethrow()
    end
    nothing
end

"""
    DocumenterTools.generate(pkg::Module; dir = "docs", format = :html)

Same as `generate(path::String)` but the `path` and name is determined
automatically from the module.

!!! note
    The package must be in development mode. Make sure you run
    `pkg> develop pkg` from the Pkg REPL, or `Pkg.develop(\"pkg\")`
    before generating docs.

# Examples
```julia-repl
julia> using DocumenterTools

julia> using MyPackage

julia> DocumenterTools.generate(MyPackage)
[ ... output ... ]
```
"""
function generate(pkg::Module; dir = "docs", format = :html)
    package_path = package_devpath(pkg)
    name = String(nameof(pkg))
    return generate(joinpath(package_path, dir); name = name, format = format)
end


"""
$(SIGNATURES)

Returns the path to the top level directory of a devved out package source tree. The package
is identified by its top level module `pkg`.
"""
function package_devpath(pkg::Module)
    pkg == parentmodule(pkg) || throw(ArgumentError("$(pkg) is a submodule. Use the package top-level module."))
    path = pathof(pkg)
    path === nothing && throw(ArgumentError("could not find path to $(pkg)."))
    name = String(nameof(pkg))

    # check that pkg is not originating from a standard installation directory
    # since those are supposed to be immutable.
    for depot in DEPOT_PATH
        sep = Sys.iswindows() ? "\\\\" : "/"
        if startswith(path, joinpath(depot, "packages", name)) &&
            occursin(Regex(name * sep * "\\w{4,5}" * sep * "src" * sep * name * ".jl"), path)
            throw(ArgumentError(string(
                "module $(name) was found in a standard installation directory. ",
                "Please make sure that $(name) is ready for development by running ",
                "`pkg> develop $(name)` from the Pkg REPL, or ",
                "`Pkg.develop(\"$(name)\")` from the Julia REPL, and try again.")))
        end
    end
    # We assume that the path to source file of pkg is ../Package/src/Package.jl, but we
    # return simply the top level directory of the package (i.e. ../Package)
    return normpath(joinpath(path, "..", ".."))
end

include("Travis.jl")
include("Generator.jl")

end # module

module DocumenterTools

using DocStringExtensions

export Travis

include("Travis.jl")
include("Generator.jl")

"""
$(SIGNATURES)

Creates a documentation stub for a package called `pkgname`. The location of
the documentation is assumed to be `<package directory>/docs`, but this can
be overriden with the keyword argument `dir`.

It creates the following files

```
docs/
    .gitignore
    src/index.md
    make.jl
    mkdocs.yml
```

# Arguments

**`pkgname`** is the name of the package (without `.jl`). It is used to
determine the location of the documentation if `dir` is not provided.

# Keywords

**`dir`** defines the directory where the documentation will be generated.
It defaults to `<package directory>/docs`. The directory must not exist.

# Examples

```julia-repl
julia> using DocumenterTools

julia> using MyPackage

julia> Documenter.generate(MyPackage)
[ ... output ... ]
```
"""
function generate(pkg::Module; dir=nothing)
    # TODO:
    #   - set up deployment to `gh-pages`
    #   - fetch url and username automatically (e.g from git remote.origin.url)

    # Assume the package name
    pkgname = string(pkg) * ".jl"
    # Determine the root directory where we wish to generate the docs and
    # check that it is a valid directory.
    docroot = if dir === nothing
        pkgdir = dirname(dirname(pathof(pkg)))
        if !isdir(pkgdir)
            error("Unable to find package $(pkgname).jl at $(pkgdir).")
        end
        joinpath(pkgdir, "docs")
    else
        dir
    end

    if ispath(docroot)
        error("Directory $(docroot) already exists.")
    end

    # deploy the stub
    try
        @info("Deploying documentation to $(docroot)")
        mkdir(docroot)

        # create the root doc files
        Generator.savefile(docroot, ".gitignore") do io
            write(io, Generator.gitignore())
        end
        Generator.savefile(docroot, "make.jl") do io
            write(io, Generator.make(pkgname))
        end
        Generator.savefile(docroot, "mkdocs.yml") do io
            write(io, Generator.mkdocs(pkgname))
        end

        # Create the default documentation source files
        Generator.savefile(docroot, "src/index.md") do io
            write(io, Generator.index(pkgname))
        end
    catch
        rm(docroot, recursive=true)
        rethrow()
    end
    nothing
end

end # module

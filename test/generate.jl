module GenerateTests

using DocumenterTools
using Test
using Pkg
using Example

@testset "Generate" begin
    function check_docdir(path; format)
        @test isdir(path)
        @test isfile(joinpath(path, "mkdocs.yml")) == (format === :markdown)
        @test isfile(joinpath(path, ".gitignore"))
        @test isfile(joinpath(path, "Project.toml"))
        @test isfile(joinpath(path, "make.jl"))
        @test isdir(joinpath(path, "src"))
        @test isfile(joinpath(path, "src", "index.md"))
    end
    mktempdir() do tmp; cd(tmp) do
        # generate from module argument
        Pkg.generate("Pkg1")
        Pkg.develop(PackageSpec(path = "Pkg1"))
        @eval using Pkg1
        DocumenterTools.generate(Pkg1; format = :html)
        check_docdir(joinpath("Pkg1", "docs"); format = :html)
        @test_throws ArgumentError DocumenterTools.generate(Pkg1)
        Pkg.rm(PackageSpec("Pkg1"))

        # generate from path
        Pkg.generate("Pkg2")
        DocumenterTools.generate(joinpath("Pkg2", "docs"); format = :markdown)
        check_docdir(joinpath("Pkg2", "docs"); format = :markdown)
        @test_throws ArgumentError DocumenterTools.generate(joinpath("Pkg2", "docs"))

        # generate where name can't be determined
        mkdir("Pkg3")
        @test_throws ArgumentError DocumenterTools.generate(joinpath("Pkg3", "docs"))
        mkdir(joinpath("Pkg3", "src"))
        @test_throws ArgumentError DocumenterTools.generate(joinpath("Pkg3", "docs"))
        write(joinpath("Pkg3", "src", "Pkg3.jl"), "module Pkg3\nend\n")
        write(joinpath("Pkg3", "src", "Pkg4.jl"), "module Pkg4\nend\n")
        @test_throws ArgumentError DocumenterTools.generate(joinpath("Pkg3", "docs"))
        DocumenterTools.generate(joinpath("Pkg3", "docs"); name = "Pkg3", format = :pdf)
        check_docdir(joinpath("Pkg3", "docs"), format = :pdf)

        # throw for a package that is installed and not deved
        @test_throws ArgumentError DocumenterTools.generate(Example)

        # throw for a submodule
        @test_throws ArgumentError DocumenterTools.generate(Broadcast)
    end; end
end

end

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
        mod = Module()
        @eval mod using Pkg1, DocumenterTools
        @test_logs (:info, r"deploying documentation to") (:info, r"Generating \.gitignore") (:info, r"Generating make\.jl") (:info, r"Generating Project\.toml") (:info, r"Generating src/index\.md") @eval mod DocumenterTools.generate(Pkg1; format = :html)
        check_docdir(joinpath("Pkg1", "docs"); format = :html)
        @test_throws ArgumentError @eval mod DocumenterTools.generate(Pkg1)
        Pkg.rm(PackageSpec("Pkg1"))

        # generate from path
        Pkg.generate("Pkg2")
        @test_logs (:info, r"name of package automatically determined to be") (:info, r"deploying documentation to") (:info, r"Generating \.gitignore") (:info, r"Generating make\.jl") (:info, r"Generating mkdocs\.yml") (:info, r"Generating Project\.toml") (:info, r"Generating src/index\.md") DocumenterTools.generate(joinpath("Pkg2", "docs"); format = :markdown)
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
        @test_logs (:info, r"deploying documentation to") (:info, r"Generating \.gitignore") (:info, r"Generating make\.jl") (:info, r"Generating Project\.toml") (:info, r"Generating src/index\.md") DocumenterTools.generate(joinpath("Pkg3", "docs"); name = "Pkg3", format = :pdf)
        check_docdir(joinpath("Pkg3", "docs"), format = :pdf)

        # throw for a package that is installed and not deved
        @test_throws ArgumentError DocumenterTools.generate(Example)

        # throw for a submodule
        @test_throws ArgumentError DocumenterTools.generate(Broadcast)
    end; end
end

end

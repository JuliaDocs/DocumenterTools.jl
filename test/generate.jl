module GenerateTests

using Test
using DocumenterTools
import Random: randstring

@testset "Generate" begin
    mktempdir() do root
        let path = joinpath(root, "docs")
            DocumenterTools.generate(DocumenterTools, dir = path)
            @test isdir(path)
            @test isfile(joinpath(path, "mkdocs.yml"))
            @test isfile(joinpath(path, ".gitignore"))
            @test isfile(joinpath(path, "make.jl"))
            @test isdir(joinpath(path, "src"))
            @test isfile(joinpath(path, "src", "index.md"))
        end
    end

    # TODO: these tests should be reviewed. DocumenterTools.generate() does not really
    # support Pkg3 / Julia 0.7 at the moment.
    @test_throws ErrorException DocumenterTools.generate(DocumenterTools)
end

end

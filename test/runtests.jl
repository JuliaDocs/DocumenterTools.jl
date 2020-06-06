using Test
using DocumenterTools

@testset "DocumenterTools" begin
    @testset "generate" begin
        include("generate.jl")
    end
end

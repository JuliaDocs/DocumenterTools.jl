using Test
using DocumenterTools
import Documenter

@testset "DocumenterTools" begin
    @testset "generate" begin
        include("generate.jl")
    end

    @testset "genkeys-added" begin
        using Example
        DocumenterTools.genkeys(user="JuliaLang", repo="git@github.com:JuliaLang/Example.jl.git")
    end

    @testset "genkeys-deved" begin
        import Pkg
        # It's unlikely that Revise will ever enter our dependency graph
        Pkg.develop("Revise")
        import Revise
        DocumenterTools.genkeys(Revise)
    end

    @testset "outdated warnings" begin
        include("outdated.jl")
    end

    Documenter.doctest(nothing, [DocumenterTools])
end

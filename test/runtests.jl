using Test
using DocumenterTools
import Documenter

@testset "DocumenterTools" begin
    @testset "generate" begin
        include("generate.jl")
    end

    @testset "genkeys-added" begin
        using Example
        @test_logs (:info, r"Add the key below") (:info, r"Add a secure 'Repository secret' named 'DOCUMENTER_KEY'") DocumenterTools.genkeys(user="JuliaLang", repo="git@github.com:JuliaLang/Example.jl.git", io=devnull)
    end

    @testset "genkeys-deved" begin
        import Pkg
        # It's unlikely that Revise will ever enter our dependency graph
        Pkg.develop("Revise")
        import Revise
        @test_logs (:info, r"Add the key below") (:info, r"Add a secure 'Repository secret' named 'DOCUMENTER_KEY'") DocumenterTools.genkeys(Revise; io=devnull)
    end

    @testset "outdated warnings" begin
        include("outdated.jl")
    end

    @test_logs (:info, r"SetupBuildDirectory") (:info, r"Doctest") (:info, r"Skipped ExpandTemplates step") (:info, r"Skipped CrossReferences step") (:info, r"Skipped CheckDocument step") (:info, r"Skipped Populate step") (:info, r"Skipped RenderDocument step") Documenter.doctest(nothing, [DocumenterTools])
end

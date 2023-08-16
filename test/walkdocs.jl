let fileinfos = []
    rs = DocumenterTools.walkdocs(joinpath(@__DIR__, "fixtures")) do fileinfo
        push!(fileinfos, fileinfo)

        @test isabspath(fileinfo.root)
        @test isabspath(fileinfo.fullpath)
        @test !isabspath(fileinfo.relpath)
        @test joinpath(fileinfo.root, fileinfo.relpath) == fileinfo.fullpath
    end
    @test rs === nothing
    @test length(fileinfos) == 10
end

let rs = DocumenterTools.walkdocs(joinpath(@__DIR__, "fixtures"), collect=true) do fileinfo
        fileinfo.root
    end
    @test length(rs) == 10
    @test all(s -> isa(s, String), rs)
end

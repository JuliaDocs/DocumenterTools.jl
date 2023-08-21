mktempdir() do TMP
    cp(joinpath(@__DIR__, "fixtures"), joinpath(TMP, "fixtures"))
    chmod(joinpath(TMP, "fixtures"), 0o777, recursive=true)

    index_changed = joinpath(TMP, "fixtures", "index_changed.html")
    cp(joinpath(TMP, "fixtures", "index.html"), index_changed, force=true)
    OutdatedWarning.add_old_docs_notice(index_changed)
    output = read(index_changed, String)

    @test occursin("data-outdated-warner", output)
    # The following is sensitive to how Gumbo.jl writes HTML, but let's hope that doesn't change often:
    @test replace(output, "\r\n" => "\n") == replace(read(joinpath(@__DIR__, "fixtures", "index_after.html"), String), "\r\n" => "\n")


    transient_path = joinpath(TMP, "fixtures", "transient")
    cp(joinpath(TMP, "fixtures", "pre"), transient_path, force=true)
    OutdatedWarning.generate(transient_path)

    DocumenterTools.walkdocs(transient_path) do fileinfo
        content = read(fileinfo.fullpath, String)
        expected = read(
            joinpath(replace(dirname(fileinfo.fullpath), "transient" => "post"), fileinfo.filename),
            String
        )
        @test replace(content, "\r\n" => "\n") == replace(expected, "\r\n" => "\n")
    end

    rm(joinpath(TMP, "fixtures"), recursive=true)
end

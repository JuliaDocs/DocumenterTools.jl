index_changed = joinpath(@__DIR__, "fixtures", "index_changed.html")
cp(joinpath(@__DIR__, "fixtures", "index.html"), index_changed, force=true)
OutdatedWarning.add_old_docs_notice(index_changed)
output = read(index_changed, String)

@test occursin("data-outdated-warner", output)
# The following is sensitive to how Gumbo.jl writes HTML, but let's hope that doesn't change often:
@test replace(output, "\r\n" => "\n") == replace(read(joinpath(@__DIR__, "fixtures", "index_after.html"), String), "\r\n" => "\n")

rm(index_changed)


transient_path = joinpath(@__DIR__, "fixtures", "transient")
cp(joinpath(@__DIR__, "fixtures", "pre"), transient_path, force=true)
OutdatedWarning.generate(transient_path)

for (root, _, files) in walkdir(transient_path)
    for file in files
        content = read(joinpath(root, file), String)
        expected = read(joinpath(replace(root, "transient" => "post"), file), String)
        @test replace(content, "\r\n" => "\n") == replace(expected, "\r\n" => "\n")
    end
end

rm(transient_path, recursive=true)
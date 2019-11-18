"""
The [`Themes`](@ref) module contains APIs to more easily compile the Documenter Sass themes
into CSS files.

To compile an Sass file into a Documenter theme, you can use the [`Themes.compile`]
function:

```julia-repl
julia> using DocumenterTools: Themes

julia> Themes.compile("mytheme.scss")
```

When working on the Documenter built-in themes, the [`Themes.themewatcher`](@ref) function
can be used to automatically update all the built-in themes when any of the Sass files are
modified. To enable it, just run

```julia-repl
julia> using DocumenterTools: Themes

julia> Themes.themewatcher()
```

Note that it will read and overwrite the Sass and CSS files of the Documenter of the
environment DocumenterTools is loaded in — make sure that you have Documenter added as a
development dependency to that environment.
"""
module Themes
using FileWatching
using Documenter.Writers: HTMLWriter
using Sass

"""
    compile(src[, dst])

Compile an input Sass/SCSS file `src` into a CSS file. The standard Documenter Sass/SCSS
files are available in the include path.

The optional `dst` argument can be used to specify the output file. Otherwise, the file
extension of the `src` file is simply replaced by `.css`.
"""
function compile(src, dst=nothing)
    isfile(src) || error("$name not at $src")
    if dst === nothing
        s = (endswith(src, ".scss") || endswith(src, ".sass")) ? first(splitext(src)) : src
        dst = "$(s).css"
    end
    Sass.compile_file(src, dst; include_paths=HTMLWriter.ASSETS_SASS)
end

"""
    compile_native_theme(name; dst=nothing)

Compiles a native Documenter theme and places it into Documenter's assets directory.

Optionally, the `dst` keyword argument can be used to specify the output file.
"""
function compile_native_theme(name; dst = nothing)
    name in HTMLWriter.THEMES || error("Bad theme name. Valid themes: $(HTMLWriter.THEMES)")
    src = joinpath(HTMLWriter.ASSETS_SASS, "$(name).scss")
    dst = (dst === nothing) ? joinpath(HTMLWriter.ASSETS_THEMES, "$(name).css") : dst
    compile(src, dst)
    return dst
end

function compile_native_themes()
    for theme in HTMLWriter.THEMES
        compile_native_theme(theme)
    end
end


# themewatcher() watches the Documenter theme source SCSS/Sass files and recompiles
# the native themes if there are any changes
const compiler_channel = Channel{Any}(1024)
const tasks = Vector{Tuple{Task,Channel{Any}}}()

themewatcher(; kwargs...) = isempty(tasks) ?
    themewatcher_start(; kwargs...) : themewatcher_stop(; kwargs...)

function themewatcher_start(; dst=nothing, kwargs...)
    # Start the compiler task
    t = @async compiler(compiler_channel; dst=dst)
    push!(tasks, (t, compiler_channel))
    # Start watchers on all theme subdirectories
    for directory in all_subdirectories(HTMLWriter.ASSETS_SASS)
        start_watcher(directory)
    end
end

function themewatcher_stop(; kwargs...)
    # Send stop messages to all tasks
    for (_, c) in tasks
        put!(c, false)
    end
    # Wait for all of the tasks to finish
    for (t, _) in tasks
        try
            wait(t)
        catch e
            @warn "Task $t failed with exception" e
        end
    end
    # clear out the task list
    empty!(tasks)
    # clear out the compiler_channel channel
    while isready(compiler_channel)
        take!(compiler_channel)
    end
end

function all_subdirectories(d)
    vcat(d, mapreduce(vcat, walkdir(d)) do (root, dirs, _)
        [joinpath(root, d) for d in dirs]
    end)
end

function start_watcher(directory)
    channel = Channel{Any}(32)
    task = @async watcher(channel, directory, compiler_channel)
    push!(tasks, (task, channel))
end

function watcher(channel, directory, compiler_channel)
    @info "Starting watcher for: $(directory)"
    while true
        (f, reason) = watch_folder(directory, 2)
        if reason.changed
            @info "Change detected: $(f)" directory
            if endswith(f, ".scss") || endswith(f, ".sass")
                put!(compiler_channel, true)
            else
                @info "Ignoring $(f) -- not Sass"
            end
        end
        if isready(channel)
            @info "Received message, exiting watcher." directory take!(channel)
            return
        end
    end
end

function compiler(compiler_channel; dst=nothing)
    @info "Starting Sass compiler task." dst
    while true
        sleep(1)
        if isready(compiler_channel)
            @info "Received messages to compiler."
            while isready(compiler_channel)
                msg = take!(compiler_channel)
                if !msg
                    @info "Exiting compiler."
                    return
                end
            end
            for theme in HTMLWriter.THEMES
                @info "Compiling: $(theme)"
                _dst = nothing
                if dst !== nothing
                    _dst = joinpath(dst, "$(theme).css")
                end
                try
                    compile_native_theme(theme; dst=_dst)
                catch e
                    @warn "Compilation of $(theme) failed" e
                end
            end
        end
    end
end

end

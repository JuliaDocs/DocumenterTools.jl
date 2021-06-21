export OutdatedWarning

module OutdatedWarning
using Gumbo, AbstractTrees, Documenter

OLD_VERSION_CSS = replace("""
.outdated-warning-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.3);
  z-index: 999;
  background-color: #ffaba7;
  color: rgba(0, 0, 0, 0.7);
  border-bottom: 3px solid #da0b00;
  padding: 10px 35px;
  text-align: center;
  font-size: 15px; }
  .outdated-warning-overlay .outdated-warning-closer {
    position: absolute;
    top: calc(50% - 10px);
    right: 18px;
    cursor: pointer;
    width: 12px; }
  .outdated-warning-overlay a {
    color: #2e63b8; }
    .outdated-warning-overlay a:hover {
      color: #363636; }
""", '\n' => "")

OUTDATED_VERSION_ATTR = isdefined(Documenter.Writers.HTMLWriter, :OUTDATED_VERSION_ATTR) ?
    Documenter.Writers.HTMLWriter.OUTDATED_VERSION_ATTR : "data-outdated-warner"

OLD_VERSION_WARNER = """
function maybeAddWarning () {
    const head = document.getElementsByTagName('head')[0];

    // Add a noindex meta tag (unless one exists) so that search engines don't index this version of the docs.
    if (document.body.querySelector('meta[name="robots"]') === null) {
        const meta = document.createElement('meta');
        meta.name = 'robots';
        meta.content = 'noindex';

        head.appendChild(meta);
    };

    // Add a stylesheet to avoid inline styling
    const style = document.createElement('style');
    style.type = 'text/css';
    style.appendChild(document.createTextNode('$(OLD_VERSION_CSS)'));
    head.appendChild(style);

    const div = document.createElement('div');
    div.classList.add('outdated-warning-overlay');
    const closer = document.createElement('div');
    closer.classList.add('outdated-warning-closer');

    // Icon by font-awesome (license: https://fontawesome.com/license, link: https://fontawesome.com/icons/times?style=solid)
    closer.innerHTML = '<svg aria-hidden="true" focusable="false" data-prefix="fas" data-icon="times" class="svg-inline--fa fa-times fa-w-11" role="img" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 352 512"><path fill="currentColor" d="M242.72 256l100.07-100.07c12.28-12.28 12.28-32.19 0-44.48l-22.24-22.24c-12.28-12.28-32.19-12.28-44.48 0L176 189.28 75.93 89.21c-12.28-12.28-32.19-12.28-44.48 0L9.21 111.45c-12.28 12.28-12.28 32.19 0 44.48L109.28 256 9.21 356.07c-12.28 12.28-12.28 32.19 0 44.48l22.24 22.24c12.28 12.28 32.2 12.28 44.48 0L176 322.72l100.07 100.07c12.28 12.28 32.2 12.28 44.48 0l22.24-22.24c12.28-12.28 12.28-32.19 0-44.48L242.72 256z"></path></svg>';
    closer.addEventListener('click', function () {
        document.body.removeChild(div);
    });
    let href = '/stable';
    if (window.documenterBaseURL) {
        href = window.documenterBaseURL + '/../stable';
    }
    div.innerHTML = 'This documentation is not for the latest version. <br> <a href="' + href + '">Go to the latest documentation</a>.';
    div.appendChild(closer);
    document.body.appendChild(div);
};

if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', maybeAddWarning);
} else {
    maybeAddWarning();
};
"""

function add_old_docs_notice(index, force = false)
    html = read(index, String)
    parsed = Gumbo.parsehtml(html)

    did_update = false
    for el in PreOrderDFS(parsed.root)
        if el isa HTMLElement && Gumbo.tag(el) == :head
            old_notice = get_notice(el)

            if old_notice === nothing
                push!(el.children, make_notice(el))
                did_update = true
            elseif force
                update_notice(old_notice)
                did_update = true
            end

            break
        end
    end

    if did_update
        open(index, "w") do io
            print(io, parsed)
        end
    end
    return did_update
end

function make_notice(parent)
    script = Gumbo.HTMLElement{:script}([], parent, Dict(OUTDATED_VERSION_ATTR => ""))
    content = Gumbo.HTMLText(script, OLD_VERSION_WARNER)
    push!(script.children, content)
    return script
end

function update_notice(script)
    content = Gumbo.HTMLText(script, OLD_VERSION_WARNER)
    empty!(script.children)
    push!(script.children, content)
    return script
end

function get_notice(html)
    for el in PreOrderDFS(html)
        if el isa HTMLElement && Gumbo.tag(el) == :script
            attrs = Gumbo.attrs(el)
            if haskey(attrs, OUTDATED_VERSION_ATTR)
                return el
            end
        end
    end
    return nothing
end

"""
    generate([io::IO = stdout,] root::String;force = false)

This function adds a (nonconditional) warning (and `noindex` meta tag) to all
versions of the documentation in `root`.

`force` overwrites a previous injected warning message created by this function.

A typical use case is to run this on the `gh-pages` branch of a package. Make sure
you review which changes you check in if you are *not* tagging a new release
of your package's documentation at the same time.
"""
generate(root::String; kwargs...) = generate(stdout, root; kwargs...)
function generate(io::IO, root::String;force = false)
    for dir in readdir(root)
        path = joinpath(root, dir)
        islink(path) && continue
        isdir(path) || continue
        index = joinpath(path, "index.html")
        isfile(index) || continue

        if endswith(path, "dev")
            println(io, "Skipping $(dir) since it's a dev version.")
            continue
        end

        print(io, "Processing $(dir): ")
        for (root, _, files) in walkdir(path)
            for file in files
                _, ext = splitext(file)
                if ext == ".html"
                    try
                        did_change = add_old_docs_notice(joinpath(root, file), force)
                        print(io, did_change ? "✓" : ".")
                    catch err
                        if err isa InterruptException
                            rethrow()
                        end
                        @debug "Fatally failed to add a outdated warning" exception = (err, catch_backtrace())
                        print(io, "!")
                    end
                end
            end
        end
        println(io)
    end
end

end

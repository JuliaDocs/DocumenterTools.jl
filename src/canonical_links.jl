"""
    DocumenterTools.update_canonical_links_for_build(
        docs_directory::AbstractString;
        canonical::AbstractString,
    )

- **`canonical`**: corresponds to the `canonical` attribute of `Documenter.HTML`,
  specifying the root of the canonical URL.
"""
function update_canonical_links_for_version(
        docs_directory::AbstractString;
        canonical::AbstractString
    )
    canonical = rstrip(canonical, '/')

    walkdocs(docs_directory) do fileinfo
        @debug "update_canonical_links: checking $(fileinfo.relpath)"
        # Determine the
        filepath = splitpath(fileinfo.relpath)
        new_canonical_href = if filepath[end] == "index.html"
            joinurl(canonical, filepath[1:end-1]...) * '/'
        else
            joinurl(canonical, filepath[1:end]...)
        end

        html = Gumbo.parsehtml(read(fileinfo.fullpath, String))
        n_canonical_tags::Int = 0
        dom_updated::Bool = false
        for e in AbstractTrees.PreOrderDFS(html.root)
            is_canonical_element(e) || continue
            n_canonical_tags += 1
            canonical_href = Gumbo.getattr(e, "href", nothing)
            if canonical_href != new_canonical_href
                Gumbo.setattr!(e, "href", new_canonical_href)
                @warn "canonical_href updated" canonical_href new_canonical_href fileinfo.relpath
                dom_updated = true
            end
        end
        if n_canonical_tags == 0
            for e in AbstractTrees.PreOrderDFS(html.root)
                e isa Gumbo.HTMLElement || continue
                Gumbo.tag(e) == :head || continue
                canonical_href_element = Gumbo.HTMLElement{:link}(
                    [], e, Dict(
                        "rel" => "canonical",
                        "href" => new_canonical_href,
                    )
                )
                push!(e.children, canonical_href_element)
                @warn "Added new canonical_href" new_canonical_href fileinfo.relpath
                dom_updated = true
                break
            end
        end
        if dom_updated
            open(io -> print(io, html), fileinfo.fullpath, "w")
        end
        if n_canonical_tags > 1
            @error "Multiple canonical tags!" file = fileinfo.relpath
        end
    end
end

is_canonical_element(e) = (e isa Gumbo.HTMLElement) && (Gumbo.tag(e) == :link) && (Gumbo.getattr(e, "rel", nothing) == "canonical")
joinurl(ps::AbstractString...) = join(ps, '/')

function update_canonical_links(
        docs_directory::AbstractString;
        canonical::AbstractString
    )
    canonical = rstrip(canonical, '/')
    docs_directory = abspath(docs_directory)
    isdir(docs_directory) || throw(ArgumentError("No such directory: $(docs_directory)"))

    # Try to extract the list of versions from versions.js
    versions_js = joinpath(docs_directory, "versions.js")
    isfile(versions_js) || throw(ArgumentError("versions.js is missing in $(docs_directory)"))
    versions = map(extract_versions_list(versions_js)) do version_str
        isversion, version_number = if occursin(Base.VERSION_REGEX, version_str)
            true, VersionNumber(version_str)
        else
            false, nothing
        end
        fullpath = joinpath(docs_directory, version_str)
        return (;
            path = version_str,
            path_exists = isdir(fullpath) || islink(fullpath),
            symlink = islink(fullpath),
            isversion,
            version_number,
            fullpath,
        )
    end
    # We'll filter out a couple of potential bad cases and issue warnings
    filter(versions) do vi
        if !vi.path_exists
            @warn "update_canonical_links: path does not exists or is not a directory" docs_directory vi
            return false
        end
        return true
    end
    # We need to determine the canonical path. This would usually be something like the stable/
    # directory, but it can have a different name, including being a version number. So first we
    # try to find a non-version directory _that is a symlink_ (so that it wouldn't get confused)
    # previews/ or dev builds. If that fails, we try to find the directory matching `v[0-9]+`,
    # with the highest version number. This does not cover all possible cases, but should be good
    # enough for now.
    #
    # TODO: we could also try to parse the canonical URL from the index.html, and only fall
    # back to versions.js when the canonical URL is not present.
    non_version_symlinks = filter(vi -> !vi.isversion && vi.symlink, versions)
    canonical_version = if isempty(non_version_symlinks)
        # We didn't find any non-version symlinks, so we'll try to find the vN directory now
        # as a fallback.
        version_symlinks = map(versions) do vi
            if !(vi.symlink && vi.isversion)
                return nothing
            end
            m = match(r"^([0-9]+)$", vi.path)
            isnothing(m) && return nothing
            parse(Int, m[1]) => vi
        end
        filter!(!isnothing, version_symlinks)
        if isempty(version_symlinks)
            error("Unable to determine the canonical path. Found no version directories")
        end
        _, idx = findmax(first, version_symlinks)
        version_symlinks[idx][2]
    elseif length(non_version_symlinks) > 1
        error("Unable to determine the canonical path. Found multiple non-version symlinks.\n$(non_version_symlinks)")
    else
        only(non_version_symlinks)
    end
    canonical_full_root = joinurl(canonical, canonical_version.path)
    # If we have determined which version should be the canonical version, we can actually
    # go and run update_canonical_links_for_version on each directory.
    for filename in readdir(docs_directory)
        path = joinpath(docs_directory, filename)
        # We'll skip all files. This includes files such as index.html, which in this
        # directory will likely be the redirect. Also, links should be pointing to other
        # versions, so we'll skip them too.
        if islink(path) || !isdir(path)
            continue
        end
        # For true directories, we check that siteinfo.js file is present, which is a pretty
        # good indicator that it's a proper Documenter build.
        if !isfile(joinpath(path, "siteinfo.js"))
            # We want to warn if we run across any directories that are not Documenter builds.
            # But previews/ is one valid case which may be present and so we shouldn't warn
            # for this one.
            if filename != "previews"
                @warn "update_canonical_links: skipping directory that does not look like a Documenter build" filename docs_directory
            end
            continue
        end
        # Finally, we can run update_canonical_links_for_version on the directory.
        @info "Updating canonical URLs for" docs_directory filename canonical_full_root
        update_canonical_links_for_version(path; canonical = canonical_full_root)
    end
end

function extract_versions_list(versions_js::AbstractString)
    versions_js = abspath(versions_js)
    isfile(versions_js) || throw(ArgumentError("No such file: $(versions_js)"))
    versions_js_content = read(versions_js, String)
    m = match(r"var\s+DOC_VERSIONS\s*=\s*\[([0-9A-Za-z\"\s.,+-]+)\]", versions_js_content)
    if isnothing(m)
        throw(ArgumentError("""
        Could not find DOC_VERSIONS in $(versions_js):
        $(versions_js_content)"""))
    end
    versions = strip.(c -> isspace(c) || (c == '"'), split(m[1], ","))
    filter!(!isempty, versions)
    if isempty(versions)
        throw(ArgumentError("""
        DOC_VERSIONS empty in $(versions_js):
        $(versions_js_content)"""))
    end
    return versions
end

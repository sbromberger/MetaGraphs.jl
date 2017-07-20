using Documenter, MetaGraphs

# index is equal to the README for the time being
cp(normpath(@__FILE__, "../../README.md"), normpath(@__FILE__, "../src/index.md"); remove_destination=true)

# same for license
cp(normpath(@__FILE__, "../../LICENSE.md"), normpath(@__FILE__, "../src/license.md"); remove_destination=true)

makedocs(
    modules = [MetaGraphs],
    format = :html,
    sitename = "MetaGraphs",
    pages    = Any[
        "Overview"             => "index.md",
        "MetaGraphs Functions" => "metagraphs.md",
        "License Information"  => "license.md"
    ]
)

deploydocs(
    deps=nothing,
    make=nothing,
    repo="github.com/JuliaGraphs/MetaGraphs.jl.git",
    target="build",
    julia="0.6",
    osname = "linux"
)
    
rm(normpath(@__FILE__, "../src/index.md"))
rm(normpath(@__FILE__, "../src/license.md"))

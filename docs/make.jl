using Documenter
include("../src/MetaGraphs.jl")

cp(normpath(@__FILE__, "../../README.md"), normpath(@__FILE__, "../src/index.md"); remove_destination=true)

cp(normpath(@__FILE__, "../../LICENSE.md"), normpath(@__FILE__, "../src/license.md"); remove_destination=true)

makedocs(
    sitename = "MetaGraphs.jl",
    modules = [MetaGraphs],
    format = :html,
    clean = false,
    pages = Any["Home" => "index.md"],
)

deploydocs(
    target = "build",
    deps = Deps.pip("pygments", "mkdocs", "mkdocs-material", "python-markdown-math"),
    make = nothing,
    repo = "github.com/JuliaGraphs/MetaGraphs.jl.git",
    julia  = "0.6"
)

rm(normpath(@__FILE__, "../src/index.md"))
rm(normpath(@__FILE__, "../src/license.md"))

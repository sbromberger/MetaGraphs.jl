using Documenter
include("../src/MetaGraphs.jl")
using MetaGraphs

# index is equal to the README for the time being
cp(normpath(@__FILE__, "../../README.md"), normpath(@__FILE__, "../src/index.md"); remove_destination=true)

# same for license
cp(normpath(@__FILE__, "../../LICENSE.md"), normpath(@__FILE__, "../src/license.md"); remove_destination=true)

makedocs(modules=[MetaGraphs], doctest = false)


deploydocs(
    deps = Deps.pip("pygments", "mkdocs", "mkdocs-material", "python-markdown-math"),
    repo   = "github.com/JuliaGraphs/MetaGraphs.jl.git",
    julia  = "0.6"
)

rm(normpath(@__FILE__, "../src/index.md"))
rm(normpath(@__FILE__, "../src/license.md"))

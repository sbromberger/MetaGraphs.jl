using LightGraphs
using MetaGraphs
using Test

import LightGraphs.SimpleGraphs: SimpleGraph, SimpleDiGraph
testdir = dirname(@__FILE__)

testgraphs(g) = [g, SimpleGraph{UInt8}(g), SimpleGraph{Int16}(g)]
testdigraphs(g) = [g, SimpleDiGraph{UInt8}(g), SimpleDiGraph{Int16}(g)]

tests = [
    "metagraphs",
    "overrides",
    "persistence",
    "dotformat"
]

@testset "MetaGraphs" begin
    for t in tests
        tp = joinpath(testdir, "$(t).jl")
        include(tp)
    end
end

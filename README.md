# MetaGraphs

[![Build Status](https://travis-ci.org/JuliaGraphs/MetaGraphs.jl.svg?branch=master)](https://travis-ci.org/JuliaGraphs/MetaGraphs.jl)
[![codecov.io](http://codecov.io/github/JuliaGraphs/MetaGraphs.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaGraphs/MetaGraphs.jl?branch=master)
[![](https://img.shields.io/badge/docs-latest-blue.svg)](https://juliagraphs.github.io/MetaGraphs.jl/latest)

[LightGraphs.jl](https://github.com/JuliaGraphs/LightGraphs.jl) graphs with arbitrary metadata.

## Documentation
Full documentation is available at [GitHub Pages](https://juliagraphs.github.io/MetaGraphs.jl/latest).
Documentation for methods is also available via the Julia REPL help system.

## Compatibility
We have recently made a large, breaking change to `MetaGraphs`. The metadata at
vertices and edges is now type stable (although you can still attach
type-unstable data by setting `AtEdge` or `AtVertex` to `Any`).

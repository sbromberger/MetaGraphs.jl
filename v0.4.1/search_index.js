var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Overview",
    "title": "Overview",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#MetaGraphs-1",
    "page": "Overview",
    "title": "MetaGraphs",
    "category": "section",
    "text": "(Image: Build Status) (Image: codecov.io) (Image: )LightGraphs.jl graphs with arbitrary metadata."
},

{
    "location": "index.html#Documentation-1",
    "page": "Overview",
    "title": "Documentation",
    "category": "section",
    "text": "Full documentation is available at GitHub Pages. Documentation for methods is also available via the Julia REPL help system."
},

{
    "location": "index.html#Installation-1",
    "page": "Overview",
    "title": "Installation",
    "category": "section",
    "text": "Installation is straightforward:julia> Pkg.add(\"MetaGraphs\")"
},

{
    "location": "index.html#Example-Usage-1",
    "page": "Overview",
    "title": "Example Usage",
    "category": "section",
    "text": "julia> using LightGraphs, MetaGraphs\n\n# create a standard simplegraph\njulia> g = PathGraph(5)\n{5, 4} undirected simple Int64 graph\n\n# create a metagraph based on the simplegraph, with optional default edgeweight\njulia> mg = MetaGraph(g, 3.0)\n{5, 4} undirected Int64 metagraph with Float64 weights defined by :weight (default weight 3.0)\n\n# set some properties for the graph itself\njulia> set_prop!(mg, :description, \"This is a metagraph.\")\nDict{Symbol,Any} with 1 entry:\n  :description => \"This is a metagraph.\"\n\n# set properties on a vertex in bulk\njulia> set_props!(mg, 1, Dict(:name=>\"Susan\", :id => 123))\nDict{Symbol,Any} with 2 entries:\n  :id   => 123\n  :name => \"Susan\"\n\n# set individual properties\njulia> set_prop!(mg, 2, :name, \"John\")\nDict{Symbol,String} with 1 entry:\n  :name => \"John\"\n\n# set a property on an edge\njulia> set_prop!(mg, Edge(1, 2), :action, \"knows\")\nDict{Symbol,String} with 1 entry:\n  :action => \"knows\"\n\n# set another property on an edge by specifying source and destination\njulia> set_prop!(mg, 1, 2, :since, Date(\"20170501\", \"yyyymmdd\"))\nDict{Symbol,Any} with 2 entries:\n  :since   => 2017-05-01\n  :action => \"knows\"\n\n# get all the properties for an element\njulia> props(mg, 1)\nDict{Symbol,Any} with 2 entries:\n  :id   => 123\n  :name => \"Susan\"\n\n# get a specific property by name\njulia> get_prop(mg, 2, :name)\n\"John\"\n\n# delete a specific property\njulia> rem_prop!(mg, 1, :name)\nDict{Symbol,Any} with 1 entry:\n  :id => 123\n\n# clear all properties for vertex 2\njulia> clear_props!(mg, 2)\nDict{Symbol,Any} with 0 entries\n\n# confirm there are no properties set for vertex 2\njulia> props(mg, 2)\nDict{Symbol,Any} with 0 entries\n\n# all LightGraphs analytics work\njulia> betweenness_centrality(mg)\n5-element Array{Float64,1}:\n 0.0\n 0.5\n 0.666667\n 0.5\n 0.0\n\n# using weights\njulia> mg = MetaGraph(CompleteGraph(3))\n{3, 3} undirected Int64 metagraph with Float64 weights defined by :weight (default weight 1.0)\n\njulia> enumerate_paths(dijkstra_shortest_paths(mg, 1), 3)\n2-element Array{Int64,1}:\n 1\n 3\n\njulia> set_prop!(mg, 1, 2, :weight, 0.2)\nDict{Symbol,Float64} with 1 entry:\n  :weight => 0.2\n\njulia> set_prop!(mg, 2, 3, :weight, 0.6)\nDict{Symbol,Float64} with 1 entry:\n  :weight => 0.6\n\njulia> enumerate_paths(dijkstra_shortest_paths(mg, 1), 3)\n3-element Array{Int64,1}:\n 1\n 2\n 3\n\n# use vertex values as indices\njulia> G = MetaGraph(100)\n{100, 0} undirected Int64 metagraph with Float64 weights defined by :weight (default weight 1.0)\n\njulia> for i in 1:100\n           set_prop!(G, i, :name, \"node$i\")\n       end\n\njulia> set_indexing_prop!(G, :name)\nSet(Symbol[:name])\n\n# nodes can now be found by the value in the index\njulia> G[\"node4\", :name]\n4\n\n# You can also find the value of an index by the vertex number (note, this behavior will dominate if index values are also integers)\njulia> G[4, :name]\n\"node4\"\n\njulia> set_prop!(G, 3, :name, \"name3\")\nERROR: \':name\' is an indexing property, use `set_indexing_prop!()` instead"
},

{
    "location": "metagraphs.html#",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs Functions",
    "category": "page",
    "text": ""
},

{
    "location": "metagraphs.html#MetaGraphs.clear_props!-Tuple{MetaGraphs.AbstractMetaGraph,Integer}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.clear_props!",
    "category": "method",
    "text": "clear_props!(g)\nclear_props!(g, v)\nclear_props!(g, e)\nclear_props!(g, s, d)\n\nRemove all defined properties from graph g, vertex v, or edge e (optionally referenced by source vertex s and destination vertex d).\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.defaultweight!-Tuple{MetaGraphs.AbstractMetaGraph,Real}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.defaultweight!",
    "category": "method",
    "text": "defaultweight!(g, weight)\n\nSet the default weight for metagraph g\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.defaultweight-Tuple{MetaGraphs.AbstractMetaGraph}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.defaultweight",
    "category": "method",
    "text": "defaultweight(g)\n\nReturn the default weight for metagraph g.\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.filter_edges-Tuple{MetaGraphs.AbstractMetaGraph,Function}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.filter_edges",
    "category": "method",
    "text": "filter_edges(g, prop[, val])\nfilter_edges(g, fn)\n\nReturn an iterator to all edges that have property prop defined (optionally as val), or where function fn returns true only for edges that should be included in the iterator.\n\nfn should be of the form\n\nfn(g::AbstractMetaGraph{T}, e::SimpleEdge{T})::Boolean\n\nwhere e is replaced with the edge being evaluated.\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.filter_vertices-Tuple{MetaGraphs.AbstractMetaGraph,Function}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.filter_vertices",
    "category": "method",
    "text": "filter_vertices(g, prop[, val])\nfilter_vertices(g, fn)\n\nReturn an iterator to all vertices that have property prop defined (optionally as val), or where function fn returns true only for vertices that should be included in the iterator.\n\nfn should be of the form\n\nfn(g::AbstractMetaGraph, v::Integer)::Boolean\n\nwhere v is replaced with the vertex being evaluated.\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.get_prop-Tuple{MetaGraphs.AbstractMetaGraph,Symbol}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.get_prop",
    "category": "method",
    "text": "get_prop(g, prop)\nget_prop(g, v, prop)\nget_prop(g, e, prop)\nget_prop(g, s, d, prop)\n\nReturn the property prop defined for graph g, vertex v, or edge e (optionally referenced by source vertex s and destination vertex d). If property is not defined, return an error.\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.has_prop-Tuple{MetaGraphs.AbstractMetaGraph,Symbol}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.has_prop",
    "category": "method",
    "text": "has_prop(g, prop)\nhas_prop(g, v, prop)\nhas_prop(g, e, prop)\nhas_prop(g, s, d, prop)\n\nReturn true if the property prop is defined for graph g, vertex v, or edge e (optionally referenced by source vertex s and destination vertex d).\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.props-Tuple{MetaGraphs.AbstractMetaGraph}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.props",
    "category": "method",
    "text": "props(g)\nprops(g, v)\nprops(g, e)\nprops(g, s, d)\n\nReturn a dictionary of all metadata from graph g, vertex v, or edge e (optionally referenced by source vertex s and destination vertex d).\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.rem_prop!-Tuple{MetaGraphs.AbstractMetaGraph,Symbol}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.rem_prop!",
    "category": "method",
    "text": "rem_prop!(g, prop)\nrem_prop!(g, v, prop)\nrem_prop!(g, e, prop)\nrem_prop!(g, s, d, prop)\n\nRemove property prop from graph g, vertex v, or edge e (optionally referenced by source vertex s and destination vertex d). If property, vertex, or edge does not exist, will not do anything.\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.set_indexing_prop!-Tuple{MetaGraphs.AbstractMetaGraph,Symbol}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.set_indexing_prop!",
    "category": "method",
    "text": "set_indexing_prop!(g, prop)\nset_indexing_prop!(g, v, prop, val)\n\nMake property prop into an indexing property. If any values for this property are already set, each vertex must have unique values. Optionally, set the index val for vertex v. Any vertices without values will be set to a default (\"(prop)(v)\").\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.set_prop!-Tuple{MetaGraphs.AbstractMetaGraph,Symbol,Any}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.set_prop!",
    "category": "method",
    "text": "set_prop!(g, prop, val)\nset_prop!(g, v, prop, val)\nset_prop!(g, e, prop, val)\nset_prop!(g, s, d, prop, val)\n\nSet (replace) property prop with value val in graph g, vertex v, or edge e (optionally referenced by source vertex s and destination vertex d). Will return false if vertex or edge does not exist, true otherwise\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.set_props!-Tuple{MetaGraphs.AbstractMetaGraph,Dict}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.set_props!",
    "category": "method",
    "text": "set_props!(g, dict)\nset_props!(g, v, dict)\nset_props!(g, e, dict)\nset_props!(g, s, d, dict)\n\nBulk set (merge) properties contained in dict with graph g, vertex v, or edge e (optionally referenced by source vertex s and destination vertex d). Will do nothing if vertex or edge does not exist.\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.weightfield!-Tuple{MetaGraphs.AbstractMetaGraph,Symbol}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.weightfield!",
    "category": "method",
    "text": "weightfield!(g, prop)\n\nSet the field that contains weight information to prop.\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs.weightfield-Tuple{MetaGraphs.AbstractMetaGraph}",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs.weightfield",
    "category": "method",
    "text": "weightfield(g)\n\nReturn the field that contains weight information for metagraph g.\n\n\n\n"
},

{
    "location": "metagraphs.html#MetaGraphs-1",
    "page": "MetaGraphs Functions",
    "title": "MetaGraphs",
    "category": "section",
    "text": "Metadata for graphs is stored as a series of named key-value pairs, with the key being an instance of type Symbol and the value being any type. The following methods are available for MetaGraphs:Modules = [MetaGraphs]\nPages   = [\n    \"MetaGraphs.jl\",\n    \"metagraph.jl\",\n    \"metadigraph.jl\"\n]\nPrivate = false"
},

{
    "location": "license.html#",
    "page": "License Information",
    "title": "License Information",
    "category": "page",
    "text": "The MetaGraphs.jl package is licensed under the MIT \"Expat\" License:Copyright (c) 2017: Seth Bromberger.Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE."
},

]}

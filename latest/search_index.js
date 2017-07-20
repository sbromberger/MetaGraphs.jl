var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#MetaGraphs-1",
    "page": "Home",
    "title": "MetaGraphs",
    "category": "section",
    "text": "(Image: Build Status) (Image: codecov.io)LightGraphs.jl graphs with arbitrary metadata.Example usage:julia> using LightGraphs, MetaGraphs\n\n# create a standard simplegraph\njulia> g = PathGraph(5)\n{5, 4} undirected simple Int64 graph\n\n# create a metagraph based on the simplegraph, with optional default edgeweight\njulia> mg = MetaGraph(g, 3.0)\n{5, 4} undirected Int64 metagraph with Float64 weights defined by :weight (default weight 3.0)\n\n# set some properties for the graph itself\njulia> set_prop!(mg, :description, \"This is a metagraph.\")\nDict{Symbol,Any} with 1 entry:\n  :description => \"This is a metagraph.\"\n\n# set properties on a vertex in bulk\njulia> set_props!(mg, 1, Dict(:name=>\"Susan\", :id => 123))\nDict{Symbol,Any} with 2 entries:\n  :id   => 123\n  :name => \"Susan\"\n\n# set individual properties\njulia> set_prop!(mg, 2, :name, \"John\")\nDict{Symbol,String} with 1 entry:\n  :name => \"John\"\n\n# set a property on an edge\njulia> set_prop!(mg, Edge(1, 2), :action, \"knows\")\nDict{Symbol,String} with 1 entry:\n  :action => \"knows\"\n\n# set another property on an edge by specifying source and destination\njulia> set_prop!(mg, 1, 2, :since, Date(\"20170501\", \"yyyymmdd\"))\nDict{Symbol,Any} with 2 entries:\n  :since   => 2017-05-01\n  :action => \"knows\"\n\n# get all the properties for an element\njulia> props(mg, 1)\nDict{Symbol,Any} with 2 entries:\n  :id   => 123\n  :name => \"Susan\"\n\n# get a specific property by name\njulia> get_prop(mg, 2, :name)\n\"John\"\n\n# delete a specific property\njulia> rem_prop!(mg, 1, :name)\nDict{Symbol,Any} with 1 entry:\n  :id => 123\n\n# clear all properties for vertex 2\njulia> clear_props!(mg, 2)\nDict{Symbol,Any} with 0 entries\n\n# confirm there are no properties set for vertex 2\njulia> props(mg, 2)\nDict{Symbol,Any} with 0 entries\n\n# all LightGraphs analytics work\njulia> betweenness_centrality(mg)\n5-element Array{Float64,1}:\n 0.0\n 0.5\n 0.666667\n 0.5\n 0.0\n\n# using weights\njulia> mg = MetaGraph(CompleteGraph(3))\n{3, 3} undirected Int64 metagraph with Float64 weights defined by :weight (default weight 1.0)\n\njulia> enumerate_paths(dijkstra_shortest_paths(mg, 1), 3)\n2-element Array{Int64,1}:\n 1\n 3\n\njulia> set_prop!(mg, 1, 2, :weight, 0.2)\nDict{Symbol,Float64} with 1 entry:\n  :weight => 0.2\n\njulia> set_prop!(mg, 2, 3, :weight, 0.6)\nDict{Symbol,Float64} with 1 entry:\n  :weight => 0.6\n\njulia> enumerate_paths(dijkstra_shortest_paths(mg, 1), 3)\n3-element Array{Int64,1}:\n 1\n 2\n 3"
},

]}

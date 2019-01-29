function reverse(mg::MetaDiGraph{T,U}) where T <: Integer where U <: Real
    rg = reverse(mg.graph)
    map = nv(mg):-1:1
    rvprops = mg.vprops
    reprops = Dict{SimpleEdge{T},PropDict}()
    rgprops = mg.gprops
    rweightfield = mg.weightfield
    rdefaultweight = mg.defaultweight
    rindices = mg.indices

    for e in keys(mg.eprops)
        reprops[reverse(e)] = mg.eprops[e]
    end

    rmg = MetaDiGraph(rg,
        rvprops,
        reprops,
        rgprops,
        rweightfield,
        rdefaultweight,
        MetaDict(),
        Set{Symbol}())
    for p in mg.indices
        set_indexing_prop!(rmg, p)
    end

    return rmg
end

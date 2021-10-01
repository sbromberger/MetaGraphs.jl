using MetaGraphs
using Test
using LightGraphs

property_set=[
    (src="thirty",dst="inf",color="missing",penwidth="missing",style="missing",),
    (src="twenty",dst="mort",color="missing",penwidth="missing",style="missing",),
    (src="rate",dst="personper",color="missing",penwidth="missing",style="missing",),
    (src="person",dst="unit",color="missing",penwidth="missing",style="missing",),
    (src="personper",dst="unit",color="missing",penwidth="missing",style="missing",),
    (src="second",dst="unit",color="missing",penwidth="missing",style="missing",),
    (src="dollars",dst="unit",color="missing",penwidth="missing",style="missing",),
    (src="dGDP",dst="prices",color="missing",penwidth="missing",style="missing",),
    (src="prices",dst="regres",color="missing",penwidth="missing",style="missing",),
    (src="fed",dst="dGDP",color="missing",penwidth="missing",style="missing",),
    (src="ode",dst="epi",color="missing",penwidth="missing",style="missing",),
    (src="dollars",dst="cost",color="missing",penwidth="missing",style="missing",),
    (src="mort",dst="rate",color="black",penwidth="2.0",style="dashed",),
    (src="inf",dst="rate",color="black",penwidth="2.0",style="dashed",),
    (src="birth",dst="rate",color="black",penwidth="2.0",style="dashed",),
    (src="mort",dst="ind",color="orange",penwidth="4.0",style="solid",),
    (src="ind",dst="epi",color="orange",penwidth="4.0",style="solid",),
    (src="ind",dst="epi",color="orange",penwidth="4.0",style="solid",),
    (src="inf",dst="ind",color="orange",penwidth="4.0",style="solid",),
    (src="birth",dst="ind",color="orange",penwidth="4.0",style="solid",),
    (src="temp",dst="inf",color="orange",penwidth="4.0",style="solid",),
    (src="age",dst="mort",color="orange",penwidth="4.0",style="solid",),
    (src="demo",dst="birth",color="orange",penwidth="4.0",style="solid",),
    (src="epi",dst="cases",color="orange",penwidth="4.0",style="solid",),
    (src="cases",dst="regres",color="orange",penwidth="4.0",style="solid",),
    (src="weather",dst="temp",color="orange",penwidth="4.0",style="solid",),
    (src="demo",dst="age",color="orange",penwidth="4.0",style="solid",),
    (src="regres",dst="cost",color="orange",penwidth="4.0",style="solid",),
    (src="html",dst="fed",color="black",penwidth="2.0",style="solid",)
]

# name, label, color
vprops = [
    ("weather","NOAA\\nWeather","orange"),
    ("cost","Vaccination\\nCost","orange"),
    ("demo","Census\\nDemographics","orange"),
    ("fed", "Fed Forcast", "#5DADE2"),
    ("epi","SIR","#5DADE2"),
    ("ode", "ODE Solver", "#5DADE2"),
    ("rate","{Transition\\nRate}","#66AA55"),
    ("unit","Unit","#66AA55"),
    ("personper","Person/s","#66AA55"),
    ("person","Person","#66AA55"),
    ("second","second (s)","#66AA55"),
    ("dollars","\$","#66AA55"),
    ("inf","Infection\\nRate","#66AA55"),
    ("mort","Mortality\\nRate","#66AA55"),
    ("birth","Birth\\nRate","#66AA55"),
    ("twenty","0.2 Persons/s","#DD1133"),
    ("thirty","0.3 Persons/s","#DD1133"),
    ("ind","Individual\\nContact\\nModel","#5DADE2"),
    ("temp","Temperature","#5DADE2"),
    ("age","Age","#5DADE2"),
    ("dGDP","Economic Growth","#5DADE2"),
    ("cases","Flu\\nCases","#5DADE2"),
    ("prices","Vacc\\nPrice","#5DADE2"),
    ("regres", "Regression", "#5DADE2"),
    ("html", "<<U><B>Title </B></U> <BR/> Some text.>", "#000000"),
]

g = MetaDiGraph(25)

set_prop!(g, :pack, true)

for (v, prop) in enumerate(vprops)
    set_prop!(g, v, :name,  prop[1])
    set_prop!(g, v, :label, prop[2])
    set_prop!(g, v, :color, prop[3])
end

# enable indexing with string names
set_indexing_prop!(g, :name)

# add edges
for prop in property_set
    src, dst = g[prop.src, :name], g[prop.dst, :name]
    add_edge!(g, src,dst)
    set_prop!(g, src, dst, :color, prop.color)
    set_prop!(g, src, dst, :penwidth, prop.penwidth)
    set_prop!(g, src, dst, :style, prop.style)
end

# set global edge properties
for e in edges(g)
    set_prop!(g, e, :dir, :none)
end
# set global vertex properties 
for v in vertices(g)
    set_prop!(g, v, :shape, :record)
    set_prop!(g, v, :style, :filled)
    set_prop!(g, v, :fillcolor, "#dddddd")
    set_prop!(g, v, :penwidth, 2.0)
end

@testset "dotio" begin
    savegraph("diagram.dot", g, DOTFormat())
    open("diagram_ref.dot") do fp
        s_ref = read(fp)
        open("diagram.dot") do fp
            s = read(fp)
            @test s == s_ref
        end

    # Verify that HTML labels are saved without quotes, but that "conventional" (non-html) labels are saved with quotes.
    # The label attribute should be either delimited by:
    #   - "..."     : OK
    #   - <...>     : OK
    #   - both      : NOK ("< or >" as bounding characters, resulting HTML in file will not be parsed correctly by dot.)
    quote_regex = r"label\s*=\s*\"(?:[^\"\\]|\\.)*\"" # source: https://stackoverflow.com/questions/249791/regex-for-quoted-string-with-escaping-quotes
    html_regex = r"label\s*=\s*<.*>" 
    invalid_quote_regex = r"label\s*=\s*\"<(?:[^\"\\]|\\.)*>\""
    for line in eachline(fp)
            test_val = false
            if  !occursin(r"label\s*=",line)
                # the line does not contain a "label" attribute
                test_val = true
            elseif occursin(quote_regex, line)
                # check if a "< or >" combination is present as outer delimiter, this shouldn't occur.
                test_val =  !occursin(invalid_quote_regex, line)
            elseif occursin(html_regex, line)
                # no worries, proper HTML surrounding brackets found.
                test_val = true
            end
        @test test_val 
    end
end


end

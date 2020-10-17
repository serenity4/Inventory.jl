module Inventory

using LightGraphs, MetaGraphs

struct GraphDatabase
    g::MetaGraph
    GraphDatabase() = new(MetaGraph())
end

LightGraphs.add_vertex!(gd::GraphDatabase, attrs) = add_vertex!(gd.g, Dict(attrs))
LightGraphs.add_edge!(gd::GraphDatabase, i, j, attrs) = add_edge!(gd.g, i, j, Dict(attrs))
MetaGraphs.props(gd::GraphDatabase, args...) = MetaGraphs.props(gd.g, args...)

abstract type Item end
Base.broadcastable(x::Item) = Ref(x)

function add_item!(gd::GraphDatabase, item::T; tags=String[], description="", quantity=1) where {T <: Item}
    fnames = fieldnames(T)
    description = endswith(description, ".") ? description : description * "."
    values = getproperty.(item, fnames)
    add_vertex!(gd, Dict(
        (fnames .=> values)...,
        :description => description,
        :tags => tags,
        :quantity => quantity,
        :item => item
    ))
end

function add_item!(gd::GraphDatabase, item_desc::String; tags=String[])
    add_vertex!(gd, Dict(desc_string(item_desc)..., :tags => tags))
end

abstract type Relationship end
label(::Type{T}) where {T <: Relationship} = lowercase(string(Symbol(T)))

find_vert(gd::GraphDatabase, i::Number) = i
function find_vert(gd::GraphDatabase, item::Item)
    verts = collect(filter_vertices(gd.g, :item, item))
    lv = length(verts)
    @assert lv <= 1 "More than one vertex found for $item (found $lv)"
    @assert lv > 0 "No vertex found for $item"
    first(verts)
end

add_relationship!(gd::GraphDatabase, relationship::T) where {T <: Relationship} = add_edge!(gd, find_vert(gd, relationship.src), find_vert(gd, relationship.dst), Dict(:relationship => label(T)))

find_vertices(gd::GraphDatabase, properties::Dict{Symbol, <: Any}) = collect(filter_vertices(gd.g, (g, x) -> all(props(g, x)[prop] == val for (prop, val) ∈ properties)))
find_vertices(gd::GraphDatabase, properties::Vector{Symbol}) = collect(filter_vertices(gd.g, (g, x) -> all(haskey(props(g, x), prop) for prop ∈ properties)))
find_edges(gd::GraphDatabase, relationship::Type{T}) where {T <: Relationship} = collect(filter_edges(gd.g, :relationship, label(T)))

Base.show(io::IO, gd::GraphDatabase) = print(io, "Graph database ($(length(gd.g)) items, $(length(edges(gd.g))) relationships)")

function desc_string(str)
    quantity_m = match(r"x\d+(?=(?:$|\s-))", str)
    quantity = isnothing(quantity_m) ? 1 : parse(Int, strip(quantity_m.match, 'x'))
    desc_m = match(r"\s-\s(.*)$", str)
    desc = isnothing(desc_m) ? nothing : first(desc_m.captures)
    if isnothing(quantity_m) && isnothing(desc_m)
        name_reg = r"^(.*)$"
    elseif isnothing(quantity_m)
        name_reg = r"^(.*)\s-\s"
    else
        name_reg = r"^(.*)\sx\d+"
    end
    name = match(name_reg, str).captures[1]
    Dict(:name => name, :description => desc, :quantity => quantity)
end

export GraphDatabase,
       Relationship,
       Item,
       find_vert,
       label,
       add_relationship!,
       add_item!,
       props,
       find_vertices,
       find_edges
end

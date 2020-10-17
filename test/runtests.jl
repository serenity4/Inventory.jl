using Inventory
using LightGraphs
using Test

include("items.jl")
include("relationships.jl")

house = House("166 rue Jean Bart", "Sanary-sur-Mer", "France")
bedroom = Room(house)
gd = GraphDatabase()
add_item!(gd, house, tags=["house"], description="Parents' house")
add_item!(gd, bedroom, description="Cedric's bedroom in his parents' house")
add_item!(gd, "Plug extension x3", tags=["plugs", "electric", "accessories"])
add_item!(gd, "Side power strip - Power strip with plugs on the sides (left, right, top/bottom)", tags=["plugs", "electric", "accessories"])

add_relationship!(gd, Contains(house, bedroom))
gd

@testset "Items" begin
    @test find_vert(gd, house) == 1
    @test find_vert(gd, bedroom) == 2
    @test props(gd, 1)[:tags] == ["house"]
    @test props(gd, 1)[:quantity] == 1
    @test props(gd, 1)[:description] == "Parents' house."
    @test isempty(props(gd, 2)[:tags])
end

@testset "Relationships" begin
    @test find_edges(gd, Contains) == [Edge(1, 2)]
end

@testset "Queries" begin
    @test find_vertices(gd, Dict(:tags => ["house"])) == [1]
    @test find_vertices(gd, [:description]) == [1, 2, 3, 4]
end
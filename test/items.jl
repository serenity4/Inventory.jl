struct House <: Item
    address
    city
    country
end

struct Room <: Item
    house::House
end

Base.@kwdef struct Desk <: Item
    top
    main_drawer
    side_drawer_1
    side_drawer_2
    side_drawer_3
    drawers_top
end

struct MainCompartment <: Item end
struct LightSuitcase <: Item end
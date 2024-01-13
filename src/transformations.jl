# Helper functions for transforming between
# world, model and paper.

"""
    world_to_paper_factor(m::ModelSpace) 
    ---> Float64

An increase of one unit in a UTM coordinate corresponds to how may paper space points or pixels? 
This depends on model ink extents. Everything fits to the paper size minus margins.
"""
world_to_paper_factor(m::ModelSpace) = world_to_model_factor(m) * model_to_paper_factor(m)

"""
    world_to_model_factor(m::ModelSpace)

An increase of one unit in a UTM coordinate corresponds to how may paper space points or pixels? 
"""
world_to_model_factor(m::ModelSpace) = m.world_to_model_factor

"""
    model_to_paper_factor(m::ModelSpace)
    ---> Float64

An increase of one unit in a model space coordinate corresponds to how may paper space points or pixels? 
This depends on LuxorLayout ink extents. Everything fits to the paper size minus margins.
"""
function model_to_paper_factor(m::ModelSpace)
    update_layout(m)
    factor_user_to_overlay_get()
end
"""
    O_model_in_paper_space()
    ---> Point

This depends on updated limits in LuxorLayout.
"""
function O_model_in_paper_space(m)
    update_layout(m)
    user_origin_in_overlay_space_get()
end




# In the model, y is down, as in device space of Cairo / Luxor.
# Also in paper space.
easting_to_model_x(m::ModelSpace, easting) = easting_to_model_x(world_to_model_factor(m), m.originE, easting)
easting_to_model_x(world_to_model_factor, originE, veasting::Vector) = map(wx -> easting_to_model_x(world_to_model_factor, originE, wx), veasting)
easting_to_model_x(world_to_model_factor, originE, easting) = (easting - originE) * world_to_model_factor

northing_to_model_y(m::ModelSpace, northing) = northing_to_model_y(world_to_model_factor(m), m.originN, northing)
northing_to_model_y(world_to_model_factor, originN, vnorthing::Vector) = map(wy -> northing_to_model_y(world_to_model_factor, originN, wy), vnorthing)
northing_to_model_y(world_to_model_factor, originN, northing) = -(northing - originN) * world_to_model_factor

model_x_to_easting(m::ModelSpace, mx) = model_x_to_easting(world_to_model_factor(m), m.originE, mx)
model_x_to_easting(world_to_model_factor, originE, vmx::Vector) = map(mx -> model_x_to_easting(world_to_model_factor, originE, mx), vmx)
model_x_to_easting(world_to_model_factor, originE, mx) = mx / world_to_model_factor + originE

model_y_to_northing(m::ModelSpace, my) = model_y_to_northing(world_to_model_factor(m), m.originN, my)
model_y_to_northing(world_to_model_factor, originN, vmy::Vector) = map(my -> model_y_to_northing(world_to_model_factor, originN, my), vmy)
model_y_to_northing(world_to_model_factor, originN, my) = -my / world_to_model_factor + originN

model_x_to_paper_x(m::ModelSpace, mx) = model_x_to_paper_x(model_to_paper_factor(m), O_model_in_paper_space(m).x, mx)
model_x_to_paper_x(model_to_paper_factor, Ox_model_in_paper_space, vmx::Vector) = map(mx -> model_x_to_paper_x(model_to_paper_factor, Ox_model_in_paper_space, mx), vmx)
model_x_to_paper_x(model_to_paper_factor, Ox_model_in_paper_space, mx) = Ox_model_in_paper_space + (mx * model_to_paper_factor)

model_y_to_paper_y(m::ModelSpace, my) = model_y_to_paper_y(model_to_paper_factor(m), O_model_in_paper_space(m).y, my)
model_y_to_paper_y(model_to_paper_factor, Oy_model_in_paper_space, vmy::Vector) = map(my -> model_y_to_paper_y(model_to_paper_factor, Oy_model_in_paper_space, my), vmy)
model_y_to_paper_y(model_to_paper_factor, Oy_model_in_paper_space, my) = Oy_model_in_paper_space + (my * model_to_paper_factor)

paper_x_to_model_x(m::ModelSpace, paper_x) = paper_x_to_model_x(model_to_paper_factor(m), O_model_in_paper_space(m).x, paper_x)
paper_x_to_model_x(model_to_paper_factor, Ox_model_in_paper_space, vpaper_x::Vector) = map(paper_x -> paper_x_to_model_x(model_to_paper_factor, Ox_model_in_paper_space, paper_x), vpaper_x)
paper_x_to_model_x(model_to_paper_factor, Ox_model_in_paper_space, paper_x) = (paper_x - Ox_model_in_paper_space) / model_to_paper_factor

paper_y_to_model_y(m::ModelSpace, paper_y) = paper_y_to_model_y(model_to_paper_factor(m), O_model_in_paper_space(m).y, paper_y)
paper_y_to_model_y(model_to_paper_factor, Oy_model_in_paper_space, vpaper_y::Vector) = map(paper_y -> paper_y_to_model_y(model_to_paper_factor, Oy_model_in_paper_space, paper_y), vpaper_y)
paper_y_to_model_y(model_to_paper_factor, Oy_model_in_paper_space, paper_y) = (paper_y - Oy_model_in_paper_space) / model_to_paper_factor


easting_to_paper_x(m::ModelSpace, easting) = model_x_to_paper_x(m, easting_to_model_x(m, easting))
northing_to_paper_y(m::ModelSpace, northing) = model_y_to_paper_y(m, northing_to_model_y(m, northing))
paper_x_to_easting(m::ModelSpace, paper_x) = model_x_to_easting(m, paper_x_to_model_x(m, paper_x))
paper_y_to_northing(m::ModelSpace, paper_y) = model_y_to_northing(m, paper_y_to_model_y(m, paper_y))


function utm_to_model(m::ModelSpace, bb_utm::BoundingBox)
    xs = easting_to_model_x(m, [bb_utm.corner1.x, bb_utm.corner2.x])
    ys = northing_to_model_y(m, [bb_utm.corner1.y, bb_utm.corner2.y])
    BoundingBox(Point(xs[1], ys[1]), Point(xs[2], ys[2]))
end

"""
    update_layout(model)    ---> Nothing

model.limiting... is mutable. Update LuxorLayout with the model's current values.

model.margin is not mutable. Update LuxorLayout globals in case the model was not activated.
"""
function update_layout(model)
    LIMITING_WIDTH[] = model.limiting_width[]
    LIMITING_HEIGHT[] = model.limiting_height[]
    ma = model.margin
    margin_set(Margin(ma.t, ma.b, ma.l, ma.r))
    nothing
end

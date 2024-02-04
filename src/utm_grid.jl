
"""
    draw_utm_grid(m::ModelSpace)

Uses ModelSpace fields:
- utm_grid_size
- utm_grid_thickness

Reads LuxorLayout.inkextent_user_with_margin().

The UTM grid serves three purposes:
 1) It provides a visually recognizable scale.
 2) It aids in pasting together a map from different sheets of paper.
 3) It aids in pasting in map backgrounds (e.g. a satelite image) which has similar grids.
"""
function draw_utm_grid(m::ModelSpace)
    # The ink extent is owned by LuxorLayout.
    topleft_model, bottomright_model = inkextent_user_with_margin()
    easting_min = model_x_to_easting(m, topleft_model[1])
    northing_max = model_y_to_northing(m, topleft_model[2])
    easting_max = model_x_to_easting(m, bottomright_model[1])
    northing_min = model_y_to_northing(m, bottomright_model[2])
    _draw_utm_grid(m, easting_min, northing_max, easting_max, northing_min)
end

function _draw_utm_grid(m, easting_min, northing_max, easting_max, northing_min; 
        utm_grid_size = m.utm_grid_size, 
        utm_grid_thickness = m.utm_grid_thickness / world_to_paper_factor(m), 
        grid_size_model = m.utm_grid_size *  m.world_to_model_factor)
    x0 = round(easting_min / utm_grid_size, RoundDown) * utm_grid_size
    y0 = round(northing_min / utm_grid_size, RoundDown) * utm_grid_size
    x1 = round(easting_max / utm_grid_size, RoundUp) * utm_grid_size
    y1 = round(northing_max / utm_grid_size, RoundUp) * utm_grid_size
    xm0 = easting_to_model_x(m, x0)
    ym0 = northing_to_model_y(m, y0)
    xm1 = easting_to_model_x(m, x1)
    ym1 = northing_to_model_y(m, y1)
    draw_grid(xm0, ym0, xm1, ym1, grid_size_model, utm_grid_thickness)
end
function draw_grid(x0, y0, x1, y1, grid_size, grid_thickness)
    @assert x0 < x1
    @assert y0 > y1
    vx = range(x0, x1, step = grid_size)
    vy = range(y1, y0, step = grid_size)
    @layer begin
        setline(grid_thickness)
        for i in 1:max(length(vx), length(vy))
            if i <= length(vx)
                x = vx[i]
                line(Point(x, y0), Point(x, y1), action = :none)
            end
            if i <= length(vy)
                y = vy[i]
                line(Point(x0, y), Point(x1, y), action = :none)
            end
        end
        Luxor.do_action(:stroke)
    end
    nothing
end
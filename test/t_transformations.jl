# Unit testing
using Test, RouteMap
using RouteMap: utm_to_model, find_boolean_step_using_interval_halving
import Luxor
using Luxor: Point, BoundingBox
# Create a model with no UTM to model scaling, don't activate it.
model = RouteMap.ModelSpace()
# Define some manually transformed coordinates
wx, wy = 55021, 6956132 # Rundkjøring Moa sentralstasjon, UTM 33. In model space: ca. 28362.0, 15899.0
mx, my = 28460, -15908
px, py = 28460, -15908 
vwx, vwy = [55021, 55022], [6956132, 6956133]
vmx, vmy = [28460, 28461], [-15908, -15909]
vpx, vpy = [28460, 28461], [-15908, -15909]

@test easting_to_model_x(model, wx) == mx
@test northing_to_model_y(model, wy) == my
@test model_x_to_easting(model, mx) == wx
@test model_y_to_northing(model, my) == wy
@test easting_to_model_x(model, vwx) == vmx
@test northing_to_model_y(model, vwy) == vmy
@test model_x_to_easting(model, vmx) == vwx
@test model_y_to_northing(model, vmy) == vwy


# Create a model with UTM to model scaling, don't activate it.
model = RouteMap.ModelSpace(; world_to_model_factor = 0.5)
@test easting_to_model_x(model, wx) == mx / 2
@test northing_to_model_y(model, wy) == my / 2
@test model_x_to_easting(model, mx / 2) == wx
@test model_y_to_northing(model, my / 2) == wy
@test easting_to_model_x(model, vwx) == vmx / 2
@test northing_to_model_y(model, vwy) == vmy / 2
@test model_x_to_easting(model, vmx / 2) == vwx
@test model_y_to_northing(model, vmy / 2) == vwy


# To test paper space, we need to activate a model. We 
# don't draw anything in model space yet. Hence, ink_extent
# is at default, so model to paper scale will be 1.
model = model_activate()
@test paper_x_to_model_x(model, px) == mx
@test paper_y_to_model_y(model, py) == my
@test model_x_to_paper_x(model, mx) == px
@test model_y_to_paper_y(model, my) == py
@test paper_x_to_model_x(model, vpx) == vmx
@test paper_y_to_model_y(model, vpy) == vmy
@test model_x_to_paper_x(model, vmx) == vpx
@test model_y_to_paper_y(model, vmy) == vpy

model = model_activate(; world_to_model_factor = 0.5)
@test paper_x_to_model_x(model, px) == mx
@test paper_y_to_model_y(model, py) == my
@test model_x_to_paper_x(model, mx) == px
@test model_y_to_paper_y(model, my) == py
@test paper_x_to_model_x(model, vpx) == vmx
@test paper_y_to_model_y(model, vpy) == vmy
@test model_x_to_paper_x(model, vmx) == vpx
@test model_y_to_paper_y(model, vmy) == vpy

bb_utm = BoundingBox(Point(vwx[1], vwy[1]), Point(vwx[2], vwy[2]))
bbm = utm_to_model(model, bb_utm)
@test bbm.corner1.x == 0.5 * vmx[1]
@test bbm.corner1.y == 0.5 * vmy[1]
@test bbm.corner2.x == 0.5 * vmx[2]
@test bbm.corner2.y == 0.5 * vmy[2]


# Let's update a new model with something twice the size of paper width.
# For easier checking, set all margins symmetrical.
model = model_activate(; margin = (t = 10, b = 10, l = 72, r = 72))
ptmx = RouteMap.Point(model.limiting_width[] - model.margin.l - model.margin.r, 0)
encompass(ptmx)
encompass(-ptmx)
@test model_to_paper_factor(model) == 0.5
#
@test paper_x_to_model_x(model, px) == 2 * mx
@test paper_y_to_model_y(model, py) == 2 * my
@test model_x_to_paper_x(model, mx) == 0.5 * px
@test model_y_to_paper_y(model, my) == 0.5 * py
@test paper_x_to_model_x(model, vpx) == 2 * vmx
@test paper_y_to_model_y(model, vpy) == 2 * vmy
@test model_x_to_paper_x(model, vmx) == 0.5 * vpx
@test model_y_to_paper_y(model, vmy) == 0.5 * vpy


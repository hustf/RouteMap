# Unit testing
using Test, RouteMap
using RouteMap: find_boolean_step_using_interval_halving
# Create a model, don't activate it.
model = RouteMap.ModelSpace()
wx, wy = 55021, 6956132 # Rundkjøring Moa sentralstasjon, UTM 33. In model space: ca. 28362.0, 15899.0
mx, my = 28460, -15908
vwx, vwy = [55021, 55022], [6956132, 6956133]
vmx, vmy = [28460, 28461], [-15908, -15909]
@test easting_to_model_x(model, wx) == mx
@test northing_to_model_y(model, wy) == my
@test model_x_to_easting(model, mx) == wx
@test northing_to_model_y(model, my) == wy


model = RouteMap.ModelSpace(; world_to_model_scale = 2)
@test easting_to_model_x(model, wx) == mx / 2
@test northing_to_model_y(model, wy) == my / 2
@test model_x_to_easting(model, mx / 2) == wx
@test model_y_to_northing(model, my / 2) == wy

model = RouteMap.ModelSpace()
@test easting_to_model_x(model, vwx) == vmx
@test northing_to_model_y(model, vwy) == vmy
@test model_x_to_easting(model, vmx) == vwx
@test northing_to_model_y(model, vmy) == vwy

@test abs(find_boolean_step_using_interval_halving(;lower = 1.0, upper = 10.0, iterations = 100) do x
    x >= π
end - 3.1415) < 1e-3


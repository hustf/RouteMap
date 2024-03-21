# testing `leg_offset`
# This uses some variables defined in `t_world_space.jl` and 't_draw.jl'
if ! @isdefined leg
    include("t_world_space.jl")
end
using RouteMap: path_offset_along_normal, progression_at_each_coordinate

# Offset a straight horizontal line
px = collect(.0:5:10)
py = 0.0 .* px
@test progression_at_each_coordinate(px, py) == px
@test path_offset_along_normal(px, py, 0.0) == (px, py)
@test path_offset_along_normal(px, py, 1) == (px, py .+ 1)
@test path_offset_along_normal(px, py, -1) == (px, py .- 1)

# Offset a unit circle
s = 0.0:.1:2π
px = cos.(s)
py = sin.(s)
@test path_offset_along_normal(px, py, 0.0) == (px, py)
ox, oy = path_offset_along_normal(px, py, 1.0)
@test maximum(hypot.(ox, oy)) < 0.05
ox, oy = path_offset_along_normal(px, py, -1.0)
@test minimum(hypot.(ox, oy)) > 1.99


# Create a model with no UTM to model scaling, don't activate it.
model = RouteMap.ModelSpace()
lo = leg_offset(model, leg, 1)
@test lo.label_A == leg.label_A
@test lo.label_B == leg.label_B
@test lo.bb_utm == leg.bb_utm
@test length(lo.ABx) == length(lo.ABx)
@test length(lo.ABy) == length(lo.ABy)
@test length(lo.ABx) == length(lo.ABx)
@test length(lo.ABy) == length(lo.ABy) 

# Graphic test, linecap and linejoin settings
if ! @isdefined legs_fork
    include("t_draw.jl")
end
import Luxor
using Luxor: sethue, setopacity, RGB, circle, setline, @layer,
    Point, line, BoundingBox, snapshot, Drawing, O, translate
using RouteMap: plot_leg_in_model_space_and_push_labels_to_model!,
    indices_surrounding_si_loop, inkextent_set

    
m = model_activate(;countimage_startvalue = 24)

legs_fork_o = map(l -> leg_offset(m, l, 1), legs_fork)
sethue(m.foreground)
setopacity(0.9)
plot_legs_in_model_space_and_push_labels_to_model!(m, legs_fork)
sethue(m.colorscheme[9])
plot_legs_in_model_space_and_push_labels_to_model!(m, legs_fork_o)
snap_with_labels(m) 

# Unit and graphic test of intersection.
# This has unrelated lines entirely outside of the loop
#      1   2  3  4   5     6
#      o   o  i  i   o     o     
vx = [-1., 0, 1, -1, 0.5,  1] .* 10
vy = [-1., 0.1, 1, 1,  0.0, -1] .* 10
model_activate(;countimage_startvalue = 22)
inkextent_set(BoundingBox(O, O + (5, 5)))
circle(Point(vx[1], vy[1]), 0.2, :stroke) |> encompass
for i in 2:length(vx)
    circle(Point(vx[i], vy[i]), 0.2, :stroke) |> encompass
    line(Point(vx[i - 1], vy[i - 1]), Point(vx[i], vy[i]), :stroke)
end
snap()
@test indices_surrounding_si_loop(vx, vy) == (2, 5)



# Unit and graphic test of intersection.
# This has an unrelated line after the loop
#     1  2  3   4   5
#     o  i  i   o   o     
vx = [0, 1, -1, 0.5,  1] .* 10
vy = [0.1, 1, 1,  0.0, -1] .* 10
model_activate(;countimage_startvalue = 23)
inkextent_set(BoundingBox(O, O + (5, 5)))
circle(Point(vx[1], vy[1]), 0.2, :stroke) |> encompass
for i in 2:length(vx)
    circle(Point(vx[i], vy[i]), 0.2, :stroke) |> encompass
    line(Point(vx[i - 1], vy[i - 1]), Point(vx[i], vy[i]), :stroke)
end
snap()
@test indices_surrounding_si_loop(vx, vy) == (1, 4)


# Unit and graphic test of intersection.
# This has no unrelated lines outside the loop, just two vertices.
#     1  2  3   4  
#     o  i  i   o      
vx = [0, 1, -1, 0.5] .* 10
vy = [0.1, 1, 1,  0.0] .* 10
model_activate(;countimage_startvalue = 24)
inkextent_set(BoundingBox(O, O + (5, 5)))
circle(Point(vx[1], vy[1]), 0.2, :stroke) |> encompass
for i in 2:length(vx)
    circle(Point(vx[i], vy[i]), 0.2, :stroke) |> encompass
    line(Point(vx[i - 1], vy[i - 1]), Point(vx[i], vy[i]), :stroke)
end
snap()
@test indices_surrounding_si_loop(vx, vy) == (1, 4)

# Unit and graphic test of intersection.
# This has no self intersection
#     1   2   3    4 
#     o   o   o    o     
vx = [1, -1, 0.5,  1] .* 10
vy = [1, 1,  0.0, -1] .* 10
model_activate(;countimage_startvalue = 25)
inkextent_set(BoundingBox(O, O + (5, 5)))
circle(Point(vx[1], vy[1]), 0.2, :stroke) |> encompass
for i in 2:length(vx)
    circle(Point(vx[i], vy[i]), 0.2, :stroke) |> encompass
    line(Point(vx[i - 1], vy[i - 1]), Point(vx[i], vy[i]), :stroke)
end
snap()
@test indices_surrounding_si_loop(vx, vy) == (nothing, nothing)

# Unit and graphic test of intersection.
# Too short for self-intersection
vx = [1, -1, 0.5] .* 10
vy = [1, 1,  0.0] .* 10
@test indices_surrounding_si_loop(vx, vy) == (nothing, nothing)
vx = [1, -1] .* 10
vy = [1, 1] .* 10
@test indices_surrounding_si_loop(vx, vy) == (nothing, nothing)
vx = [1] .* 10
vy = [1] .* 10
@test indices_surrounding_si_loop(vx, vy) == (nothing, nothing)
vx = Float64[]
vy = Float64[]
@test indices_surrounding_si_loop(vx, vy) == (nothing, nothing)


# Graphic test, self-intersection due to inner corner offset 
leg = Leg(;ABx, ABy, text_A, text_B, prominence_A, prominence_B)
legs = [leg]
m = model_activate(;countimage_startvalue = 25)
Luxor.background(RGB(1,1,1))
sethue(m.foreground)
setopacity(0.9)
plot_legs_in_model_space_and_push_labels_to_model!(m, legs)
legs_o = Leg[]
for i = 2:2:8
    leg_o = leg_offset(m, legs[1], -i; allow_self_intersection = true)
    push!(legs_o, leg_o)
end
@layer begin
    for (i, l) in enumerate(legs_o)
        sethue(m.colorscheme[i])
        plot_leg_in_model_space_and_push_labels_to_model!(m, l)
    end
end
@test ! RouteMap.is_polyline_self_intersecting(legs[end].ABx, legs[end].ABy)
for l in legs_o
    @test RouteMap.is_polyline_self_intersecting(l.ABx, l.ABy)
end

# Move the original leg out of the way 
@layer begin
    translate(O + (150, -250))
    plot_legs_in_model_space_and_push_labels_to_model!(m, [leg])
end

legs_o_fixed = Leg[]
for i = 2:2:8
    leg_o_fixed = leg_offset(m, legs[1], -i)
    push!(legs_o_fixed, leg_o_fixed)
end
@layer begin
    translate(O + (150, -250))
    for (i, l) in enumerate(legs_o_fixed)
        sethue(m.colorscheme[i])
        plot_leg_in_model_space_and_push_labels_to_model!(m, l)
    end
end
snap_with_labels(m) 


#  Graphic test, self-intersection due to inner corner offset
#  but now including BA as well as AB
# NOTE: BA is actually shorther than BA, since exit and entry points differ.
leg = Leg(;ABx, ABy, BAx, BAy, text_A, text_B, prominence_A, prominence_B)
legs = [leg]
m = model_activate(;countimage_startvalue = 26)
Luxor.background(RGB(0.8, 0.8, 1))
sethue(m.foreground)
setopacity(0.9)
plot_legs_in_model_space_and_push_labels_to_model!(m, legs)
legs_o = Leg[]
for i = 2:2:8
    leg_o = leg_offset(m, legs[1], -i; allow_self_intersection = true)
    push!(legs_o, leg_o)
end
@layer begin
    for (i, l) in enumerate(legs_o)
        sethue(m.colorscheme[i])
        plot_leg_in_model_space_and_push_labels_to_model!(m, l)
    end
end
@test ! RouteMap.is_polyline_self_intersecting(legs[end].ABx, legs[end].ABy)
for l in legs_o
    @test RouteMap.is_polyline_self_intersecting(l.ABx, l.ABy)
end

# Move the original leg out of the way 
@layer begin
    translate(O + (150, -250))
    plot_legs_in_model_space_and_push_labels_to_model!(m, [leg])
end

legs_o_fixed = Leg[]
for i = 2:2:8
    leg_o_fixed = leg_offset(m, legs[1], -i)
    push!(legs_o_fixed, leg_o_fixed)
end
@layer begin
    translate(O + (150, -250))
    for (i, l) in enumerate(legs_o_fixed)
        sethue(m.colorscheme[i])
        plot_leg_in_model_space_and_push_labels_to_model!(m, l)
    end
end
snap_with_labels(m) 

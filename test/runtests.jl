include("t_world_space.jl")
# Time to draw a little.
using Luxor, LuxorLayout
Drawing(NaN, NaN, :rec)
background("yellow")
inkextent_reset()
vx = 100 .* [1, 2.2, 3, 4.1 , 5, 6]
vy = 100 .* [1.1, 2.0, 3, 2 , 1.2, 0.5]
wx = 100 .* [6.8765305817039915, 5.5108313221027805, 3.6517099327681195, 3.151178505491685, 1.2679176009349515]
wy = 100 .* [1.6223257209157279, 1.2477648298469046, 3.774275715327908, 2.7447059574248542, 1.6639055278414527]
v = map(xy -> Point(xy[1], xy[2]), zip(vx, vy))
w = map(xy -> Point(xy[1], xy[2]), zip(wx, wy))
encompass(v)
encompass(w)
setcolor("red")
poly(v, action=:stroke)
setcolor("blue")
poly(w, action=:stroke)
snap()
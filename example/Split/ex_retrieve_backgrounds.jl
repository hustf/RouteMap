#
# This is a sketch for retrieving images through an api.
# The best elevation data was instead retrieved through
# hoydedata.no, but there is no support for generating urls.
# Instead, we took the corner coordinates for each part of the map
# from somewhere else (maybe the code below), and manually
# typed coordinates into the 'export' tab. Elevation data
# with a 1m resolution is received by email after ~2 hours,
# and intitial processing to bitmap images was done using
# the environment 'geoarrays'. We should move that elsewhere.
# The best images are based on a 3 m horizontal distance elevation data,
# because the surface normals based on 1m resolution vary too much.

# We keep this for now because we might find some reuse.




import RouteMap
using RouteMap: ModelSpace, paper_to_utm
if ! @isdefined FILELARGE
    include("split_functions.jl")
end



function matrix_of_image_space_bounding_boxes(;pagewidth = 595, pageheight = 842, 
    gutter_overlap_x = 0,
    gutter_overlap_y = 0,
    centre_rot_cw = 0 * π / 180, 
    Δx = 0.0, 
    Δy = 0.0)
    # Find the width and height of the big drawing on disk.
    iw, ih  = image_width_height()
    # Find the parameters we would use to split the big drawing.
    # 'partitions' is an iterator defined by Luxor.
    w, h, partitions, gx, gy, dx, dy, ncols, nrows = parameters_for_partitioning(iw, ih; pagewidth, pageheight, gutter_overlap_x, gutter_overlap_y, centre_rot_cw)
    # Create the bounding boxes we would use to take snapshots of printable pieces of the large drawing.
    mbb = Matrix{BoundingBox}(undef, nrows, ncols)
    for (ptc, n) in partitions
        i, j = partitions.currentrow, partitions.currentcol
        cb = bobox(ptc, dx, Δx, gx, dy, Δy, gy)
        mbb[i, j] = cb
    end
    mbb
end


function image_bb_to_utm(bb::BoundingBox)
    xs = map(image_x_to_easting, [bb.corner1.x, bb.corner2.x])
    ys = map(image_y_to_northing, [bb.corner1.y, bb.corner2.y])
    BoundingBox(Point(xs[1], ys[1]), Point(xs[2], ys[2]))
end
r(x) = string(Int(round(x)))
function image_bb_to_utm_text(bb)
    bbu = image_bb_to_utm(bb)
    r(bbu.corner1.x) * " " * r(bbu.corner1.y) * "    "*  r(bbu.corner2.x) * " " * r(bbu.corner2.y)
end
xmin(bb) = r(image_bb_to_utm(bb).corner1.x)
xmax(bb) = r(image_bb_to_utm(bb).corner2.x)
ymin(bb) = r(image_bb_to_utm(bb).corner1.y)
ymax(bb) = r(image_bb_to_utm(bb).corner2.y)
function u(bb)
    s = """
    https://hoydedata.no/LaserInnsyn2/
    ?xmin=$(xmin(bb))
    &ymin=$(ymin(bb))
    &xmax=$(xmax(bb))
    &ymax=$(ymax(bb))
    &wkid=25833&background=topo4graatone
    &batymetriLayers=&batymetriAdvanced=&dtmLayers=&dtmAdvanced=&domLayers=DOM_skyggerelieff&otherLayers=&metadataLayers=Prosjektavgrensning&projects=6118
    """
    @info "Copy mulit-line url to browser:"
    println(s)
end
# We made RouteMap elsewhere, but we found the corners, thus:
#       julia> inkextent_user_with_margin() |> bb -> model_to_utm(m, bb)
#        ⤡ Point(2604.283630878439, 6.961467968415262e6) : Point(58323.800369121556, 6.911995687723159e6)
# Captured by the conversion:
bb_utm = BoundingBox(Point(2604.283630878439, 6.961467968415262e6), Point(58323.800369121556, 6.911995687723159e6))
iw, ih  = image_width_height()
# The conversion:
# Note that, due to margins, 'paper y' and 'image y' are not quite identical.
# If margins are unsymmetric to left and right, that may also be the case for x.
# Inkscape coordinates are different, too. Origin is top left,
image_x_to_easting(x) = (bb_utm.corner1.x + bb_utm.corner2.x) / 2 + x * boxwidth(bb_utm) / iw 
image_y_to_northing(y) = (bb_utm.corner2.y + bb_utm.corner1.y) / 2 - y * boxheight(bb_utm) / ih 

mbb = matrix_of_image_space_bounding_boxes(; centre_rot_cw = 0 * π / 180, Δx = 320)
bb_is = mbb[2, 3]
image_bb_to_utm_text(bb_is)

https://hoydedata.no/LaserInnsyn2/?xmin=27407.528910603323&ymin=6938171.881467131&xmax=27591.01794827495&ymax=6938266.259542747&wkid=25833&background=topo4graatone&batymetriLayers=&batymetriAdvanced=&dtmLayers=&dtmAdvanced=&domLayers=DOM_skyggerelieff&otherLayers=&metadataLayers=Prosjektavgrensning&projects=6118







# What resolution?
# 595 pt / 210mm = 2.8333 pt /mm
# 595 pt / 8.267 in = 72 dpi
# 2480 pt/ 8.267 in = 300 dpi
# So: 2480 pt is sufficient for A4 width.
# 2480 pt * 842 / 595 = 3510 pt height, but scale for width! 

for i in 1:3
    for j in 1:4
        print(rpad(string(i), 4))
        print(rpad(string(j), 4))
        println(image_bb_to_utm_text(mbb[i,j]))
    end
end
#=

=
1   1    4873 6964416    17915 6945960
1   2   17915 6964416    30957 6945960
1   3   30957 6964416    43999 6945960
1   4   43999 6964416    57042 6945960
2   1    4873 6945960    17915 6927504
2   2   17915 6945960    30957 6927504
2   3   30957 6945960    43999 6927504
2   4   43999 6945960    57042 6927504
3   1    4873 6927504    17915 6909048
3   2   17915 6927504    30957 6909048
3   3   30957 6927504    43999 6909048
3   4   43999 6927504    57042 6909048
=#

# Image sizes for a full-res patchwork:
# widths: [0, 13042, 26084, 39126, 52168]
# heights: [0, 18456, 36912, 55368]






# Alternative: 
#https://norgeskart.no/#!?project=ssr&layers=1007&zoom=11&lat=6914631.48&lon=10274.16&p=searchOptionsPanel

function u_norgeskart(lat, lon)
    s = """
    https://norgeskart.no/#!?project=ssr&layers=1007
    &zoom=12
    &lat=$lat
    &lon=$lon
    """
    println(s);
end


@info "Copy mulit-line url to browser:"

i = 0
for (j, lat) in enumerate(6916700:7200:6953836)
    for (k, lon) in enumerate(8300:9500:55800)
        i += 1
        println(i, "  ", j, "  ", k)
        u_norgeskart(lat, lon)
    end
end

#=
1
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6916700
&lon=8300

2
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6916700
&lon=17800

3
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6916700
&lon=27300

4
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6916700
&lon=36800

5
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6916700
&lon=46300

6
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6916700
&lon=55800

7
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6923900
&lon=8300

8
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6923900
&lon=17800

9
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6923900
&lon=27300

10
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6923900
&lon=36800

11
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6923900
&lon=46300

12
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6923900
&lon=55800

13
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6931100
&lon=8300

14
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6931100
&lon=17800

15
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6931100
&lon=27300

16
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6931100
&lon=36800

17
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6931100
&lon=46300

18
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6931100
&lon=55800

19
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6938300
&lon=8300

20
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6938300
&lon=17800

21
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6938300
&lon=27300

22
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6938300
&lon=36800

23
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6938300
&lon=46300

24
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6938300
&lon=55800

25
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6945500
&lon=8300

26
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6945500
&lon=17800

27
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6945500
&lon=27300

28
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6945500
&lon=36800

29
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6945500
&lon=46300

30
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6945500
&lon=55800

31
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6952700
&lon=8300

32
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6952700
&lon=17800

33
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6952700
&lon=27300

34
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6952700
&lon=36800

35
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6952700
&lon=46300

36
https://norgeskart.no/#!?project=ssr&layers=1007
&zoom=12
&lat=6952700
&lon=55800
=#
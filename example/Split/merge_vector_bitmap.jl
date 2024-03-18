# This splits a large svg file into A4-sized partitions,
# without scaling but with rotation. This is handy for 
# preserving text size when printing piecewise
include("split_functions.jl")
pagewidth = 595
pageheight = 842
gutter_overlap_x = 0
gutter_overlap_y = 0
centre_rot_cw = 0 * π / 180
Δx = 320
Δy = 0.0
# Find the width and height of the big svg drawings on disk.
fsvg_labels = "example/split/Routemap-labels.svg"
fsvg_nolabels = "example/split/Routemap-nolabels.svg"

rimg_labels = _read_image(fsvg_labels)
rimg_legs = _read_image(fsvg_nolabels)

iw, ih  = rimg_labels.width, rimg_labels.height
@assert iw == rimg_legs.width
@assert ih ==  rimg_legs.height
# Find the parameters we'll use to split the big drawing.
# 'partitions' is an iterator defined by Luxor.
w, h, partitions, gx, gy, dx, dy, ncols, nrows = parameters_for_partitioning(iw, ih; pagewidth, pageheight, gutter_overlap_x, gutter_overlap_y, centre_rot_cw)
for (ptc, n) in partitions
    i, j = partitions.currentrow, partitions.currentcol
    cb = bobox(ptc, dx, Δx, gx, dy, Δy, gy)
    fname = replace(fnam_out(i, j), ".svg" => ".png")
    fname_bg = joinpath("example", "split", "$i $j bg.png")
    ! isfile(fname_bg) && continue
    # Skip if the output file is newer than any of the input
    if isfile(fname)
        latest_input_time = max(mtime(fname_bg), mtime(fsvg_labels), mtime(fsvg_nolabels))
        if mtime(fname) > latest_input_time
            continue 
        end
    end
    r_bg = _read_image(fname_bg)
    w_png = r_bg.width
    h_png = r_bg.height
    w_png_m = 3 * w_png 
    h_png_m = 3 * h_png 
    Drawing(w_png, h_png, fname)
    # Fill the canvas with the background image.
    placeimage(r_bg, centered = false)
    @layer begin
        println(fname)
        # cb is scaled in pts, but we don't care about pts anymore. We
        # can define any unit length we want, and pixels is fine for a bitmap
        w_cb = boxwidth(cb) 
        h_cb = boxheight(cb)
        sc = w_png / boxwidth(cb)
        # We may actually loose a couple of pixels. A better value might be 4350, but still:
        translate(-757   -w_png * (j - 1), 985 - h_png * (i - 1) )
        scale(sc)
        placeimage(rimg_legs)
        placeimage(rimg_labels)
    end
    finish()
end

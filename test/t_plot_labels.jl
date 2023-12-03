# Run after t_world_space.jl and t_draw.jl
# This tests label plotting without going through the normal process of adding
# it in an overlay layer, as 'snap_with_labels' does.

#using Test
#using RouteMap
using RouteMap: plot_prominent_labels_from_paper_space, labels_paper_space, O, snap, encompass
#import LuxorLayout: snap
#using Luxor # TODO Reduce imports later
#using Luxor: snapshot
m = model_activate(;countimage_startvalue = 14)
plot_legs_in_model_space(m, legs)

begin
    model_to_paper_scale = 1
    O_model_in_paper_space = O 
    pslabels = labels_paper_space(m; model_to_paper_scale, O_model_in_paper_space)
end

bbs = plot_prominent_labels_from_paper_space(pslabels; plot_overlapping = true)
# encompass the boundary boxes, so as to include the labels which are now plotted in model space.
encompass.(bbs)
# output 15.svg and 15.png. Here, no overlay is added.
snap()
for l in pslabels
    l.offsetbelow = false
    l.halign = :right
end
m = model_activate(;countimage_startvalue = 15)
plot_legs_in_model_space(m, legs)
bbs = plot_prominent_labels_from_paper_space(pslabels; plot_overlapping = true)
# encompass the boundary boxes, so as to include the labels which are now plotted in model space.
encompass.(bbs)
# output 16.svg and 16.png, labels top right.
snap()

# Let us try again, but this time with an overlay function. We can "fool
# LuxorLabels" by sneaking in our collection of label object through the
# duck-typed arguments which have been intended for text collections, position collections.
# TODO: Move LabelPaperSpace to LuxorLabels, make a better interface. Don't bother with making
# this work fully without updating LuxorLabels.
#=
m = model_activate(;countimage_startvalue = 16)
plot_legs_in_model_space(m, legs)
snap_with_labels(plot_prominent_labels_from_paper_space, pslabels, pslabels, pslabels)
=#
# A small investigation of 'textextents':
m = model_activate();circle(O, 3, :fill);fontsize(102); text("1", O);xb, yb, w, h, _, _ = textextents("1");line(O + (xb, yb), O + (xb + 50, yb), :stroke);line(O + (xb, yb), O + (xb, yb + 70), :stroke);snap()
# => xb = 10, yb = -73
m = model_activate();circle(O, 3, :fill);fontsize(102); text("j", O);xb, yb, w, h, _, _ = textextents("j");line(O + (xb, yb), O + (xb + 50, yb), :stroke);line(O + (xb, yb), O + (xb, yb + 30), :stroke);snap()
# => xb = -6
m = model_activate();circle(O, 3, :fill);fontsize(102); text("2", O);xb, yb, w, h, _, _ = textextents("2");line(O + (xb, yb), O + (xb + 50, yb), :stroke);line(O + (xb, yb), O + (xb, yb + 30), :stroke);snap()
# => xb = 2.0, yb = -73, h = 73
m = model_activate();circle(O, 3, :fill);fontsize(102); text("_", O);xb, yb, w, h, _, _ = textextents("_");line(O + (xb, yb), O + (xb + 50, yb), :stroke);line(O + (xb, yb), O + (xb, yb + 30), :stroke);snap()
# => xb = -2.0, yb = 14, h = 6
m = model_activate();circle(O, 3, :fill);fontsize(102); text("§", O);xb, yb, w, h, _, _ = textextents("§");line(O + (xb, yb), O + (xb + 50, yb), :stroke);line(O + (xb, yb), O + (xb, yb + 30), :stroke);snap()
# => xb = 3.0, yb = -74, h = 96
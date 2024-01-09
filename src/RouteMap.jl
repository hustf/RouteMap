module RouteMap

export Leg, add_or_update_if_not_redundant!, LabelUTM, LabelModelSpace
export model_activate, plot_leg_in_model_space, plot_legs_in_model_space_and_collect_labels_in_model, snap_with_labels
export draw_utm_grid, minimum_model_to_paper_scale_for_non_overlapping_labels
export easting_to_model_x, northing_to_model_y, model_x_to_easting, model_y_to_northing
using LuxorLayout, LuxorLabels, ColorSchemes
using ColorSchemes: Colorant
import Luxor
using Luxor: Drawing, background, setline, settext, BoundingBox
using Luxor: sethue, get_current_color, poly, Point, setcolor, fontsize
using Luxor: @layer, O, textextents, setopacity, text, setdash, line, circle
using Luxor: midpoint, box, boundingboxesintersect
using Luxor: newpath, do_action
import Base: show
import Base.Iterators

"An alias. A conversion of a 'multi_linestring' to numeric nested 3D"
const Mls = Vector{Vector{Tuple{Float64, Float64, Float64}}}


abstract type Label end
"""
Legs exist in the world space, UTM. We don't want
its labels to depend on each model space.
"""
struct LabelUTM <:Label
    text::String
    prominence::Float64
    x::Float64           # "World (UTM) space", easting
    y::Float64           # Northing
end

"""
A label may not be have high enough prominence to be displayed.
The check for that is done by mapping model to paper space.
"""
struct LabelModelSpace <: Label
    text::String
    prominence::Float64
    x::Float64           # "Model space".
    y::Float64           # y points down, opposite of northing.
end

# The input geometry format is 'multi_linestring', kept from data source.
# Those are nested in segments, which are closed intervals: Ends within a leg
# repeats border points. Drop the 'segments' division by calling
# `RouteSlopeDistance.unique_unnested_coordinates_of_multiline_string(mls)`

"""
Leg is used for storing data for drawing a leg on a 2d birds-eye map.

Rules to implement:

1)    A to B and B to A may not exist in the same collection.

2)    Legs may have two paths (multi_linestring), but only if they are not symmetric.

3)    If a Leg with a low-priority label exists in a collection, and
      a leg with equal boundingbox is attempted to be added, then:
      Labels with low prominence are replaced by high prominence labels.

4)    The boundingbox encompasses both paths. It is intended for selecting legs.
"""
struct Leg
    label_A:: LabelUTM
    label_B:: LabelUTM
    bb_utm::BoundingBox
    # World space (utm) horizontal projection
    ABx::Vector{Float64}
    ABy::Vector{Float64}
    BAx::Vector{Float64}
    BAy::Vector{Float64}
end

# TODO: Store labels as LabelUTM, which makes it easier
#       to refer labels to a map.
@kwdef struct ModelSpace
    # Start at 9 leads to first file at 10.
    # Thus, following snapshot will be sorted well in file explorer.
    countimage_startvalue::Int64 = 9
    colorscheme::ColorScheme = ColorSchemes.browncyan
    world_to_model_scale::Float64 = 1.0
    originE::Int64 = 26561
    originN::Int64 = 6940224
    background::Colorant = colorscheme[5]
    linewidth::Float64 = 9.0
    foreground::Colorant = colorscheme[1]
    # Font size for Toy API
    FS = 22
    # The unit EM, as in .css, corresponds to text + margins above and below
    EM = Int(round(FS * 1.16))
    # The paper size default is meant to be printed on A4 portrait.
    # The PostScript standard is 72 pts/inch to cover A4 outside size of 210mm x 297mm
    # There is some approximation in the standard due to 'gutter' margins.
    # 72 dpi is not good enough, but we make vector graphics here, which can
    # be resampled to a bitmap picture of arbitrary resolution (minimum 300 dots per inch?)
    limiting_height::Ref{Int64} = 595
    limiting_width::Ref{Int64} = 842
    # Margins are relevant to 'outside margins' if we make maps covering several pages.
    # The main function is to limit spill-over from labels at the end of routes.
    margin::NamedTuple{(:t, :b, :l, :r), NTuple{4, Int64}} = (t = 54, b = 81, l = 72, r = 72)
    marker_color::Colorant = foreground
    labels::Vector{LabelModelSpace} = LabelModelSpace[]
    utm_grid_size::Int64 = 1000
    utm_grid_thickness::Float64 = 0.5
end

include("utils.jl")
include("world_space.jl")
include("model_space.jl")
include("paper_space.jl")
include("utm_grid.jl")
include("io.jl")
end
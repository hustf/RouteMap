"""
    plot_leg_no_text(m::ModelSpace, l::Leg, markercol)
"""
function plot_leg_no_text(m::ModelSpace, l::Leg)
    leg_pts_nested = map(l.path) do ml
        map(ml) do xyz
            x, y, _ = xyz
            Point((x - m.originE) * m.world_to_model_scale, - (y - m.originN) * m.world_to_model_scale)
        end
    end
    # Draw straight lines between points,
    # road segment by road segment
    for segment in leg_pts_nested
        # Extend ink extents
        encompass.(segment)
        poly(segment, action=:stroke)
    end
    # Mark the 'starting stop' for this leg
    start_pt = leg_pts_nested[1][1]
    @layer begin
        setcolor(m.marker_color)
        circle(start_pt, m.FS / 2, :stroke)
    end
end
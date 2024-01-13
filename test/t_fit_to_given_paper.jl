using Test
using RouteMap
import Luxor
using Luxor: Drawing, O, Point, setcolor, setline, line, background, finish, midpoint, BoundingBox

# Unit grid test
begin
    xmax, ymax = 3000, 5000
    grid = 500
    Drawing(xmax + grid, ymax + grid, "14.png")
    background("gold4")
    setcolor("gold")
    RouteMap.draw_model_grid(grid, ymax, xmax, grid, grid, 0.5) # draw_utm_grid is the exported form.
    # Write the defined drawing file and get rid of the global state Luxor / Cairo canvas.
    finish()
end

# Define some real labels for unit testing. Some appear twice with only prominence differing. We would
# normally avoid by this by defining labels through adding legs and doing some checking.
lbws = LabelUTM[LabelUTM("Årvika ferjekai", 1.0, 13742.0, 6.930773e6), LabelUTM("Grønnevik", 2.0, 11211.0, 6.931634e6), LabelUTM("Grønnevik", 2.0, 11204.0, 6.931669e6), LabelUTM("Larsnes", 2.0, 10796.0, 6.932902e6), LabelUTM("Larsnes ferjekai", 2.0, 10611.0, 6.932987e6), LabelUTM("Larsnes ferjekai", 1.0, 10611.0, 6.932987e6), LabelUTM("Hallebygdskiftet", 2.0, 11181.0, 6.93322e6), LabelUTM("Sandvikskiftet", 2.0, 13575.0, 6.933872e6), LabelUTM("Knottenkrysset", 2.0, 14488.0, 6.933577e6), LabelUTM("Vågen", 2.0, 14969.0, 6.933339e6), LabelUTM("Almestad vest", 2.0, 15853.0, 6.933146e6), LabelUTM("Almestad aust", 2.0, 16512.0, 6.932966e6), LabelUTM("Skoge", 2.0, 17437.0, 6.933383e6), LabelUTM("Seljeset", 2.0, 18192.0, 6.933761e6), LabelUTM("Aurvoll", 2.0, 18503.0, 6.934024e6), LabelUTM("Leikongsætra", 2.0, 21153.0, 6.935686e6), LabelUTM("Leikongbakken", 2.0, 21895.0, 6.935786e6), LabelUTM("Nykrem", 2.0, 23052.0, 6.936736e6), LabelUTM("Djupvika", 2.0, 23293.0, 6.937471e6), LabelUTM("Kjeldsundkrysset", 2.0, 23918.0, 6.938131e6), LabelUTM("Myrvåglomma", 1.0, 23920.0, 6.938919e6), LabelUTM("Fiskå", 1.0, 8244.0, 6.921276e6), LabelUTM("Rusten", 2.0, 9622.0, 6.921538e6), LabelUTM("Storeide sør", 2.0, 11101.0, 6.921507e6), LabelUTM("Storeide nord", 2.0, 12351.0, 6.921295e6), LabelUTM("Lilleeide", 2.0, 12856.0, 6.921216e6), LabelUTM("Leitebakkane", 2.0, 14166.0, 6.921339e6), LabelUTM("Eidså", 1.0, 14598.0, 6.922564e6), LabelUTM("Eidså nord", 2.0, 14709.0, 6.923306e6), LabelUTM("Øyra", 2.0, 14958.0, 6.924092e6), LabelUTM("Sannes", 2.0, 14870.0, 6.925321e6), LabelUTM("Sannes Reitabakken", 2.0, 14656.0, 6.925664e6), LabelUTM("Lid", 2.0, 14433.0, 6.926406e6), LabelUTM("Koparneset ferjekai", 1.0, 13871.0, 6.928275e6), LabelUTM("Gursken oppvekstsenter", 2.0, 15021.0, 6.93346e6), LabelUTM("Leikong", 2.0, 22263.0, 6.935849e6), LabelUTM("Myrvåglomma", 2.0, 23920.0, 6.938919e6), LabelUTM("Dragsund sør", 2.0, 24823.0, 6.939041e6), LabelUTM("Garneskrysset", 1.0, 26453.0, 6.94012e6), LabelUTM("Garneskrysset", 2.0, 26453.0, 6.94012e6), LabelUTM("Garnes nord", 2.0, 26545.0, 6.940333e6), LabelUTM("Botnen", 2.0, 26807.0, 6.941535e6), LabelUTM("Strandabøen", 2.0, 27809.0, 6.944171e6), LabelUTM("Saunes sør", 2.0, 27558.0, 6.944745e6), LabelUTM("Saunes nord", 2.0, 27458.0, 6.945077e6), LabelUTM("Ulsteinvik skysstasjon", 2.0, 27266.0, 6.945717e6), LabelUTM("Ulsteinvik skysstasjon", 2.0, 27224.0, 6.945781e6), LabelUTM("Holsekerdalen", 2.0, 27716.0, 6.94561e6), LabelUTM("Støylesvingen", 2.0, 28276.0, 6.94529e6), LabelUTM("Ulstein vgs.", 1.0, 28962.0, 6.945247e6), LabelUTM("Åheim", 1.0, 5825.0, 6.914413e6), LabelUTM("Torvik", 2.0, 5860.0, 6.915186e6), LabelUTM("Slagnes kryss", 2.0, 6039.0, 6.917888e6), LabelUTM("Vik vest", 2.0, 7287.0, 6.918367e6), LabelUTM("Vik øst", 2.0, 7839.0, 6.917746e6), LabelUTM("Kråkenes nord", 2.0, 9205.0, 6.917399e6), LabelUTM("Kråkenes sør", 2.0, 9769.0, 6.916996e6), LabelUTM("Eikrem nord", 2.0, 9808.0, 6.916191e6), LabelUTM("Eikrem sør", 2.0, 10167.0, 6.915262e6), LabelUTM("Sylte", 2.0, 10760.0, 6.915396e6), LabelUTM("Sylte gamle skule", 2.0, 10945.0, 6.915786e6), LabelUTM("Vidnes", 2.0, 10952.0, 6.91631e6), LabelUTM("Lillebø", 2.0, 11203.0, 6.917425e6), LabelUTM("Bøstranda", 2.0, 10389.0, 6.918886e6), LabelUTM("Tunheim sør", 2.0, 9433.0, 6.919387e6), LabelUTM("Tunheim nord", 2.0, 9098.0, 6.919671e6), LabelUTM("Låtra", 2.0, 9008.0, 6.920242e6), LabelUTM("Tussa", 2.0, 9123.0, 6.920712e6), LabelUTM("Fiskå", 2.0, 8244.0, 6.921276e6), LabelUTM("Fiskå skule", 2.0, 8790.0, 6.921265e6), LabelUTM("Ulstein vgs.", 2.0, 28962.0, 6.945247e6), LabelUTM("Varleitekrysset", 2.0, 29426.0, 6.945336e6), LabelUTM("Rise vest", 2.0, 31167.0, 6.94606e6), LabelUTM("Rise", 2.0, 31514.0, 6.946168e6), LabelUTM("Rise aust", 2.0, 31909.0, 6.946302e6), LabelUTM("Korshaug", 2.0, 32344.0, 6.94636e6), LabelUTM("Nybøen", 2.0, 32852.0, 6.94645e6), LabelUTM("Byggeli", 2.0, 33142.0, 6.946489e6), LabelUTM("Bigsetkrysset", 2.0, 33729.0, 6.946682e6), LabelUTM("Bjåstad vest", 2.0, 34053.0, 6.946888e6), LabelUTM("Bjåstad aust", 2.0, 34417.0, 6.947107e6), LabelUTM("Grimstad vest", 2.0, 34866.0, 6.947308e6), LabelUTM("Grimstad aust", 2.0, 35465.0, 6.947466e6), LabelUTM("Holstad", 2.0, 35983.0, 6.947674e6), LabelUTM("Hareid ungdomsskule fv. 61", 2.0, 36533.0, 6.947583e6), LabelUTM("Hareid bussterminal", 1.0, 36943.0, 6.947662e6), LabelUTM("Hareid bussterminal", 1.0, 36975.0, 6.947631e6), LabelUTM("Hareid ferjekai", 2.0, 37005.0, 6.947595e6), LabelUTM("Sulesund ferjekai", 2.0, 44295.0, 6.949434e6), LabelUTM("Eikrem sør", 2.0, 48441.0, 6.949923e6), LabelUTM("Eikrem", 2.0, 48929.0, 6.950292e6), LabelUTM("Grova", 2.0, 49632.0, 6.951143e6), LabelUTM("Mauseidvåg", 2.0, 50213.0, 6.951497e6), LabelUTM("Furneset", 2.0, 50540.0, 6.951645e6), LabelUTM("Veibust", 2.0, 54399.0, 6.951913e6), LabelUTM("Vegsund", 2.0, 54831.0, 6.952519e6), LabelUTM("Urdalen", 2.0, 55101.0, 6.953046e6), LabelUTM("Moa trafikkterminal", 2.0, 54967.0, 6.956088e6), LabelUTM("Moa trafikkterminal", 2.0, 54923.0, 6.956123e6), LabelUTM("Vindgårdskiftet", 2.0, 54522.0, 6.95591e6), LabelUTM("Furmyrhagen", 2.0, 54188.0, 6.955953e6), LabelUTM("Åse", 2.0, 53608.0, 6.956114e6), LabelUTM("Ålesund sjukehus", 1.0, 53072.0, 6.95601e6), LabelUTM("Leikong kyrkje", 2.0, 22265.0, 6.936069e6), LabelUTM("Breivik", 2.0, 11215.0, 6.931462e6), LabelUTM("Vikane", 2.0, 51568.0, 6.951637e6), LabelUTM("Måseide skule", 2.0, 50059.0, 6.951684e6), LabelUTM("Båtnes", 2.0, 46914.0, 6.949437e6), LabelUTM("Hareid bussterminal", 2.0, 36943.0, 6.947662e6), LabelUTM("Dimnakrysset", 2.0, 27721.0, 6.943086e6), LabelUTM("Møre barne- og ungdomsskule", 2.0, 24064.0, 6.93904e6), LabelUTM("Ulstein rådhus", 2.0, 27018.0, 6.946077e6), LabelUTM("Kongsberg Maritime Ulsteinvik", 2.0, 26714.0, 6.946197e6), LabelUTM("Ulstein Verft", 2.0, 25931.0, 6.945971e6), LabelUTM("Ulstein Propeller", 2.0, 26483.0, 6.946219e6)]
lbms = LabelModelSpace[LabelModelSpace("Årvika ferjekai", 1.0, -12819.0, 9451.0), LabelModelSpace("Grønnevik", 2.0, -15350.0, 8590.0), LabelModelSpace("Grønnevik", 2.0, -15357.0, 8555.0), LabelModelSpace("Larsnes", 2.0, -15765.0, 7322.0), LabelModelSpace("Larsnes ferjekai", 2.0, -15950.0, 7237.0), LabelModelSpace("Larsnes ferjekai", 1.0, -15950.0, 7237.0), LabelModelSpace("Hallebygdskiftet", 2.0, -15380.0, 7004.0), LabelModelSpace("Sandvikskiftet", 2.0, -12986.0, 6352.0), LabelModelSpace("Knottenkrysset", 2.0, -12073.0, 6647.0), LabelModelSpace("Vågen", 2.0, -11592.0, 6885.0), LabelModelSpace("Almestad vest", 2.0, -10708.0, 7078.0), LabelModelSpace("Almestad aust", 2.0, -10049.0, 7258.0), LabelModelSpace("Skoge", 2.0, -9124.0, 6841.0), LabelModelSpace("Seljeset", 2.0, -8369.0, 6463.0), LabelModelSpace("Aurvoll", 2.0, -8058.0, 6200.0), LabelModelSpace("Leikongsætra", 2.0, -5408.0, 4538.0), LabelModelSpace("Leikongbakken", 2.0, -4666.0, 4438.0), LabelModelSpace("Nykrem", 2.0, -3509.0, 3488.0), LabelModelSpace("Djupvika", 2.0, -3268.0, 2753.0), LabelModelSpace("Kjeldsundkrysset", 2.0, -2643.0, 2093.0), LabelModelSpace("Myrvåglomma", 1.0, -2641.0, 1305.0), LabelModelSpace("Fiskå", 1.0, -18317.0, 18948.0), LabelModelSpace("Rusten", 2.0, -16939.0, 18686.0), LabelModelSpace("Storeide sør", 2.0, -15460.0, 18717.0), LabelModelSpace("Storeide nord", 2.0, -14210.0, 18929.0), LabelModelSpace("Lilleeide", 2.0, -13705.0, 19008.0), LabelModelSpace("Leitebakkane", 2.0, -12395.0, 18885.0), LabelModelSpace("Eidså", 1.0, -11963.0, 17660.0), LabelModelSpace("Eidså nord", 2.0, -11852.0, 16918.0), LabelModelSpace("Øyra", 2.0, -11603.0, 16132.0), LabelModelSpace("Sannes", 2.0, -11691.0, 14903.0), LabelModelSpace("Sannes Reitabakken", 2.0, -11905.0, 14560.0), LabelModelSpace("Lid", 2.0, -12128.0, 13818.0), LabelModelSpace("Koparneset ferjekai", 1.0, -12690.0, 11949.0), LabelModelSpace("Gursken oppvekstsenter", 2.0, -11540.0, 6764.0), LabelModelSpace("Leikong", 2.0, -4298.0, 4375.0), LabelModelSpace("Myrvåglomma", 2.0, -2641.0, 1305.0), LabelModelSpace("Dragsund sør", 2.0, -1738.0, 1183.0), LabelModelSpace("Garneskrysset", 1.0, -108.0, 104.0), LabelModelSpace("Garneskrysset", 2.0, -108.0, 104.0), LabelModelSpace("Garnes nord", 2.0, -16.0, -109.0), LabelModelSpace("Botnen", 2.0, 246.0, -1311.0), LabelModelSpace("Strandabøen", 2.0, 1248.0, -3947.0), LabelModelSpace("Saunes sør", 2.0, 997.0, -4521.0), LabelModelSpace("Saunes nord", 2.0, 897.0, -4853.0), LabelModelSpace("Ulsteinvik skysstasjon", 2.0, 705.0, -5493.0), LabelModelSpace("Ulsteinvik skysstasjon", 2.0, 663.0, -5557.0), LabelModelSpace("Holsekerdalen", 2.0, 1155.0, -5386.0), LabelModelSpace("Støylesvingen", 2.0, 1715.0, -5066.0), LabelModelSpace("Ulstein vgs.", 1.0, 2401.0, -5023.0), LabelModelSpace("Åheim", 1.0, -20736.0, 25811.0), LabelModelSpace("Torvik", 2.0, -20701.0, 25038.0), LabelModelSpace("Slagnes kryss", 2.0, -20522.0, 22336.0), LabelModelSpace("Vik vest", 2.0, -19274.0, 21857.0), LabelModelSpace("Vik øst", 2.0, -18722.0, 22478.0), LabelModelSpace("Kråkenes nord", 2.0, -17356.0, 22825.0), LabelModelSpace("Kråkenes sør", 2.0, -16792.0, 23228.0), LabelModelSpace("Eikrem nord", 2.0, -16753.0, 24033.0), LabelModelSpace("Eikrem sør", 2.0, -16394.0, 24962.0), LabelModelSpace("Sylte", 2.0, -15801.0, 24828.0), LabelModelSpace("Sylte gamle skule", 2.0, -15616.0, 24438.0), LabelModelSpace("Vidnes", 2.0, -15609.0, 23914.0), LabelModelSpace("Lillebø", 2.0, -15358.0, 22799.0), LabelModelSpace("Bøstranda", 2.0, -16172.0, 21338.0), LabelModelSpace("Tunheim sør", 2.0, -17128.0, 20837.0), LabelModelSpace("Tunheim nord", 2.0, -17463.0, 20553.0), LabelModelSpace("Låtra", 2.0, -17553.0, 19982.0), LabelModelSpace("Tussa", 2.0, -17438.0, 19512.0), LabelModelSpace("Fiskå", 2.0, -18317.0, 18948.0), LabelModelSpace("Fiskå skule", 2.0, -17771.0, 18959.0), LabelModelSpace("Ulstein vgs.", 2.0, 2401.0, -5023.0), LabelModelSpace("Varleitekrysset", 2.0, 2865.0, -5112.0), LabelModelSpace("Rise vest", 2.0, 4606.0, -5836.0), LabelModelSpace("Rise", 2.0, 4953.0, -5944.0), LabelModelSpace("Rise aust", 2.0, 5348.0, -6078.0), LabelModelSpace("Korshaug", 2.0, 5783.0, -6136.0), LabelModelSpace("Nybøen", 2.0, 6291.0, -6226.0), LabelModelSpace("Byggeli", 2.0, 6581.0, -6265.0), LabelModelSpace("Bigsetkrysset", 2.0, 7168.0, -6458.0), LabelModelSpace("Bjåstad vest", 2.0, 7492.0, -6664.0), LabelModelSpace("Bjåstad aust", 2.0, 7856.0, -6883.0), LabelModelSpace("Grimstad vest", 2.0, 8305.0, -7084.0), LabelModelSpace("Grimstad aust", 2.0, 8904.0, -7242.0), LabelModelSpace("Holstad", 2.0, 9422.0, -7450.0), LabelModelSpace("Hareid ungdomsskule fv. 61", 2.0, 9972.0, -7359.0), LabelModelSpace("Hareid bussterminal", 1.0, 10382.0, -7438.0), LabelModelSpace("Hareid bussterminal", 1.0, 10414.0, -7407.0), LabelModelSpace("Hareid ferjekai", 2.0, 10444.0, -7371.0), LabelModelSpace("Sulesund ferjekai", 2.0, 17734.0, -9210.0), LabelModelSpace("Eikrem sør", 2.0, 21880.0, -9699.0), LabelModelSpace("Eikrem", 2.0, 22368.0, -10068.0), LabelModelSpace("Grova", 2.0, 23071.0, -10919.0), LabelModelSpace("Mauseidvåg", 2.0, 23652.0, -11273.0), LabelModelSpace("Furneset", 2.0, 23979.0, -11421.0), LabelModelSpace("Veibust", 2.0, 27838.0, -11689.0), LabelModelSpace("Vegsund", 2.0, 28270.0, -12295.0), LabelModelSpace("Urdalen", 2.0, 28540.0, -12822.0), LabelModelSpace("Moa trafikkterminal", 2.0, 28406.0, -15864.0), LabelModelSpace("Moa trafikkterminal", 2.0, 28362.0, -15899.0), LabelModelSpace("Vindgårdskiftet", 2.0, 27961.0, -15686.0), LabelModelSpace("Furmyrhagen", 2.0, 27627.0, -15729.0), LabelModelSpace("Åse", 2.0, 27047.0, -15890.0), LabelModelSpace("Ålesund sjukehus", 1.0, 26511.0, -15786.0), LabelModelSpace("Leikong kyrkje", 2.0, -4296.0, 4155.0), LabelModelSpace("Breivik", 2.0, -15346.0, 8762.0), LabelModelSpace("Vikane", 2.0, 25007.0, -11413.0), LabelModelSpace("Måseide skule", 2.0, 23498.0, -11460.0), LabelModelSpace("Båtnes", 2.0, 20353.0, -9213.0), LabelModelSpace("Hareid bussterminal", 2.0, 10382.0, -7438.0), LabelModelSpace("Dimnakrysset", 2.0, 1160.0, -2862.0), LabelModelSpace("Møre barne- og ungdomsskule", 2.0, -2497.0, 1184.0), LabelModelSpace("Ulstein rådhus", 2.0, 457.0, -5853.0), LabelModelSpace("Kongsberg Maritime Ulsteinvik", 2.0, 153.0, -5973.0), LabelModelSpace("Ulstein Verft", 2.0, -630.0, -5747.0), LabelModelSpace("Ulstein Propeller", 2.0, -78.0, -5995.0)]
# For drawing something in model space...
model = model_activate(;labels = lbws, countimage_startvalue = 14)
for l in lbms
    draw_and_encompass_circle(model, Point(l.x, l.y))
end

draw_utm_grid(model)
# Show just what's currently on the model canvas in ink extent
snap() # 15.svg and png, almost invisible grid. Overwritten below.
# Clear the canvas, keep settings, reset countimage
model_activate(model)
# This time we don't add anything to model space before snapping. 
# Hence, ink extent corresponds to paper space without margins,
# and taking a snapshot with a label overlay just displays the labels that happes to be close to origin. 
# Default paper space size 595x842 points reflects 595x842 meter.
snap_with_labels(model; draw_grid = true)  # 15.svg, overwrites previous
@test world_to_paper_factor(model) == 1.0
# Plotting regardless of label overlap may help track down mistakes (not in this case;
# we explicitly defined two 'Garneskrysset' labels, but with different prominence values.)
snap_with_labels(model; draw_grid = true, plot_overlapping = true) # 16
# Extend ink extents to encompass all labels.
for lbm in lbms
    encompass(Point(lbm.x, lbm.y))
end
@test world_to_paper_factor(model) ≈ 0.011028530328458403
snap_with_labels(model) # 17.svg

# Legs are made by calling this package's Leg generator:
leg = Leg(; text_A = "Kjeldsundkrysset", prominence_A = 2.0, text_B = "Myrvåglomma", prominence_B = 1.0, ABx = [23917.965, 23926.41, 23939.59, 23954.8, 23962.59, 23976.41, 23995.5, 24010.09, 24026.09, 24041.41, 24057.2, 24073.81, 24090.41, 24103.91, 24118.91, 24136.2, 24147.91, 24157.41, 24164.59, 24170.0, 24172.59, 24174.0, 24173.8, 24172.2, 24168.91, 24163.0, 24156.41, 24148.3, 24138.0, 24130.59, 24123.59, 24118.3, 24114.5, 24112.8, 24111.3, 24110.539, 24110.239, 24109.795, 24109.742, 24109.861, 24104.116, 24098.469, 24081.7, 24061.017, 24041.139, 24034.754, 24020.573, 24005.59, 23986.7, 23969.91, 23954.139, 23938.487, 23939.0, 23939.234, 23940.3, 23941.8, 23943.3, 23934.41, 23928.09, 23921.59, 23920.063, 23919.301, 23919.005, 23918.786, 23920.251], ABy = [6.938131025e6, 6.9381427e6, 6.9381612e6, 6.9381805e6, 6.9381925e6, 6.938212e6, 6.9382379e6, 6.938258e6, 6.93828e6, 6.9383013e6, 6.9383232e6, 6.93834657e6, 6.9383687e6, 6.9383877e6, 6.9384085e6, 6.9384329e6, 6.93845e6, 6.9384659e6, 6.9384815e6, 6.9384979e6, 6.9385115e6, 6.938525e6, 6.9385384e6, 6.9385506e6, 6.9385657e6, 6.9385859e6, 6.9386075e6, 6.9386335e6, 6.9386672e6, 6.9386908e6, 6.9387155e6, 6.9387383e6, 6.9387587e6, 6.938773e6, 6.9387877e6, 6.938801e6, 6.9388131e6, 6.938824554e6, 6.938834254e6, 6.938857893e6, 6.938857792e6, 6.938857894e6, 6.938858248e6, 6.938859114e6, 6.938860226e6, 6.938860774e6, 6.938861961e6, 6.938863214e6, 6.9388655e6, 6.938867394e6, 6.938869616e6, 6.938872407e6, 6.9388742e6, 6.938875684e6, 6.9388861e6, 6.9388933e6, 6.938902e6, 6.9389018e6, 6.9389011e6, 6.9389e6, 6.9388998e6, 6.938904282e6, 6.938907309e6, 6.938911747e6, 6.938919173e6], BAx = [23920.251, 23918.786, 23919.005, 23919.301, 23920.063, 23921.59, 23928.09, 23934.41, 23943.3, 23941.8, 23940.3, 23939.234, 23939.0, 23938.487, 23954.139, 23969.91, 23986.7, 24005.59, 24020.573, 24034.754, 24041.139, 24061.017, 24081.7, 24098.469, 24104.116, 24109.861, 24109.742, 24109.795, 24110.239, 24110.539, 24111.3, 24112.8, 24114.5, 24118.3, 24123.59, 24130.59, 24138.0, 24148.3, 24156.41, 24163.0, 24168.91, 24172.2, 24173.8, 24174.0, 24172.59, 24170.0, 24164.59, 24157.41, 24147.91, 24136.2, 24118.91, 24103.91, 24090.41, 24073.81, 24057.2, 24041.41, 24026.09, 24010.09, 23995.5, 23976.41, 23962.59, 23954.8, 23939.59, 23926.41, 23917.965], BAy = [6.938919173e6, 6.938911747e6, 6.938907309e6, 6.938904282e6, 6.9388998e6, 6.9389e6, 6.9389011e6, 6.9389018e6, 6.938902e6, 6.9388933e6, 6.9388861e6, 6.938875684e6, 6.9388742e6, 6.938872407e6, 6.938869616e6, 6.938867394e6, 6.9388655e6, 6.938863214e6, 6.938861961e6, 6.938860774e6, 6.938860226e6, 6.938859114e6, 6.938858248e6, 6.938857894e6, 6.938857792e6, 6.938857893e6, 6.938834254e6, 6.938824554e6, 6.9388131e6, 6.938801e6, 6.9387877e6, 6.938773e6, 6.9387587e6, 6.9387383e6, 6.9387155e6, 6.9386908e6, 6.9386672e6, 6.9386335e6, 6.9386075e6, 6.9385859e6, 6.9385657e6, 6.9385506e6, 6.9385384e6, 6.938525e6, 6.9385115e6, 6.9384979e6, 6.9384815e6, 6.9384659e6, 6.93845e6, 6.9384329e6, 6.9384085e6, 6.9383877e6, 6.9383687e6, 6.93834657e6, 6.9383232e6, 6.9383013e6, 6.93828e6, 6.938258e6, 6.9382379e6, 6.938212e6, 6.9381925e6, 6.9381805e6, 6.9381612e6, 6.9381427e6, 6.938131025e6])
legs = [leg]
# New model, but copy the labels from previous mode. Clear canvas.
model = model_activate(; labels = model.labels, countimage_startvalue = 17)
# We need to remove some existing labels before adding labels from a new leg,
# or we would get assertion errors from overlapping labels:
remove_indices = findall(l -> l.text == "Kjeldsundkrysset" || l.text == "Myrvåglomma", model.labels)
splice!(model.labels, remove_indices)
# Plot a detailed leg in model space and add those labels we just removed.
plot_legs_in_model_space_and_collect_labels_in_model!(model, legs)
# Show just what's currently on the model canvas in ink extent
snap() #18
# We want to draw lines between labels in sequence. It will be a mess, but we can improve the mess
# by sorting labels!
sort_by_vector!(model.labels, 1, 0.8)
# Add some straight lines in model space between label anchors.
function draw_lines_btw()
    x0, y0 = 0.0, 0.0
    setline(10)
    setcolor("green")
    for lbw in model.labels
        x = easting_to_model_x(model, lbw.x)
        y = northing_to_model_y(model, lbw.y)
        if (x0, y0) !== (0.0, 0.0)
            pt0, pt1 = Point(x0, y0), Point(x, y)
            draw_and_encompass_circle(model, pt0) 
            draw_and_encompass_circle(model, pt1) 
            line(pt0, pt1, action=:stroke)
            encompass([pt0, pt1])
        end
        x0, y0 = x, y
    end
end
draw_lines_btw()
# Show just what's currently on the model canvas in ink extent
snap() #19
@test abs(world_to_paper_factor(model) - 0.011028530328458403) < 0.00001
snap_with_labels(model; draw_grid = true, plot_overlapping = true) #20
# Get rid of the global state Luxor / Cairo canvas.
finish()
# We can see from the messy output how label placement is a problem if paper space has limits.



# Tiny example plot from README.md 

model = model_activate(; countimage_startvalue = 20)
leg = Leg(; text_A = "Kjeldsundkrysset", prominence_A = 2.0, text_B = "Myrvåglomma", prominence_B = 1.0, 
    ABx = [22217.965, 22226.41, 23920.251], ABy = [6.938131025e6, 6.9381427e6, 6.938919173e6])
legs = [leg];
plot_legs_in_model_space_and_collect_labels_in_model!(model, legs) # This plots the path geometry and updates model's `label` collection
snap() # Show just what's currently on the model canvas in ink extent. 21
snap_with_labels(model) # 22
# Get rid of the global state Luxor / Cairo canvas.
finish()



nothing

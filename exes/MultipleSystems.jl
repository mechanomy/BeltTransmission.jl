# This is the Multiple Systems example from https://mechanomy.github.io/BeltTransmission.jl/dev/#Multiple-systems

using Unitful, Plots
using Geometry2D
using BeltTransmission

#create the pulleys
pA = PlainPulley( pitch=Geometry2D.Circle( 10u"mm",  20u"mm", 20u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")
pB = PlainPulley( pitch=Geometry2D.Circle(100u"mm",  20u"mm", 30u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")

pX = PlainPulley( pitch=Geometry2D.Circle( 10u"mm",  20u"mm", 15u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="X")
pY = PlainPulley( pitch=Geometry2D.Circle( 50u"mm",  80u"mm",  5u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="Y")

#create the belt systems
segAB = route2Segments( calculateRouteAngles( [pA, pB] ))
segXY = route2Segments( calculateRouteAngles( [pX, pY] ))

plot( segAB, title="Parallel Systems", xlabel="[mm]", ylabel="[mm]", xlims=([-50,150]), ylims=([-50,100]), legend=false, dpi=100, size=(1000,500))
plot!(segXY, segmentColor=:cyan)
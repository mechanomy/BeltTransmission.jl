# This is the various pulleys example from https://mechanomy.github.io/BeltTransmission.jl/dev/#A-variety-of-pulleys

using Unitful, Plots
using Geometry2D
using BeltTransmission

#create the pulleys
ctrA = Geometry2D.Point(10u"mm", 10u"mm")
pA = PlainPulley( pitch=Geometry2D.Circle( center=ctrA, radius=10u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="A")
pB = PlainPulley( pitch=Geometry2D.Circle(100u"mm",  20u"mm", 20u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")
pC = PlainPulley( pitch=Geometry2D.Circle( 80u"mm",  40u"mm",  5u"mm"), axis=-Geometry2D.UnitVector(0,0,1), name="C")
pD = PlainPulley( pitch=Geometry2D.Circle(150u"mm",  40u"mm",  5u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="D")
pE = PlainPulley( pitch=Geometry2D.Circle(100u"mm",  80u"mm",  5u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="E")

#create the belt route
route = [pA, pB, pC, pD, pE]

#solve the departure and arrival angles on each PlainPulley
solved = calculateRouteAngles(route)

#create belt Segments between the Pulleys
segments = route2Segments(solved)

plot(segments, title="Various Pulleys" )
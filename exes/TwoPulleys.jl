# This is the same example as https://mechanomy.github.io/BeltTransmission.jl/dev/#Two-pulleys

using Unitful, Plots
using Geometry2D 
using BeltTransmission

#create the pulleys
ctrA = Geometry2D.Point(10u"mm", 10u"mm")
pA = PlainPulley( pitch=Geometry2D.Circle( center=ctrA, radius=10u"mm"), axis=Geometry2D.uk, name="A")
pB = PlainPulley( pitch=Geometry2D.Circle(100u"mm", 100u"mm", 20u"mm"), axis=Geometry2D.uk, name="B")

#create the belt route
route = [pA, pB] #from A to B and back to A

#solve the departure and arrival angles on each PlainPulley
solved = calculateRouteAngles(route)

#create belt Segments between the Pulleys
segments = route2Segments(solved)
beltLength = calculateBeltLength(segments)

plot(segments, title="two pulleys")
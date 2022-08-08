# Modeling Planar Belt Transmissions

[GitHub source](https://github.com/mechanomy/BeltTransmission.jl)

## Background
Belt transmissions involve several moving elements and a variety of materials, enabling flexible power transmission but leading to complex and interdependent system design requirements.
The basic performance of a candidate belt transmission can be estimated from kinematic analysis, while a dynamic simulation can give a much better idea of actual system performance and limits.

This Julia package assists users in the kinematic analysis, designing belt transmissions using flat or synchronous belts.
Primary structures model pulleys and belt segments, these can be analyzed and plotted through recipes for [Plots.jl](https://docs.juliaplots.org/stable/).
BeltTransmission was used to determine the basic design of the [Moover variants](https://mechanomy.com/projects/moover).

See the package [readme](https://github.com/mechanomy/BeltTransmission.jl) for release, license, and development information.

## Installation
```julia
using Pkg
Pkg.add("https://github.com/mechanomy/BeltTransmission.jl.git")
```

## Use Cases
Designing a planar belt transmission is the primary use case for BeltTransmission, but this design can have several objectives according to what is already known about the system.
If the positions, sizes, and belt routing are known, these can be entered to calculate belt length and arrival and departure angles on each pulley.
BeltTransmission can also be used to solve systems for other unknowns, say to determine the position of an idler pulley given a known belt length.

### Basic belt transmissions
The goal of these examples is to calculate the belt length given pulley sizes and locations.

#### Two pulleys
```@example twopulleys; continued=false
using Unitful, Plots
using Geometry2D 
using BeltTransmission

#create the pulleys
ctrA = Geometry2D.Point(10u"mm", 10u"mm")
pA = PlainPulley( circle=Geometry2D.Circle( center=ctrA, radius=10u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="A")
pB = PlainPulley( circle=Geometry2D.Circle(100u"mm", 100u"mm", 20u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")

#create the belt route
route = [pA, pB] #from A to B and back to A

#solve the departure and arrival angles on each PlainPulley
solved = calculateRouteAngles(route)

#create belt Segments between the Pulleys
segments = route2Segments(solved)
beltLength = calculateBeltLength(segments)

plot(segments, title="two pulleys")
```

By convention, Pulleys having a positive rotation (+uk) have a dot at their center to indicate the vector's tip, while negative rotation is shown with an X for the arrow's fletching.
Once solved, the system can be interrogated:

```@example twopulleys
calculateBeltLength(segments)
```

#### A variety of pulleys
```@example variety;
using Unitful, Plots
using Geometry2D 
using BeltTransmission

#create the pulleys
ctrA = Geometry2D.Point(10u"mm", 10u"mm")
pA = PlainPulley( circle=Geometry2D.Circle( center=ctrA, radius=10u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="A")
pB = PlainPulley( circle=Geometry2D.Circle(100u"mm",  20u"mm", 20u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")
pC = PlainPulley( circle=Geometry2D.Circle( 80u"mm",  40u"mm",  5u"mm"), axis=-Geometry2D.UnitVector(0,0,1), name="C")
pD = PlainPulley( circle=Geometry2D.Circle(150u"mm",  40u"mm",  5u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="D")
pE = PlainPulley( circle=Geometry2D.Circle(100u"mm",  80u"mm",  5u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="E")

#create the belt route
route = [pA, pB, pC, pD, pE]

#solve the departure and arrival angles on each PlainPulley
solved = calculateRouteAngles(route)

#create belt Segments between the Pulleys
segments = route2Segments(solved)

plot(segments, title="Various Pulleys" )
```

```@repl variety;
calculateBeltLength(segments)
```
```@repl variety;
printSegments(segments)
```
Positive rotation of PlainPulley A will cause PlainPulley C to rotate negatively, hence the negative rotation `axis` on C.
In addition to the PlainPulley rotation axis, the point of departure on each PlainPulley is given a slight arrow in the direction of positive belt rotation.

#### Multiple systems
```@example
using Unitful, Plots
using Geometry2D 
using BeltTransmission

#create the pulleys
pA = PlainPulley( circle=Geometry2D.Circle( 10u"mm",  20u"mm", 20u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")
pB = PlainPulley( circle=Geometry2D.Circle(100u"mm",  20u"mm", 30u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")

pX = PlainPulley( circle=Geometry2D.Circle( 10u"mm",  20u"mm", 15u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="X")
pY = PlainPulley( circle=Geometry2D.Circle( 50u"mm",  80u"mm",  5u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="Y")

#create the belt systems 
segAB = route2Segments( calculateRouteAngles( [pA, pB] ))
segXY = route2Segments( calculateRouteAngles( [pX, pY] ))

plot( segAB, title="Parallel Systems", xlabel="[mm]", ylabel="[mm]", xlims=([-50,150]), ylims=([-50,100]), legend=false, dpi=100, size=(1000,500)) 
plot!(segXY, segmentColor=:cyan)
```

PlainPulley body colors are assigned by the default colormap, but `segmentColor` may be used to control the belt segment color.
Other [Plots.jl attributes](https://docs.juliaplots.org/latest/generated/attributes_plot/) may be used as expected.


## Development Plan
BeltTransmission.jl is under active development, [enhancement requests](https://github.com/mechanomy/BeltTransmission.jl/issues/new/choose) are welcome.

## API
```@meta
CurrentModule= BeltTransmission
```

```@autodocs
Modules=[BeltTransmission]
```
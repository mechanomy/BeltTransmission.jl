# Modeling Planar Belt Transmissions

## Installation

## Dependencies

## Background
Belt transmissions involve several moving elements and a variety of materials, enabling flexible power transmission but leading to complex and interdependent system design requirements.
The basic performance of a candidate belt transmission can be estimated from kinematic analysis, while a dynamic simulation can give a much better idea of actual system performance and limits.

This Julia package assists users in designing belt transmissions using flat or synchronous belts.
Primary structures model [Pulley](#BeltTransmission.Pulley) and belt [Segment](#BeltTransmission.Segment)s, these can be analyzed and plotted through recipes for [Plots.jl](https://docs.juliaplots.org/stable/).
BeltTransmission was used to determine the basic design of the [Moover variants](https://mechanomy.com/projects/moover).

See the [package readme](https://github.com/mechanomy/BeltTransmission.jl/readme.md) for release, license, and development information.

## Use Cases
Designing a planar belt transmission is the primary use case for BeltTransmission, but this design can have several objectives according to what is already known about the system.
If the positions, sizes, and belt routing are known, these can be entered to calculate belt length and arrival and departure angles on each pulley.
This is the basis of the [first use case](#Two-pulleys).

<!-- Open belt systems can also be calculated, at least t -->

For most systems the belt length and arrival and departure angles are unknown.
If the belt length is known, the angles and some other quantity can be found.
This often occurs when the belt length 
This is the case when the pulleys are known 
Optimization of the belt transmission involves solving for some 

### Basic belt transmissions
The goal of these two examples is to calculate the belt length given pulley sizes and locations.

#### Two pulleys
```@example
using Unitful, Plots
using Geometry2D 
using BeltTransmission

#create the pulleys
ctrA = Geometry2D.Point(10u"mm", 10u"mm")
pA = Pulley( circle=Geometry2D.Circle( center=ctrA, radius=10u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="A")
pB = Pulley( circle=Geometry2D.Circle(100u"mm", 100u"mm", 20u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")

#create the belt route
route = [pA, pB] #from A to B and back to A

#solve the departure and arrival angles on each Pulley
solved = calculateRouteAngles(route)

#create belt Segments between the Pulleys
segments = route2Segments(solved)
beltLength = calculateBeltLength(segments)

plot(segments, title="length = $beltLength" )
```
By convention, Pulleys having a positive rotation (+uk) have a dot at their center to indicate the vector's tip, while negative rotation is shown with an X for the arrow's fletching.

#### A variety of pulleys
```@example
using Unitful, Plots
using Geometry2D 
using BeltTransmission

#create the pulleys
ctrA = Geometry2D.Point(10u"mm", 10u"mm")
pA = Pulley( circle=Geometry2D.Circle( center=ctrA, radius=10u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="A")
pB = Pulley( circle=Geometry2D.Circle(100u"mm",  20u"mm", 20u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")
pC = Pulley( circle=Geometry2D.Circle( 80u"mm",  40u"mm",  5u"mm"), axis=-Geometry2D.UnitVector(0,0,1), name="C")
pD = Pulley( circle=Geometry2D.Circle(150u"mm",  40u"mm",  5u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="D")
pE = Pulley( circle=Geometry2D.Circle(100u"mm",  80u"mm",  5u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="E")

#create the belt route
route = [pA, pB, pC, pD, pE]

#solve the departure and arrival angles on each Pulley
solved = calculateRouteAngles(route)

#create belt Segments between the Pulleys
segments = route2Segments(solved)

beltLength = calculateBeltLength(segments)
plot(segments, title="length = $beltLength" )
```
Positive rotation of pulley A will cause pulley C to rotate negatively, hence the negative rotation `axis` on C.
In addition to the pulley rotation axis, the point of departure on each Pulley is given a slight arrow in the direction of positive belt rotation.

#### Parallel systems
```@example
using Unitful, Plots
using Geometry2D 
using BeltTransmission

#create the pulleys
pA = Pulley( circle=Geometry2D.Circle( 10u"mm",  20u"mm", 20u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")
pB = Pulley( circle=Geometry2D.Circle(100u"mm",  20u"mm", 30u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")

pX = Pulley( circle=Geometry2D.Circle( 10u"mm",  20u"mm", 15u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="X")
pY = Pulley( circle=Geometry2D.Circle( 50u"mm",  80u"mm",  5u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="Y")

#create the belt systems 
segAB = route2Segments( calculateRouteAngles( [pA, pB] ))
segXY = route2Segments( calculateRouteAngles( [pX, pY] ))

plot( segAB, title="Parallel Systems", xlabel="[mm]", ylabel="[mm]", xlims=([-50,150]), ylims=([-50,100]), legend=false, dpi=100, size=(1000,500)) 
plot!(segXY, segmentColor=:cyan)
```
Pulley body colors are assigned by the default colormap, but `segmentColor` may be used to control the belt segment color.
Other [Plots.jl attributes](https://docs.juliaplots.org/latest/generated/attributes_plot/) may be used as expected.

### Open belt systems
`calculateRouteAngles()` 

### Optimization to available parts
If the system has significant unknowns, BeltTransmission can be used to evaluate potential configurations as part of a system optimization. 

#### Known belt and pulleys


find some combination of pulleys and belt that achieve a desired transmission ratio

### Standalone usage
One-off calculations enables unambiguous calculations.

## Development Plan
BeltTransmission.jl is under active development, [enhancement requests](https://github.com/mechanomy/BeltTransmission.jl/issues/new/choose) are welcome.
<!-- Besides open requests, our next major  -->

## BeltTransmission.jl


```@meta
CurrentModule= BeltTransmission
```

```@autodocs
Modules=[BeltTransmission]
```

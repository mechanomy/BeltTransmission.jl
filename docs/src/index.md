# Modeling Planar Belt Transmissions

[GitHub source](https://github.com/mechanomy/BeltTransmission.jl)

## Background
Belt transmissions involve several moving elements and a variety of materials, enabling flexible power transmission but leading to complex and interdependent system design requirements.
The basic performance of a candidate belt transmission can be estimated from kinematic analysis, while a dynamic simulation can give a much better idea of actual system performance and limits.

This Julia package assists users in the kinematic analysis, designing belt transmissions using flat or synchronous belts.
Primary structures model pulleys and belt segments, these can be analyzed and plotted through recipes for [Plots.jl](https://docs.juliaplots.org/stable/).
BeltTransmission was used to determine the basic design of the [Moover variants](https://mechanomy.com/projects/moover).

See the package [readme](https://github.com/mechanomy/BeltTransmission.jl) for release, license, and development information.

## Dependencies

* [Geometry2D](https://github.com/mechanomy/Geometry2D.jl)
* [Utility](https://github.com/mechanomy/Utility.jl)

And from the standard repository those defined in the Project.toml.

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
pA = PlainPulley( pitch=Geometry2D.Circle( center=ctrA, radius=10u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="A")
pB = PlainPulley( pitch=Geometry2D.Circle(100u"mm", 100u"mm", 20u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")

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
pA = PlainPulley( pitch=Geometry2D.Circle( 10u"mm",  20u"mm", 20u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")
pB = PlainPulley( pitch=Geometry2D.Circle(100u"mm",  20u"mm", 30u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="B")

pX = PlainPulley( pitch=Geometry2D.Circle( 10u"mm",  20u"mm", 15u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="X")
pY = PlainPulley( pitch=Geometry2D.Circle( 50u"mm",  80u"mm",  5u"mm"), axis=Geometry2D.UnitVector(0,0,1), name="Y")

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

## BeltTransmission.jl API
```@meta
CurrentModule= BeltTransmission
```

```@autodocs
Modules=[BeltTransmission]
```

## BeltTransmission.SynchronousBeltTable
```@meta
CurrentModule= BeltTransmission.SynchronousBeltTable
```

```@autodocs
Modules=[BeltTransmission.SynchronousBeltTable]
```

## BeltTransmission.Optimizer
Pulley locations and radii can be optimized via the [`Optimizer`](#BeltTransmission.Optimizer).

### Optimizer example
This example moves and resizes pulleys to achieve a given belt length.
We start with the initial system which has a belt length of 1050mm.

```@example optimizer
using Unitful, Plots
using Geometry2D 
using BeltTransmission

uk = Geometry2D.UnitVector(0,0,1)
#a square of pulleys, arranged ccw from quadrant1
pA = SynchronousPulley( center=Geometry2D.Point( 100u"mm", 100u"mm"), axis=uk, nGrooves=62, beltPitch=2u"mm", name="1A" )
pB = SynchronousPulley( center=Geometry2D.Point(-100u"mm", 100u"mm"), axis=uk, nGrooves=30, beltPitch=2u"mm", name="2B" )
pC = SynchronousPulley( center=Geometry2D.Point(-100u"mm",-100u"mm"), axis=uk, nGrooves=80, beltPitch=2u"mm", name="3C" )
pD = SynchronousPulley( center=Geometry2D.Point( 100u"mm",-100u"mm"), axis=uk, nGrooves=30, beltPitch=2u"mm", name="4D" )
pE = PlainPulley( pitch=Geometry2D.Circle(   0u"mm",   0u"mm", 14u"mm"), axis=-uk, name="5E") # -uk axis engages the backside of the belt

solved0 = BeltTransmission.calculateRouteAngles( [pA, pB, pC, pD, pE] )
l0 = BeltTransmission.calculateBeltLength(solved0)
```

Next, we add an available belt for this system.

```@example optimizer
# Initially the belt length is 1050mm. Reduce that to force the pulleys to move.
pitch = 8u"mm"
l = 1000u"mm"
n = Int(round(ustrip(l/pitch)))
belt = BeltTransmission.SynchronousBelt(pitch=pitch, nTeeth=n, width=6u"mm", profile="gt2")
println("Closest belt is $belt")
```
While this is a bit trivial, this is where a [BeltTable](#BeltTransmission.SynchronousBeltTable) belt can be used. 
Now we indicate which system variables are allowed to change, and their acceptable ranges.

```@example optimizer
pRoute = [pA, pB, pC, pD, pE]
cfg = BeltTransmission.Optimizer.Config(belt, pRoute, 4)
BeltTransmission.Optimizer.addVariable!(cfg, pA, BeltTransmission.Optimizer.xPosition, low=60, start=100.1, up=113  )
BeltTransmission.Optimizer.addVariable!(cfg, pA, BeltTransmission.Optimizer.yPosition, low=90, start=100.2, up=111  )
BeltTransmission.Optimizer.addVariable!(cfg, pB, BeltTransmission.Optimizer.yPosition, low=90, start=100.3, up=112  )
BeltTransmission.Optimizer.addVariable!(cfg, pC, BeltTransmission.Optimizer.radius, low=20, start=25, up=95  )

solved = BeltTransmission.Optimizer.solveSystem(cfg)
p = plot(solved0, segmentColor=:magenta)
p = plot!(solved, segmentColor=:yellow)
```
Here, the initial, unavailable belt length is plotted in magenta, with the optimization to the available belt in yellow.
Solving the system minimizes the difference between the given belt's length and that of the most recent system iteration.
Note that each variable was utilized, as the optimization generally spreads the task between the available freedoms.
The ranges set in each `addVariable!` provide an ability to fine-tune the solution as desired.

Infeasible systems will return warnings like:

* _Optimizer could not achieve the desired belt length given other constraints, desired[] vs solved[]. Try reducing the number of constraints or expanding their range._

* _Optimizer stopped prior to completion, consider changing the starting point or constraints._

The latter indicates that somewhere along the optimization the calculation of the system's belt length ran into an error.
This error was probably reported elsewhere in the output, but likely results from the overlapping of two pulleys, or the movement of one pulley such that the belt cannot touch it.

### API

```@autodocs
Modules=[BeltTransmission.Optimizer]
```
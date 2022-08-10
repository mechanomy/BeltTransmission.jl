<!-- copied from exes/BeltDesign.jl -->

# Belt Design example
In this example we want to choose which Synchronous belt will fit a given pulley arrangement.

```@example BeltDesignExample;
#dependencies for function arguments
using Unitful, Unitful.DefaultSymbols
using Plots
using Geometry2D

#bring this module in
using BeltTransmission


#describe the pulleys
uk = Geometry2D.UnitVector(0,0,1)
#a square of pulleys, arranged ccw from quadrant1
pA = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 20u"mm"), axis=uk, name="A")
pB = PlainPulley( pitch=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"), axis=uk, name="B")
pC = PlainPulley( pitch=Geometry2D.Circle(-100u"mm",-100u"mm", 43u"mm"), axis=uk, name="C")
pD = PlainPulley( pitch=Geometry2D.Circle( 100u"mm",-100u"mm", 14u"mm"), axis=uk, name="D") 
pE = PlainPulley( pitch=Geometry2D.Circle(   0u"mm",   0u"mm", 14u"mm"), axis=-uk, name="E") 
route = [pA, pB, pC, pD, pE]

# solve the system
solved = calculateRouteAngles(route)
println("Initial belt length is $(calculateBeltLength(solved))")

# plot the system
plot(solved)#, legend_background_color=:transparent, legend_position=:outerright)
```

intervening things

```@example BeltDesignExample;
# generate a catalog of GT2 belts
belts = SynchronousBeltTable.generateBeltDataFrame(pitch=2u"mm", width=6u"mm", toothRange=500:5:700)

# filter by length
@show belt = SynchronousBeltTable.lookupLength( belts, calculateBeltLength(solved), pitch=2mm, width=6mm, n=1 )


# apply it to the system

```

ending things


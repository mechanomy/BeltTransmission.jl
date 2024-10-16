# BasicBeltDesign.jl
# This example of BeltTransmission.jl solves a system of 5 pulleys, finding the belt length, idler position, angle of wrap on each pulley, and the transmission ratio matrix.

# using Plots #everything ends up as a plot

#dependencies for function arguments
# using Unitful, Unitful.DefaultSymbols
using UnitTypes
import Geometry2D

#bring this module in
using BeltTransmission

#describe the pulleys
uk = Geometry2D.UnitVector(0,0,1)
#a square of pulleys, arranged ccw from quadrant1
pA = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(100), MilliMeter(100)), axis=uk, nGrooves=62, beltPitch=MilliMeter(2), name="A" )
pB = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(-100), MilliMeter(100)), axis=uk, nGrooves=30, beltPitch=MilliMeter(2), name="B" )
pC = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(-100),MilliMeter(-100)), axis=uk, nGrooves=80, beltPitch=MilliMeter(2), name="C" )
pD = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(100),MilliMeter(-100)), axis=uk, nGrooves=30, beltPitch=MilliMeter(2), name="D" )
pE = PlainPulley( pitch=Geometry2D.Circle(   MilliMeter(0),   MilliMeter(0), MilliMeter(14)), axis=-uk, name="E") # -uk axis engages the backside of the belt
route = [pA, pB, pC, pD, pE]

# solve the system
solved = calculateRouteAngles(route)
println("Initial belt length is $(calculateBeltLength(solved))")

# # plot the system
# p = plot(solved, reuse=false)#, legend_background_color=:transparent, legend_position=:outerright)
# display(p)

# generate a catalog of GT2 belts
belts = SynchronousBeltTable.generateBeltDataFrame(pitch=MilliMeter(2), width=MilliMeter(6), toothRange=500:10:700)

# filter by length
@show belt = SynchronousBeltTable.lookupLength( belts, calculateBeltLength(solved), pitch=MilliMeter(2), width=MilliMeter(6), n=1 )
belt = SynchronousBeltTable.dfRow2SyncBelt(belt) #convert out of DataFrame

# the chosen belt is MilliMeter(1090) long while the initial belt length is 1093.MilliMeter(72). Calling E an idler, let's move it in X until the belt length is correct
# See the JuMP example for a more advanced optimization, a for-loop suffices here
dx = MilliMeter(1) #initial starting movement
for i = 1:100 #this is a gradient descent optimization https://en.wikipedia.org/wiki/Gradient_descent
  global dx -= (belt.length - calculateBeltLength(solved) )/10 
  global pE = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(0) + dx,   MilliMeter(0), MilliMeter(14)), axis=-uk, name="E") 
  global route = [pA, pB, pC, pD, pE]
  global solved = calculateRouteAngles(route)
  # println("Iteration $i: l=$(calculateBeltLength(solved)) with dx=$dx")
end
println("\nIteration 100: l=$(calculateBeltLength(solved)) with dx=$dx\n")
#---
# # p = plot!(solved, segmentColor=:cyan)#, legend_background_color=:transparent, legend_position=:outerright)
# p = plot!(BeltTransmission.route2Segments(solved), segmentColor=:cyan)
# display(p)
#---
printRoute(solved)
#---
printSegments(route2Segments(solved))
#--
calculateRatios(solved)

# -- 
# The manual approach above demonstrates that by using BeltTransmission, you have control over the entirety of the system and can easily perform custom operations.
# Of course, BeltTransmission already includes an [Optimize](#BeltTransmission.Optimizer) for these common tasks.
# Here we perform the same idler positioning with it.

# pE = PlainPulley( pitch=Geometry2D.Circle(   MilliMeter(0),   MilliMeter(0), MilliMeter(14)), axis=-uk, name="E") # reset E to its original position
# route = [pA, pB, pC, pD, pE]
# po = BeltTransmission.Optimizer.PositionOptions(belt, route)
# BeltTransmission.Optimizer.setXRange!(po, pE, MilliMeter(-10.0),  MilliMeter(0.0)) #allow E to move along X 
#
# # BeltTransmission.Optimizer.setX!(po, pE, low=MilliMeter(-10.0), start=MilliMeter(0), high=MilliMeter(0.0)) #allow E to move along X 
#
# x0 = 0.0 #starting x position of E, this needs to be unitless
# xv = Optimizer.optimizeit(po, x0)
# solved = BeltTransmission.Optimizer.xv2solved(po, xv)
# l = BeltTransmission.calculateBeltLength(solved)
# # # p = plot!(solved, segmentColor=:yellow)
# # p = plot!(BeltTransmission.route2Segments(solved), segmentColor=:yellow)
# # display(p)
# printRoute(solved)

;
# BasicBeltDesign.jl
# This example of BeltTransmission.jl solves a system of 5 pulleys, finding the belt length, idler position, angle of wrap on each pulley, and the transmission ratio matrix.

using Plots #everything ends up as a plot

#dependencies for function arguments
using Unitful, Unitful.DefaultSymbols
import Geometry2D

#bring this module in
using BeltTransmission

#describe the pulleys
uk = Geometry2D.UnitVector(0,0,1)
#a square of pulleys, arranged ccw from quadrant1
pA = SynchronousPulley( center=Geometry2D.Point( 100mm, 100mm), axis=uk, nGrooves=62, beltPitch=2mm, name="A" )
pB = SynchronousPulley( center=Geometry2D.Point(-100mm, 100mm), axis=uk, nGrooves=30, beltPitch=2mm, name="B" )
pC = SynchronousPulley( center=Geometry2D.Point(-100mm,-100mm), axis=uk, nGrooves=80, beltPitch=2mm, name="C" )
pD = SynchronousPulley( center=Geometry2D.Point( 100mm,-100mm), axis=uk, nGrooves=30, beltPitch=2mm, name="D" )
pE = PlainPulley( pitch=Geometry2D.Circle(   0u"mm",   0u"mm", 14u"mm"), axis=-uk, name="E") # -uk axis engages the backside of the belt
route = [pA, pB, pC, pD, pE]

# solve the system
solved = calculateRouteAngles(route)
println("Initial belt length is $(calculateBeltLength(solved))")

# plot the system
p = plot(solved, reuse=false)#, legend_background_color=:transparent, legend_position=:outerright)
display(p)

# generate a catalog of GT2 belts
belts = SynchronousBeltTable.generateBeltDataFrame(pitch=2u"mm", width=6u"mm", toothRange=500:10:700)

# filter by length
@show belt = SynchronousBeltTable.lookupLength( belts, calculateBeltLength(solved), pitch=2mm, width=6mm, n=1 )
belt = SynchronousBeltTable.dfRow2SyncBelt(belt) #convert out of DataFrame

# the chosen belt is 1090mm long while the initial belt length is 1093.72mm. Calling E an idler, let's move it in X until the belt length is correct
# See the JuMP example for a more advanced optimization, a for-loop suffices here
dx = 1u"mm" #initial starting movement
for i = 1:100 #this is a gradient descent optimization https://en.wikipedia.org/wiki/Gradient_descent
  global dx -= (belt.length - calculateBeltLength(solved) )/10 
  global pE = PlainPulley( pitch=Geometry2D.Circle( 0u"mm" + dx,   0u"mm", 14u"mm"), axis=-uk, name="E") 
  global route = [pA, pB, pC, pD, pE]
  global solved = calculateRouteAngles(route)
  # println("Iteration $i: l=$(calculateBeltLength(solved)) with dx=$dx")
end
println("\nIteration 100: l=$(calculateBeltLength(solved)) with dx=$dx\n")
#---
p = plot!(solved, segmentColor=:cyan)#, legend_background_color=:transparent, legend_position=:outerright)
display(p)
#---
printRoute(solved)
#---
printSegments(route2Segments(solved))
#--
calculateRatios(solved)
;
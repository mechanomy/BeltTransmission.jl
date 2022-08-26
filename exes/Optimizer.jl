#Example from BeltTransmission.Optimizer
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
#---- 

# Initially the belt length is 1050mm. Reduce that to force the pulleys to move.
pitch = 8u"mm"
l = 1000u"mm"
n = Int(round(ustrip(l/pitch)))
belt = BeltTransmission.SynchronousBelt(pitch=pitch, nTeeth=n, width=6u"mm", profile="gt2")
println("Closest belt is $belt")

pRoute = [pA, pB, pC, pD, pE]
cfg = BeltTransmission.Optimizer.Config(belt, pRoute, 4)
BeltTransmission.Optimizer.addVariable!(cfg, pA, BeltTransmission.Optimizer.xPosition, low=60, start=100.1, up=113  )
BeltTransmission.Optimizer.addVariable!(cfg, pA, BeltTransmission.Optimizer.yPosition, low=90, start=100.2, up=111  )
BeltTransmission.Optimizer.addVariable!(cfg, pB, BeltTransmission.Optimizer.yPosition, low=90, start=100.3, up=112  )
BeltTransmission.Optimizer.addVariable!(cfg, pC, BeltTransmission.Optimizer.radius, low=20, start=25, up=95  )

solved = BeltTransmission.Optimizer.solveSystem(cfg)
p = plot(solved0, segmentColor=:magenta)
p = plot!(solved, segmentColor=:yellow)
display(p)
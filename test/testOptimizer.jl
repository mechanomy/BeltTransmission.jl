


uk = Geometry2D.UnitVector(0,0,1)
#a square of pulleys, arranged ccw from quadrant1
pA = SynchronousPulley( center=Geometry2D.Point( 100u"mm", 100u"mm"), axis=uk, nGrooves=62, beltPitch=2u"mm", name="1A" )
pB = SynchronousPulley( center=Geometry2D.Point(-100u"mm", 100u"mm"), axis=uk, nGrooves=30, beltPitch=2u"mm", name="2B" )
pC = SynchronousPulley( center=Geometry2D.Point(-100u"mm",-100u"mm"), axis=uk, nGrooves=80, beltPitch=2u"mm", name="3C" )
pD = SynchronousPulley( center=Geometry2D.Point( 100u"mm",-100u"mm"), axis=uk, nGrooves=30, beltPitch=2u"mm", name="4D" )
pE = PlainPulley( pitch=Geometry2D.Circle(   0u"mm",   0u"mm", 14u"mm"), axis=-uk, name="5E") # -uk axis engages the backside of the belt
pRoute = [pA, pB, pC, pD, pE]

@testset "lookupPulley" begin
  @test BeltTransmission.Optimizer.lookupPulley(pRoute, pB) == 2
  @test BeltTransmission.Optimizer.lookupPulley(pRoute, pC) == 3
  @test BeltTransmission.Optimizer.lookupPulley(pRoute, pE) == 5
end

@testset "solveSystem" begin
  # x0 = float([100.1, 100.2, 100.3, 25.46])

  #x0 has l=1050mm, now reduce that to force the pulleys to move
  l = 1000u"mm"
  pitch = 8u"mm"
  n = Int(round(ustrip(l/pitch)))
  belt = BeltTransmission.SynchronousBelt(pitch=pitch, nTeeth=n, width=6u"mm", profile="gt2")
  # println("Closest belt is $belt")

  po = BeltTransmission.Optimizer.Config(belt, pRoute, 4)
  BeltTransmission.Optimizer.addVariable!(po, pA, BeltTransmission.Optimizer.xPosition, low=60, start=100.1, up=113  )
  BeltTransmission.Optimizer.addVariable!(po, pA, BeltTransmission.Optimizer.yPosition, low=90, start=100.2, up=111  )
  BeltTransmission.Optimizer.addVariable!(po, pB, BeltTransmission.Optimizer.yPosition, low=90, start=100.3, up=112  )
  BeltTransmission.Optimizer.addVariable!(po, pC, BeltTransmission.Optimizer.radius, low=20, start=25, up=95  )

  solved0 = BeltTransmission.calculateRouteAngles( BeltTransmission.Optimizer.x2route(po, po.start) )
  l0 = BeltTransmission.calculateBeltLength(solved0)
  # BeltTransmission.printRoute(solved0)
  p = plot(solved0, segmentColor=:magenta)

  solved = BeltTransmission.Optimizer.solveSystem(po)
  solvedL = BeltTransmission.calculateBeltLength(solved)
  # BeltTransmission.printRoute(solved)
  p = plot!(solved, segmentColor=:yellow)
  # display(p)
  @test typeof(p) <: AbstractPlot

  @test isapprox(po.belt.length, solvedL, rtol=1e-3) #check sucessful belt length
  @test po.lower[1] < ustrip(u"mm", solved[1].pitch.center.x) && ustrip(u"mm", solved[1].pitch.center.x) <  po.upper[1] 
  @test po.lower[2] < ustrip(u"mm", solved[1].pitch.center.y) && ustrip(u"mm", solved[1].pitch.center.y) <  po.upper[2] 
  @test po.lower[3] < ustrip(u"mm", solved[2].pitch.center.y) && ustrip(u"mm", solved[2].pitch.center.y) <  po.upper[3] 
  @test po.lower[4] < ustrip(u"mm", solved[3].pitch.radius) && ustrip(u"mm", solved[3].pitch.radius) <  po.upper[4] 
end


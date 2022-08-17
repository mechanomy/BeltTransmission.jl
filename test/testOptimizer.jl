


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

@testset "optimization" begin
  x0 = float([100.1, -100.2, -100.3, -100.4])

  #x0 has l=1050mm, now reduce that to force the pulleys to move
  l = 1000u"mm"
  pitch = 8u"mm"
  n = Int(round(ustrip(l/pitch)))
  belt = BeltTransmission.SynchronousBelt(pitch=pitch, nTeeth=n, width=6u"mm", profile="gt2")
  println("Closest belt is $belt")

  po = BeltTransmission.Optimizer.PositionOptions(belt, pRoute)
  BeltTransmission.Optimizer.setXRange!(po, pA, 60.0u"mm", 113u"mm") #100.2 
  BeltTransmission.Optimizer.setXRange!(po, pB, -110u"mm", -99u"mm")
  BeltTransmission.Optimizer.setYRange!(po, pC, -111u"mm", -62u"mm")
  BeltTransmission.Optimizer.setYRange!(po, pD, -112u"mm", -61u"mm")

  solved0 = BeltTransmission.Optimizer.xv2solved(po, x0)
  l0 = BeltTransmission.calculateBeltLength(solved0)
  p = plot(solved0)

  xv = Optimizer.optimizeit(po, x0)
  solved = BeltTransmission.Optimizer.xv2solved(po, xv)
  l = BeltTransmission.calculateBeltLength(solved)
  p = plot!(solved, segmentColor=:yellow)
  display(p)
  printRoute(solved)

  for ip=1:5
    if po.optimizeX[ip] && ( solved[ip].pitch.center.x < po.lowerX[ip] || po.upperX[ip] < solved[ip].pitch.center.x )
      println("$ip x: $(po.lowerX[ip]) < $(solved[ip].pitch.center.x) < $(po.upperX[ip])")
    end

    if po.optimizeY[ip] && ( solved[ip].pitch.center.y < po.lowerY[ip] || po.upperY[ip] < solved[ip].pitch.center.y )
      println("$ip y: $(po.lowerY[ip]) < $(solved[ip].pitch.center.y) < $(po.upperY[ip])")
    end
  end

  @test isapprox(po.belt.length , l, rtol=1e-3) #check sucessful belt length
  for ip = 1:5 #check pulley bounds
    @test !po.optimizeX[ip] || po.lowerX[ip] < solved[ip].pitch.center.x 
    @test !po.optimizeY[ip] || po.lowerY[ip] < solved[ip].pitch.center.y 
    @test !po.optimizeX[ip] || po.upperX[ip] > solved[ip].pitch.center.x 
    @test !po.optimizeY[ip] || po.upperY[ip] > solved[ip].pitch.center.y 
  end

end

@testset "Optimizer " begin
  @test true
end

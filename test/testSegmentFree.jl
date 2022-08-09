uk = Geometry2D.UnitVector(0,0,1)
#a square of pulleys, arranged ccw from quadrant1
pA = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), axis=uk, name="A")
pB = PlainPulley( pitch=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"), axis=uk, name="B")
pC = PlainPulley( pitch=Geometry2D.Circle(-100u"mm",-100u"mm", 43u"mm"), axis=uk, name="C")
pD = PlainPulley( pitch=Geometry2D.Circle( 100u"mm",-100u"mm", 14u"mm"), axis=uk, name="D") 
pE = PlainPulley( pitch=Geometry2D.Circle( 80u"mm",-200u"mm", 14u"mm"), axis=-uk, name="E") 
route = [pA, pB, pC, pD, pE]

@testset "FreeSegment constructors" begin
  sab = FreeSegment( pA, pB )
  # @test length(sab) == Geometry2D.distance(pB.pitch.center, pA.pitch.center)
  @test distance(sab) == Geometry2D.distance(pB.pitch.center, pA.pitch.center)

  sab = FreeSegment( depart=pA, arrive=pB)
  @test length(sab) == Geometry2D.distance(pB.pitch.center, pA.pitch.center)
end

@testset "findTangents" begin
  saa = FreeSegment(depart=pA, arrive=pA)
  sab = FreeSegment(depart=pA, arrive=pB)
  sac = FreeSegment(depart=pA, arrive=pC)
  @test_throws DomainError findTangents(saa) #overlap, throws

  tans = findTangents(sab)
  for i=1:4
    @test Geometry2D.isSegmentMutuallyTangent(cA=tans[i].depart.pitch, thA=tans[i].depart.depart, cB=tans[i].arrive.pitch, thB=tans[i].arrive.arrive )
  end

  tans = findTangents(sac)
  for i=1:4
    @test Geometry2D.isSegmentMutuallyTangent(cA=tans[i].depart.pitch, thA=tans[i].depart.depart, cB=tans[i].arrive.pitch, thB=tans[i].arrive.arrive )
  end

end

@testset "isSegmentMutuallyTangent" begin
  pA = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), arrive=0°, depart=(π/2)u"rad",               axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             arrive=(π/2)u"rad", depart=200°, axis=uk, name="B")
  seg = FreeSegment( depart=pA, arrive=pB )
  @test isSegmentMutuallyTangent( seg )

  pA = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), arrive=0°, depart=90°,               axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             arrive=90°, depart=200°, axis=uk, name="B")
  seg = FreeSegment( depart=pA, arrive=pB )
  @test isSegmentMutuallyTangent( seg )
end

@testset "calculateRouteAngles" begin
  solved = calculateRouteAngles(route)

  #test confirmed via plot, copying angles into below to guard changes
  # @test isapprox(solved[1].arrive, 5.327rad, rtol=1e-3) # E@0,0
  @test isapprox(solved[1].arrive, 6.136rad, rtol=1e-3) # E@80,-200
  @test isapprox(solved[2].arrive, 1.571rad, rtol=1e-3) # == [1].depart
  @test isapprox(solved[3].arrive, 2.976rad, rtol=1e-3)
  @test isapprox(solved[4].arrive, 4.858rad, rtol=1e-3)
  # @test isapprox(solved[5].arrive, 4.126rad, rtol=1e-3)
  @test isapprox(solved[5].arrive, 0.0807rad, rtol=1e-3) #E@80,-200
end

@testset "toStringShort" begin
  pA = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), arrive=0°, depart=90°,               axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             arrive=90°, depart=200°, axis=uk, name="B")
  seg = FreeSegment( depart=pA, arrive=pB )
  @test toStringShort(seg) == "A--B"
end

@testset "toStringPoints" begin
  pA = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), arrive=0°, depart=90°,               axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             arrive=90°, depart=200°, axis=uk, name="B")
  seg = FreeSegment( depart=pA, arrive=pB )
  @test toStringPoints(seg) == "FreeSegment: depart[100.000, 110.000] -- arrive[-100.000, 110.000] length[200.000]"
end

@testset "toStringVector" begin
  pA = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), arrive=0°, depart=90°,               axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             arrive=90°, depart=200°, axis=uk, name="B")
  seg = FreeSegment( depart=pA, arrive=pB )
  @test toStringVectors(seg) == "A:[100.000,100.000]<10.000@90.000°>[100.000,110.000]--B:[-100.000,100.000]<10.000@90.000°>[-100.000,110.000]"
end

@testset "calculateBeltLength" begin
  # #one complete revolution
  pp = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), axis=uk, name="A", arrive=0°, depart=360°) # one complete revolution
  @test isapprox( calculateBeltLength( [pp] ), calculateWrappedLength(pp), rtol=1e-3 )

  # an open belt, 180d wrap on both pulleys, separated by 200mm
  pA = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), arrive=270°, depart=90°,               axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             arrive=90°, depart=270°, axis=uk, name="B")
  seg = FreeSegment( depart=pA, arrive=pB )
  @test isapprox( calculateBeltLength( [seg] ), π*2*10mm + 200mm, rtol=1e-3 )

  solved = calculateRouteAngles(route)
  # # @test isapprox( calculateBeltLength( solved ), 0.181155m, rtol=1e-3 ) #E@0,0
  # # @test isapprox( calculateBeltLength( solved ), 0.22438m, rtol=1e-3 ) #E@80,-200
  @test isapprox( calculateBeltLength( solved ), 1.231345m, rtol=1e-3 )
end

@testset "route2Segments" begin
  solved = calculateRouteAngles(route)
  segments = route2Segments(solved)
  @test toStringShort(segments[1]) == "A--B"
  @test toStringShort(segments[2]) == "B--C"
  @test toStringShort(segments[3]) == "C--D"
  @test toStringShort(segments[4]) == "D--E"
  @test toStringShort(segments[5]) == "E--A"
end


@testset "plotSegment of a single SegmentFree" begin
  # pyplot()
  pA = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), arrive=0°, depart=90°,               axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             arrive=90°, depart=200°, axis=uk, name="B")
  seg = FreeSegment( depart=pA, arrive=pB )
  p = plot(seg, reuse=false, title="plot(::FreeSegment)")
  p = plot!(seg.depart)
  p = plot!(seg.arrive)
  # display(p)
  @test typeof(p) <: Plots.AbstractPlot #did the plot draw at all?

  p = plot([seg], reuse=false, title="plot(::Vector{FreeSegment})")
  # display(p)
  @test typeof(p) <: Plots.AbstractPlot
end


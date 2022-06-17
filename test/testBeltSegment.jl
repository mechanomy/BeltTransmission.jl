



uk = Geometry2D.UnitVector(0,0,1)
#a square of pulleys, arranged ccw from quadrant1
pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), axis=uk, name="A")
pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"), axis=uk, name="B")
pC = Pulley( circle=Geometry2D.Circle(-100u"mm",-100u"mm", 43u"mm"), axis=uk, name="C")
pD = Pulley( circle=Geometry2D.Circle( 100u"mm",-100u"mm", 14u"mm"), axis=uk, name="D") 
pE = Pulley( circle=Geometry2D.Circle( 80u"mm",-200u"mm", 14u"mm"), axis=-uk, name="E") 
route = [pA, pB, pC, pD, pE]

@testset "Segment constructors" begin
  sab = Segment( pA, pB )
  # @test length(sab) == Geometry2D.distance(pB.pitch.center, pA.pitch.center)
  @test distance(sab) == Geometry2D.distance(pB.pitch.center, pA.pitch.center)

  sab = Segment( depart=pA, arrive=pB)
  @test length(sab) == Geometry2D.distance(pB.pitch.center, pA.pitch.center)
end

@testset "findTangents" begin
  saa = Segment(depart=pA, arrive=pA)
  sab = Segment(depart=pA, arrive=pB)
  sac = Segment(depart=pA, arrive=pC)
  @test_throws DomainError findTangents(saa) #overlap, throws


  tans = findTangents(sab)
  for i=1:4
    @test Geometry2D.isSegmentMutuallyTangent(cA=tans[i].depart.pitch, thA=tans[i].depart.aDepart, cB=tans[i].arrive.pitch, thB=tans[i].arrive.aArrive )
  end

  tans = findTangents(sac)
  for i=1:4
    @test Geometry2D.isSegmentMutuallyTangent(cA=tans[i].depart.pitch, thA=tans[i].depart.aDepart, cB=tans[i].arrive.pitch, thB=tans[i].arrive.aArrive )
  end

end

@testset "isSegmentMutuallyTangent" begin
  pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=(π/2)u"rad",               axis=uk, name="A")
  pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=(π/2)u"rad", aDepart=200°, axis=uk, name="B")
  seg = Segment( depart=pA, arrive=pB )
  @test isSegmentMutuallyTangent( seg )

  pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=90°,               axis=uk, name="A")
  pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=200°, axis=uk, name="B")
  seg = Segment( depart=pA, arrive=pB )
  @test isSegmentMutuallyTangent( seg )
end

@testset "calculateRouteAngles" begin
  solved = calculateRouteAngles(route)

  #test confirmed via plot, copying angles into below to guard changes
  # @test isapprox(solved[1].aArrive, 5.327rad, rtol=1e-3) # E@0,0
  @test isapprox(solved[1].aArrive, 6.136rad, rtol=1e-3) # E@80,-200
  @test isapprox(solved[2].aArrive, 1.571rad, rtol=1e-3) # == [1].aDepart
  @test isapprox(solved[3].aArrive, 2.976rad, rtol=1e-3)
  @test isapprox(solved[4].aArrive, 4.858rad, rtol=1e-3)
  # @test isapprox(solved[5].aArrive, 4.126rad, rtol=1e-3)
  @test isapprox(solved[5].aArrive, 0.0807rad, rtol=1e-3) #E@80,-200
end

@testset "toStringShort" begin
  pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=90°,               axis=uk, name="A")
  pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=200°, axis=uk, name="B")
  seg = Segment( depart=pA, arrive=pB )
  @test toStringShort(seg) == "A--B"
end

@testset "toStringPoints" begin
  pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=90°,               axis=uk, name="A")
  pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=200°, axis=uk, name="B")
  seg = Segment( depart=pA, arrive=pB )
  @test toStringPoints(seg) == "Segment: depart[100.000, 110.000] -- arrive[-100.000, 110.000] length[200.000]"
end

@testset "toStringVector" begin
  pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=90°,               axis=uk, name="A")
  pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=200°, axis=uk, name="B")
  seg = Segment( depart=pA, arrive=pB )
  @test toStringVectors(seg) == "A:[100.000,100.000]<10.000@90.000°>[100.000,110.000]--B:[-100.000,100.000]<10.000@90.000°>[-100.000,110.000]"
end

@testset "calculateBeltLength" begin
  # #one complete revolution
  pp = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), axis=uk, name="A", aArrive=0°, aDepart=360°) # one complete revolution
  @test isapprox( calculateBeltLength( [pp] ), calculateWrappedLength(pp), rtol=1e-3 )

  # an open belt, 180d wrap on both pulleys, separated by 200mm
  pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=270°, aDepart=90°,               axis=uk, name="A")
  pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=270°, axis=uk, name="B")
  seg = Segment( depart=pA, arrive=pB )
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


@testset "plotSegment" begin
  pyplot()
  pA = Pulley( circle=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), aArrive=0°, aDepart=90°,               axis=uk, name="A")
  pB = Pulley( circle=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"),             aArrive=90°, aDepart=200°, axis=uk, name="B")
  seg = Segment( depart=pA, arrive=pB )
  p = plot(seg, reuse=false, title="plot(::Segment)")
  p = plot!(seg.depart)
  p = plot!(seg.arrive)
  display(p)
  @test typeof(p) <: Plots.AbstractPlot #did the plot draw at all?

  p = plot([seg], reuse=false, title="plot(::Vector{Segment})")
  display(p)
  @test typeof(p) <: Plots.AbstractPlot
end

@testset "plotRoute of Pulley" begin
  pyplot()
  solved = calculateRouteAngles(route)
  p = plot(solved, reuse=false)#, legend_background_color=:transparent, legend_position=:outerright)
  display(p)
  
  @test typeof(p) <: Plots.AbstractPlot #did the plot draw at all?
end

@testset "plotRoute of Segment" begin
  pyplot()
  solved = calculateRouteAngles(route)
  segments = route2Segments(solved)
  p = plot(segments, reuse=false)#, legend_background_color=:transparent, legend_position=:outerright)
  display(p)
  
  @test typeof(p) <: Plots.AbstractPlot #did the plot draw at all?
end



@testset "printRoute" begin
  solved = calculateRouteAngles(route)
  printRoute(solved)
  @test true
end

@testset "printSegments" begin
  solved = calculateRouteAngles(route)
  printSegments( route2Segments( solved ) )
  @test true
end

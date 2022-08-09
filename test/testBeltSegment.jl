



uk = Geometry2D.UnitVector(0,0,1)
#a square of pulleys, arranged ccw from quadrant1
pA = PlainPulley( pitch=Geometry2D.Circle( 100u"mm", 100u"mm", 10u"mm"), axis=uk, name="A")
pB = PlainPulley( pitch=Geometry2D.Circle(-100u"mm", 100u"mm", 10u"mm"), axis=uk, name="B")
pC = PlainPulley( pitch=Geometry2D.Circle(-100u"mm",-100u"mm", 43u"mm"), axis=uk, name="C")
pD = PlainPulley( pitch=Geometry2D.Circle( 100u"mm",-100u"mm", 14u"mm"), axis=uk, name="D") 
pE = PlainPulley( pitch=Geometry2D.Circle( 80u"mm",-200u"mm", 14u"mm"), axis=-uk, name="E") 
route = [pA, pB, pC, pD, pE]


@testset "plotRoute of PlainPulley" begin
  # pyplot()
  solved = calculateRouteAngles(route)
  p = plot(solved, reuse=false)#, legend_background_color=:transparent, legend_position=:outerright)
  # display(p)
  
  @test typeof(p) <: Plots.AbstractPlot #did the plot draw at all?
end

@testset "plotRoute of FreeSegment" begin
  # pyplot()
  solved = calculateRouteAngles(route)
  segments = route2Segments(solved)
  p = plot(segments, reuse=false)#, legend_background_color=:transparent, legend_position=:outerright)
  # display(p)
  
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

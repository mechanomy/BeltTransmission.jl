# create systems to permute
ppa = PlainPulley(Geometry2D.Circle(0mm,0mm, 4mm), Geometry2D.uk, 1u"rad", 4u"rad", "PlainPulleyA") 
ppb = PlainPulley(Geometry2D.Circle(10mm,10mm, 6mm), -Geometry2D.uk, 1u"rad", 4u"rad", "PlainPulleyB") 
spa = SynchronousPulley( center=Geometry2D.Point(20mm,40mm), axis=Geometry2D.uk, nGrooves=22, beltPitch=2mm, arrive=1u"rad", depart=4u"rad", name="SyncPulleyA" )
spb = SynchronousPulley( center=Geometry2D.Point( 0mm,40mm), axis=Geometry2D.uk, nGrooves=12, beltPitch=2mm, arrive=1u"rad", depart=4u"rad", name="SyncPulleyB" )

seg1 = FreeSegment(depart=ppa, arrive=ppb)
seg2 = FreeSegment(depart=spa, arrive=spb)
seg3 = FreeSegment(depart=ppa, arrive=spb)

route1 = [ppa, ppb]
route2 = [spa, spb]
route3 = [ppa, ppb, spa, spb]

solved1 = calculateRouteAngles(route1)
solved2 = calculateRouteAngles(route2)
solved3 = calculateRouteAngles(route3)

@testset "plot ::PlainPulley" begin
  p = plot(ppa, reuse=false)
  p = plot!(ppb)
  @test typeof(p) <: Plots.AbstractPlot
  # display(p);
end
@testset "plot ::SynchronousPulley" begin
  p = plot(spa, reuse=false)
  p = plot!(spb)
  @test typeof(p) <: Plots.AbstractPlot
  # display(p);
end

@testset "plot ::Vector{PlainPulley}" begin
  p = plot(route1, reuse=false)
  @test typeof(p) <: Plots.AbstractPlot
  # display(p);
end
@testset "plot ::Vector{SynchronousPulley}" begin
  p = plot(route2, reuse=false)
  @test typeof(p) <: Plots.AbstractPlot
  # display(p);
end
@testset "plot ::Vector{AbstractPulley}" begin
  p = plot(route3, reuse=false)
  @test typeof(p) <: Plots.AbstractPlot
  # display(p);
end

@testset "seg::FreeSegment" begin
  p = plot(seg1, reuse=false)
  @test typeof(p) <: Plots.AbstractPlot

  p = plot!(seg2, segmentColor=:cyan)
  @test typeof(p) <: Plots.AbstractPlot

  p = plot!(seg3, segmentColor=:yellow)
  @test typeof(p) <: Plots.AbstractPlot
  # display(p);
end

@testset "segments::Vector{AbstractSegment}" begin
  vec = [seg1, seg2, seg3]
  p = plot(vec)
  @test typeof(p) <: Plots.AbstractPlot
  # display(p);
end

#now plot in a normal way:
@testset "plotRoutes" begin
  p = plot(route1, reuse=false)
  @test typeof(p) <: Plots.AbstractPlot
  # display(p)

  p = plot(route2, reuse=false)
  @test typeof(p) <: Plots.AbstractPlot
  # display(p)

  p = plot(route3, reuse=false)
  @test typeof(p) <: Plots.AbstractPlot
  # display(p)
end

@testset "plotRoutes via route2Segments" begin
  segments = route2Segments(route1)
  p1 = plot(segments, reuse=false)
  @test typeof(p1) <: Plots.AbstractPlot

  segments = route2Segments(route2)
  p2 = plot(segments, reuse=false)
  @test typeof(p2) <: Plots.AbstractPlot

  segments = route2Segments(route3)
  p3 = plot(segments, reuse=false)
  @test typeof(p3) <: Plots.AbstractPlot

  # display(p1)
  # display(p2)
  # display(p3)
end

@testset "plotSolved" begin
  p1 = plot(solved1, reuse=false)
  @test typeof(p1) <: Plots.AbstractPlot

  p2 = plot(solved2, reuse=false)
  @test typeof(p2) <: Plots.AbstractPlot

  p3 = plot(solved3, reuse=false, segmentColor=:green, lengthUnit=u"inch")
  @test typeof(p3) <: Plots.AbstractPlot

  # display(p1)
  # display(p2)
  # display(p3)
end


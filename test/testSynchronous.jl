
ba = SynchronousBelt(pitch=2mm, length=54mm, width=6mm, profile="gt2")
bb = SynchronousBelt(pitch=2mm, nTeeth=27, width=6mm, profile="gt2")

@testset "SynchronousBelt constructors" begin
  @test ba.pitch == bb.pitch
  @test ba.length == bb.length
  @test ba.id != bb.id
  @test ba.id == tryparse(UUID, string(ba.id))
end

@testset "SynchronousBelt copy constructor" begin
  bs = SynchronousBelt( ba, supplier="SDP/SI", url="https://sdpsi.com/", partNumber="135-246")
  @test ba.id == bs.id
  @test bs.partNumber == "135-246"
  @test bs.supplier == "SDP/SI"
  @test bs.url == "https://sdpsi.com/"
end

@testset "pitchLength2NTeeth" begin
  @test pitchLength2NTeeth(pitch=2u"mm", length=54u"mm") == 27
  @test pitchLength2NTeeth(pitch=2u"mm", length=54.4u"mm") == 27
  @test pitchLength2NTeeth(pitch=2u"mm", length=53.6u"mm") == 27
end

@testset "nTeeth2PitchLength" begin
  @test nTeeth2PitchLength(pitch=2u"mm", nTeeth=27) == 54mm
  @test nTeeth2PitchLength(pitch=2u"mm", nTeeth=28) == 0.056m
  @test nTeeth2PitchLength(pitch=2u"mm", nTeeth=26) == 52mm
end



@testset "SynchronousPulley constructors" begin
  ctr = Geometry2D.Point(3mm,5mm)

  tp = SynchronousPulley(ctr, 10, Geometry2D.uk, 2mm, "B")
  @test typeof(tp) <: AbstractPulley

  pA = SynchronousPulley( center=Geometry2D.Point(100mm,100mm), axis=Geometry2D.uk, nGrooves=62, beltPitch=2mm, name="A" )
  tp = SynchronousPulley(center=ctr, axis=Geometry2D.uk, nGrooves=10, beltPitch=2mm, name="H")
  @test typeof(tp) <: AbstractPulley

  @test pitchLength( tp ) ≈ 20mm
end

@testset "nGrooves2Radius" begin
  @test nGrooves2Radius(2mm, 10) == 20mm/2/pi
end

@testset "radius2NGrooves" begin
  @test radius2NGrooves(2mm, 10mm) == round(2*pi*10mm / 2mm)
end

@testset "nGrooves2Length" begin
  @test nGrooves2Length(2mm, 10) == 20mm
end

@testset "pulley2String" begin
  p = SynchronousPulley(center=Geometry2D.Point(1mm, 2mm), nGrooves=10, axis=Geometry2D.uk, beltPitch=2mm, arrive=1u"rad", depart=2u"rad", name="struct" ) 
  @show p
  @test pulley2String(p) == "timing pulley[struct] @ [1.000,2.000] r[3.183] mm arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.183]"
end


@testset "plotSynchronousPulley" begin
  # pyplot()
  pa = SynchronousPulley( center=Geometry2D.Point(0mm,0mm), axis=Geometry2D.uk, nGrooves=62, beltPitch=2mm, arrive=1u"rad", depart=2u"rad", name="A" )
  pb = SynchronousPulley( center=Geometry2D.Point(20mm,40mm), axis=-Geometry2D.uk, nGrooves=42, beltPitch=2mm, arrive=-1u"rad", depart=2u"rad", name="B" )
  p = plot(pa, reuse=false)
  p = plot!(pb)
  display(p);
  @test typeof(p) <: Plots.AbstractPlot
end

@testset "plotSynchronousPulley system" begin
  # pyplot()
  pa = SynchronousPulley( center=Geometry2D.Point(0mm,0mm), axis=Geometry2D.uk, nGrooves=62, beltPitch=2mm,name="A" )
  pb = SynchronousPulley( center=Geometry2D.Point(20mm,40mm), axis=Geometry2D.uk, nGrooves=42, beltPitch=2mm,name="B" )

  route = [pa,pb]
  p = plot(route)
  display(p);
  @test typeof(p) <: Plots.AbstractPlot

  sys = calculateRouteAngles([pa,pb])
  @show typeof(sys)
  p = plot(sys, reuse=false)
  display(p);
  @test typeof(p) <: Plots.AbstractPlot
end

@testset "plotSynchronousPulley mixed system" begin
  # pyplot()
  pa = SynchronousPulley( center=Geometry2D.Point(0mm,0mm), axis=Geometry2D.uk, nGrooves=62, beltPitch=2mm,name="SyncPulleyA" )
  pb = PlainPulley(Geometry2D.Circle(30mm,0mm, 4mm), Geometry2D.uk, 1u"rad", 4u"rad", "plainPulleyB") 

  route = [pa,pb]
  @show typeof(route)
  p = plot(route)
  display(p);
  @test typeof(p) <: Plots.AbstractPlot

  # sys = calculateRouteAngles([pa,pb])
  # @show typeof(sys)
  # p = plot(sys, reuse=false)
  # display(p);
  # @test typeof(p) <: Plots.AbstractPlot
end


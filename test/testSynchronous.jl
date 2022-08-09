
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
  cir = Geometry2D.Circle( ctr, 5mm )

  tp = SynchronousPulley(cir, Geometry2D.uk, 2mm, 0u"rad", 1u"rad", "A")
  @test typeof(tp) <: AbstractPulley

  tp = SynchronousPulley(ctr, 10, Geometry2D.uk, 2mm, "B")
  @test typeof(tp) <: AbstractPulley

  # tc = SynchronousPulley( tp, arrive=3u"rad", depart=1u"rad") #copy
  # @show tc
  # @test typeof(tc) <: AbstractPulley

  tp = SynchronousPulley(pitch=cir, axis=Geometry2D.uk, toothPitch=2mm, arrive=0u"rad", depart=1u"rad", name="C")
  @test typeof(tp) <: AbstractPulley
  tp = SynchronousPulley(pitch=cir, axis=Geometry2D.uk, toothPitch=2mm, arrive=0u"rad", depart=1u"rad" )
  @test typeof(tp) <: AbstractPulley

  tp = SynchronousPulley(pitch=cir, axis=Geometry2D.uk, toothPitch=2mm, name="E")
  @test typeof(tp) <: AbstractPulley
  tp = SynchronousPulley(pitch=cir, axis=Geometry2D.uk, toothPitch=2mm)
  @test typeof(tp) <: AbstractPulley

  tp = SynchronousPulley(center=ctr, radius=cir.radius, axis=Geometry2D.uk, toothPitch=2mm, name="G")
  @test typeof(tp) <: AbstractPulley

  tp = SynchronousPulley(center=ctr, axis=Geometry2D.uk, nGrooves=10, toothPitch=2mm, name="H")
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
  p = SynchronousPulley(pitch=Geometry2D.Circle(1mm, 2mm, 3mm), axis=Geometry2D.uk, toothPitch=2mm, arrive=1u"rad", depart=2u"rad", name="struct" ) 
  @test pulley2String(p) == "timing pulley[struct] @ [1.000,2.000] r[3.000] mm arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.000]"
end


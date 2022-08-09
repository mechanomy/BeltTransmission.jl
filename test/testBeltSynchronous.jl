
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



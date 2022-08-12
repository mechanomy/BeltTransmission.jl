
@testset "SynchronousBeltTable roundtrip test: generateBeltDataFrame() -> writeBeltCSV() -> readBeltCSV()" begin
  tdir = tempdir()
  bpath = joinpath(tdir, "generateBeltTable.csv") 
  bdf = SynchronousBeltTable.generateBeltDataFrame(pitch=3.5u"mm", width=4u"mm", toothRange=10:5:30)
  SynchronousBeltTable.writeBeltCSV(bdf, bpath)
  bcs = SynchronousBeltTable.readBeltCSVIntoDataFrame( bpath )

  ret = true
  for ir in 1:size(bdf,1)
    ret &= bdf[ir, :profile] == bcs[ir, :profile]
    ret &= bdf[ir, :pitch] == bcs[ir, :pitch]
    ret &= bdf[ir, :nTeeth] == bcs[ir, :nTeeth]
    ret &= bdf[ir, :length] == bcs[ir, :length]
    ret &= bdf[ir, :width] == bcs[ir, :width]
    ret &= bdf[ir, :id] == bcs[ir, :id]
    ret &= bdf[ir, :partNumber] == bcs[ir, :partNumber]
    ret &= bdf[ir, :supplier] == bcs[ir, :supplier]
    ret &= bdf[ir, :url] == bcs[ir, :url]
  end
  @test ret
end

@testset "SynchronousBeltTable dataframe SyncBelt conversion" begin
  sb = SynchronousBelt( pitch=2mm, width=6mm, nTeeth=34, profile="mxl" )
  dfrow = SynchronousBeltTable.dfRow( sb )
  sb2 = SynchronousBeltTable.dfRow2SyncBelt( dfrow[1, :] )
  @test sb == sb2
end

@testset "SynchronousBeltTable lookups" begin
  bdf = SynchronousBeltTable.generateBeltDataFrame(pitch=2u"mm", width=6u"mm", toothRange=10:15:300)
  append!(bdf, SynchronousBeltTable.generateBeltDataFrame(pitch=4u"mm", width=6u"mm", toothRange=10:15:300) )
  append!(bdf, SynchronousBeltTable.generateBeltDataFrame(pitch=4u"mm", width=9u"mm", toothRange=10:15:300) )
  # @show bdf

  nr = size(bdf,1)

  # #match any pitch & width
  # pitch=-1u"mm"
  # bp = pitch > 0mm
  # width=-1u"mm"
  # bw = width > 0mm
  # @show bdf[ ( fill(!bp, nr) .|| bdf.pitch .== pitch) .& ( fill(!bw, nr) .|| bdf.width .== width), :] 
# 
  # #restrict to pitch=2
  # pitch=2u"mm"
  # bp = pitch > 0mm
  # width=-1u"mm"
  # bw = width > 0mm
  # @show bdf[ ( fill(!bp, nr) .|| bdf.pitch .== pitch) .& ( fill(!bw, nr) .|| bdf.width .== width), :] 
# 
  # #restrict to width=6
  # pitch=-1u"mm"
  # bp = pitch > 0mm
  # width=6u"mm"
  # bw = width > 0mm
  # @show bdf[ ( fill(!bp, nr) .|| bdf.pitch .== pitch) .& ( fill(!bw, nr) .|| bdf.width .== width), :] 
# 
  # #restrict to pitch=2, width=6
  # pitch=2u"mm"
  # bp = pitch > 0mm
  # width=6u"mm"
  # bw = width > 0mm
  # @show bdf[ ( fill(!bp, nr) .|| bdf.pitch .== pitch) .& ( fill(!bw, nr) .|| bdf.width .== width), :] 

  length=100u"mm"
  pitch=2u"mm"
  width=6u"mm"

  retdf = SynchronousBeltTable.lookupLength( bdf, length )
  @test size(retdf,1) == nr

  retdf = SynchronousBeltTable.lookupLength( bdf, length, pitch=pitch, width=width, n=1)
  sb = SynchronousBeltTable.dfRow2SyncBelt( retdf )
  @test sb.length == 110mm && sb.pitch==2mm && sb.width==6mm
end


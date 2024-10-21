# Enhancement: define the belt format as a schema, eg https://tables.juliadata.org/stable/#Tables.Schema to document and enforce consistiency
# ...can any of this be made generic?

export SynchronousBeltTable

"""
  Reads, writes, and generates CSVs that represent catalogs of synchronous belts, having headers:
    `toothProfile` - trade name of the tooth profile, eg gt2, gt3, mxl, ...
    `pitchMM` - tooth spacing
    `nTeeth` - number of teeth about the closed belt
    `lengthMM` - circumferential belt length
    `widthMM` - belt width
    `id` - a UUID4 unique identifier
    `partNumber` - manufacturer or supplier part number
    `supplier` - supplier name
    `url` - link to the data source

  ### Basic usage:
  Generate a DataFrame of belts:
  ```@julia
  using BeltTransmission
  belts = SynchronousBeltTable.generateBeltDataFrame(pitch=2u"mm", width=6u"mm", toothRange=10:5:30)
  ```
  Write these to a CSV:
  ```@repl
  SynchronousBeltTable.writeBeltCSV(belts, "gt2Belts.csv")
  ```

  This creates a CSV file at the given path, with format
  ```
  profile,pitchMM,nTeeth,lengthMM,widthMM,id,partNumber,supplier,url
  gt2,2,10,20,6,3a9ee2fa-95a2-4217-b5c6-4bde0d9c65c9,pn0,none,none
  gt2,2,15,30,6,319f2899-b714-43a4-b37c-830179524311,pn0,none,none
  gt2,2,20,40,6,7e15cab0-58f2-4c4e-be0b-f168d1091ce9,pn0,none,none
  gt2,2,25,50,6,6f5fcd44-26f0-44c7-bf38-5aea52c51dd1,pn0,none,none
  gt2,2,30,60,6,ce84bc3b-4025-4de1-b79c-f536f9e95794,pn0,none,none
  ```

  (note the UUID ids will differ).

  This file can then be read in
  ```@repl
  beltsdf = SynchronousBeltTable.readBeltCSVIntoDataFrame("gt2Belts.csv")
  ```

  The table of belts can be filtered by
  ```@repl
  filtered = SynchronousBeltTable.lookupLength(beltsdf, 35u"mm", n=2)
  ```
  to get the top two belts nearest the desired length.

  These can be converted into [SynchronousBelt](#BeltTransmission.SynchronousBelt)s by
  ```@repl
  sync = SynchronousBeltTable.dfRow2SyncBelt( filtered[1,:] )
  ```
"""
module SynchronousBeltTable
  using TestItems
  using CSV
  using DataFrames
  using UnitTypes
  using UUIDs
  using Printf
  using BeltTransmission #sub-modules do not inherit parent namespace https://docs.julialang.org/en/v1/manual/modules/#Submodules-and-relative-paths
  # using .BeltTransmission 
  # import .SynchronousBelt 
  # using .SynchronousBelt 

  # export dfRow2SyncBelt, dfRow, readBeltCSVIntoDataFrame, generateBeltDataFrame, writeBeltCSV, lookupLength

  """An abstract belt type for belt optimization"""
  abstract type AbstractOptimizableBelt end #some type that we can assert Belts to be

  """
      dfRow2SyncBelt( row::DataFrames.DataFrameRow )
    Converts a DataFrame row to a SynchronousBelt struct.
  """
  function dfRow2SyncBelt( row::DataFrames.DataFrameRow ) #how to make this an AbstOB
    return SynchronousBelt( pitch=row.pitch,
                          length=row.length,
                          nTeeth=row.nTeeth,
                          width=row.width,
                          profile=row.profile,
                          partNumber=row.partNumber,
                          supplier=row.supplier,
                          url=row.url,
                          id=row.id )
  end

  """
      dfRow( sb::SynchronousBelt)
    Converts a SynchronousBelt into a DataFrame row.
  """
  function dfRow( sb::SynchronousBelt)
    return DataFrame( profile=sb.profile,
                      pitch=sb.pitch,
                      nTeeth=sb.nTeeth,
                      length=sb.length,
                      width=sb.width,
                      id=sb.id,
                      partNumber=sb.partNumber,
                      supplier=sb.supplier,
                      url=sb.url )
  end

  """
      readBeltCSVIntoDataFrame(csvPath::String)
    Returns a dataframe with the belt information from the given `csvPath` belt description file.
    See [writeBeltCSV](#BeltTransmission.SynchronousBeltTable.writeBeltCSV) for the file format.
  """
  function readBeltCSVIntoDataFrame(csvPath::String)
    cread = CSV.File( csvPath,  delim=",", stripwhitespace=true, header=1 )
    
    df = DataFrame()
    for row in eachrow(cread)
      sb = SynchronousBelt( 
                    string(row[1].profile),
                    MilliMeter(row[1].pitchMM),
                    MilliMeter(row[1].lengthMM),
                    row[1].nTeeth,
                    MilliMeter(row[1].widthMM),
                    string(row[1].partNumber),
                    string(row[1].supplier),
                    string(row[1].url),
                    tryparse(UUID, row[1].id) )
      # sb = SynchronousBelt( pitch=row[1].pitchMM*mm,
      #               length=row[1].lengthMM*mm,
      #               nTeeth=row[1].nTeeth,
      #               width=row[1].widthMM*mm,
      #               profile=string(row[1].profile),
      #               partNumber=string(row[1].partNumber),
      #               supplier=string(row[1].supplier),
      #               url=string(row[1].url),
      #               id=tryparse(UUID, row[1].id) )
      append!(df, dfRow(sb) )
    end
    return df
  end

  """
      generateBeltDataFrame(; pitch::AbstractLength, width::AbstractLength, toothRange)
    Generates a belt DataFrame with a given `pitch` and `width` over `toothRange`.
    `toothRange` can be specified as `toothRange=20:5:200` to create a tooth range array starting with 20 teeth, then proceeding to 200 teeth in 5-tooth increments.
  """
  function generateBeltDataFrame(; pitch::AbstractLength, width::AbstractLength, toothRange)
    df = DataFrame()
    for tr in toothRange
      pl = nTeeth2PitchLength( pitch=pitch, nTeeth=tr)
      dn = DataFrame( profile="gt2",
                      pitch=pitch,
                      nTeeth=tr,
                      length=pl,
                      width=width,
                      id=UUIDs.uuid4(),
                      partNumber="pn0",
                      supplier="none",
                      url="none"  )
      append!(df, dn)
    end
    return df
  end

  """
      writeBeltCSV(belts::DataFrame, csvPath::String )
    Given a `belts` DataFrame describing one or more belts, write that to the `csvPath` file.
  """
  function writeBeltCSV(belts::DataFrame, csvPath::String )
    # move units from elements to column headers. CSV.write() is totally happy to write every element's unit, but this is tedious if edited by hand...
    # df = DataFrame()
    # for rb in eachrow(belts)
    #   dn = DataFrame( profile=rb.profile,
    #                   pitchMM=MilliMeter(rb.pitch).value,
    #                   nTeeth=rb.nTeeth,
    #                   lengthMM=MilliMeter(rb.length).value,
    #                   widthMM=MilliMeter(rb.width).value,
    #                   id=rb.id,
    #                   partNumber=rb.partNumber,
    #                   supplier=rb.supplier,
    #                   url=rb.url  )
    #   append!(df, dn)
    # end
    # CSV.write(csvPath, df)
    open(csvPath, "w+") do fid
      write(fid, "profile, pitchMM, nTeeth, lengthMM, widthMM, id, partNumber, supplier, url\n")
      for rb in eachrow(belts)
        write(fid, @sprintf("%s, %f, %d, %f, %f, %s, %s, %s, %s\n", rb.profile, MilliMeter(rb.pitch).value, rb.nTeeth, MilliMeter(rb.length).value, MilliMeter(rb.width).value, rb.id, rb.partNumber, rb.supplier, rb.url) )
      end
    end
  end

  """Given a desired belt `length`, return a vector of the closest options from the `belts` dataframe for the given `pitch` and `width`.
  If `n` = 1 the single nearest result is returned, else a DataFrame sorted by abs(length error).
  """
  function lookupLength(belts::DataFrame, length::AbstractLength; pitch=MilliMeter(-1), width=MilliMeter(-1), n = 0)
    # println("Searching for pitch[$pitch] width[$width] length[$length]")
    nb = size(belts,1)

    #restrict to pitch and width:
    bp = pitch > MilliMeter(0) # if bp<0, bp=false == don't filter by pitch, so below bp=false means true
    bw = width > MilliMeter(0)
    beltsFilter = belts[ ( fill(!bp, nb) .|| belts.pitch .== pitch) .& ( fill(!bw, nb) .|| belts.width .== width), :] 

    dists = ones( size(beltsFilter,1) )
    for (ib,bl) in enumerate(eachrow(beltsFilter))
      dists[ib] = toBaseFloat(length - bl.length)
    end
    id = sortperm(abs.(dists)) #get the permutation vector
    bls = beltsFilter[ id, : ] #reorder

    # if bls[1,:pitch]*10 < dists[id[1]]
    if toBaseFloat(bls[1,:pitch]*10) < dists[id[1]]
      @warn "None of the given `belts` were close to the desired `length` of $length, closest is $(dists[1])mm away."
    end

    if n == 0 || size(bls,1) < n
      return bls
    elseif n == 1
      return bls[1,:] #a dataframe row
    else
      return bls[1:n,:] # a dataframe
    end
  end #lookupLength()



  # """Given a `belt`, return a descriptive name"""
  # function makeCatalogName(sheet)
  #   nBelts = length(sheet["belts"])
  #   sheet["nBelts"] = nBelts
  #   width = convert(Int32, sheet["width [mm]"])
  #   widthCode = @sprintf("%03d",width)
  #   for ib in 1:nBelts
  #       groove = convert(Int32, round(parse(Float64, sheet["belts"][ib]["groove"])))
  #       grooveCode = @sprintf("%03d",groove)
  #       sheet["belts"][ib]["catalogNumber"] = @sprintf("a36r51m%s%s", grooveCode, widthCode)
  #   end
  #   return sheet
  # end

  @testitem "SynchronousBeltTable roundtrip test: generateBeltDataFrame() -> writeBeltCSV() -> readBeltCSV()" begin
    using UnitTypes
    tdir = tempdir()
    # tdir = @__DIR__
    bpath = joinpath(tdir, "generateBeltTable.csv") 
    bdf = BeltTransmission.SynchronousBeltTable.generateBeltDataFrame(pitch=MilliMeter(3.5), width=MilliMeter(4), toothRange=10:5:30)
    SynchronousBeltTable.writeBeltCSV(bdf, bpath)
    # bcs = SynchronousBeltTable.readBeltCSVIntoDataFrame( bpath )
    # rm(bpath, force=true) # cleanup


    # ret = true
    # for ir in 1:size(bdf,1)
    #   ret = true
    #   ret &= bdf[ir, :profile] == bcs[ir, :profile]
    #   ret &= bdf[ir, :pitch] == bcs[ir, :pitch]
    #   ret &= bdf[ir, :nTeeth] == bcs[ir, :nTeeth]
    #   ret &= bdf[ir, :length] == bcs[ir, :length]
    #   ret &= bdf[ir, :width] == bcs[ir, :width]
    #   ret &= bdf[ir, :id] == bcs[ir, :id]
    #   ret &= bdf[ir, :partNumber] == bcs[ir, :partNumber]
    #   ret &= bdf[ir, :supplier] == bcs[ir, :supplier]
    #   @test bdf[ir, :url] == bcs[ir, :url]
    # end
    # # @test ret
  end

  # @testitem "SynchronousBeltTable dataframe SyncBelt conversion" begin
  #   using UnitTypes
  #   sb = SynchronousBelt( pitch=MilliMeter(2), width=MilliMeter(6), nTeeth=34, profile="mxl" )
  #   dfrow = SynchronousBeltTable.dfRow( sb )
  #   sb2 = SynchronousBeltTable.dfRow2SyncBelt( dfrow[1, :] )
  #   @test sb == sb2
  # end

  # @testitem "SynchronousBeltTable lookups" begin
  #   using UnitTypes
  #   bdf = SynchronousBeltTable.generateBeltDataFrame(pitch=MilliMeter(2), width=MilliMeter(6), toothRange=10:15:300)
  #   append!(bdf, SynchronousBeltTable.generateBeltDataFrame(pitch=MilliMeter(4), width=MilliMeter(6), toothRange=10:15:300) )
  #   append!(bdf, SynchronousBeltTable.generateBeltDataFrame(pitch=MilliMeter(4), width=MilliMeter(9), toothRange=10:15:300) )
  #   # @show bdf

  #   nr = size(bdf,1)

  #   # #match any pitch & width
  #   # pitch=MilliMeter(-1)
  #   # bp = pitch > 0mm
  #   # width=MilliMeter(-1)
  #   # bw = width > 0mm
  #   # @show bdf[ ( fill(!bp, nr) .|| bdf.pitch .== pitch) .& ( fill(!bw, nr) .|| bdf.width .== width), :] 
  # # 
  #   # #restrict to pitch=2
  #   # pitch=MilliMeter(2)
  #   # bp = pitch > 0mm
  #   # width=MilliMeter(-1)
  #   # bw = width > 0mm
  #   # @show bdf[ ( fill(!bp, nr) .|| bdf.pitch .== pitch) .& ( fill(!bw, nr) .|| bdf.width .== width), :] 
  # # 
  #   # #restrict to width=6
  #   # pitch=MilliMeter(-1)
  #   # bp = pitch > 0mm
  #   # width=MilliMeter(6)
  #   # bw = width > 0mm
  #   # @show bdf[ ( fill(!bp, nr) .|| bdf.pitch .== pitch) .& ( fill(!bw, nr) .|| bdf.width .== width), :] 
  # # 
  #   # #restrict to pitch=2, width=6
  #   # pitch=MilliMeter(2)
  #   # bp = pitch > 0mm
  #   # width=MilliMeter(6)
  #   # bw = width > 0mm
  #   # @show bdf[ ( fill(!bp, nr) .|| bdf.pitch .== pitch) .& ( fill(!bw, nr) .|| bdf.width .== width), :] 

  #   length=MilliMeter(100)
  #   pitch=MilliMeter(2)
  #   width=MilliMeter(6)

  #   retdf = SynchronousBeltTable.lookupLength( bdf, length )
  #   @test size(retdf,1) == nr

  #   retdf = SynchronousBeltTable.lookupLength( bdf, length, pitch=pitch, width=width, n=1)
  #   sb = SynchronousBeltTable.dfRow2SyncBelt( retdf )
  #   @test sb.length == MilliMeter(110) && sb.pitch==MilliMeter(2) && sb.width==MilliMeter(6)
  # end



end #SynchronousBeltTable



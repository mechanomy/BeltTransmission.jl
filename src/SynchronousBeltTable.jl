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
"""
module SynchronousBeltTable
  using CSV
  using DataFrames
  using Unitful, Unitful.DefaultSymbols
  using UUIDs
  using BeltTransmission #sub-modules do not inherit parent namespace https://docs.julialang.org/en/v1/manual/modules/#Submodules-and-relative-paths
  # using .BeltTransmission #sub-modules do not inherit parent namespace https://docs.julialang.org/en/v1/manual/modules/#Submodules-and-relative-paths
  # import .SynchronousBelt #sub-modules do not inherit parent namespace https://docs.julialang.org/en/v1/manual/modules/#Submodules-and-relative-paths
  # using .SynchronousBelt #sub-modules do not inherit parent namespace https://docs.julialang.org/en/v1/manual/modules/#Submodules-and-relative-paths

  # export dfRow2SyncBelt, dfRow, readBeltCSVIntoDataFrame, generateBeltDataFrame, writeBeltCSV, lookupLength


  abstract type AbstractOptimizableBelt end #some type that we can assert Belts to be

  function dfRow2SyncBelt( row::DataFrames.DataFrameRow ) #how to make this an AbstOB
    return sb = SynchronousBelt( pitch=row.pitch,
                          length=row.length,
                          nTeeth=row.nTeeth,
                          width=row.width,
                          profile=row.profile,
                          partNumber=row.partNumber,
                          supplier=row.supplier,
                          url=row.url,
                          id=row.id )
  end

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


  """Returns a dataframe with the belt information"""
  function readBeltCSVIntoDataFrame(csvPath::String)
    cread = CSV.File( csvPath,  delim=",", stripwhitespace=true, header=1 )
    
    df = DataFrame()
    for row in eachrow(cread)
     sb = SynchronousBelt( pitch=row[1].pitchMM*mm,
                    length=row[1].lengthMM*mm,
                    nTeeth=row[1].nTeeth,
                    width=row[1].widthMM*mm,
                    profile=string(row[1].profile),
                    partNumber=string(row[1].partNumber),
                    supplier=string(row[1].supplier),
                    url=string(row[1].url),
                    id=tryparse(UUID, row[1].id) )
      append!(df, dfRow(sb) )
    end
    return df
  end

  """Generates a belt DataFrame for a given `pitch`, `width`, and `toothRange`"""
  function generateBeltDataFrame(; pitch::Unitful.Length, width::Unitful.Length, toothRange)
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

  function writeBeltCSV(belts::DataFrame, csvPath::String )
    # move units from elements to column headers. CSV.write() is totally happy to write every element's unit, but this is tedious if edited by hand...
    df = DataFrame()
    for rb in eachrow(belts)
      dn = DataFrame( profile=rb.profile,
                      pitchMM=ustrip(u"mm", rb.pitch),
                      nTeeth=rb.nTeeth,
                      lengthMM=ustrip(u"mm",rb.length),
                      widthMM=ustrip(u"mm", rb.width),
                      id=rb.id,
                      partNumber=rb.partNumber,
                      supplier=rb.supplier,
                      url=rb.url  )
      append!(df, dn)
    end
    CSV.write(csvPath, df)
  end

  """Given a desired belt `length`, return a vector of the closest options from the `belts` dataframe for the given `pitch` and `width`.
  If `n` = 1 the single nearest result is returned, else a DataFrame sorted by abs(length error).
  """
  function lookupLength(belts::DataFrame, length::Unitful.Length; pitch=-1u"mm", width=-1u"mm", n = 0)
    # println("Searching for pitch[$pitch] width[$width] length[$length]")

    nb = size(belts,1)

    #restrict to pitch and width:
    bp = pitch > 0mm # if bp<0, bp=false == don't filter by pitch, so below bp=false means true
    bw = width > 0mm
    beltsFilter = belts[ ( fill(!bp, nb) .|| belts.pitch .== pitch) .& ( fill(!bw, nb) .|| belts.width .== width), :] 

    dists = ones( size(beltsFilter,1) )
    for (ib,bl) in enumerate(eachrow(beltsFilter))
      dists[ib] = ustrip(u"mm", length - bl.length)
    end
    id = sortperm(abs.(dists)) #get the permutation vector
    bls = beltsFilter[ id, : ] #reorder

    if n == 1
      return bls[1,:]
    else
      return bls
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




end #SynchronousBeltTable



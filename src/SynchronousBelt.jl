

export SyncBelt, pitchLength2NTeeth, nTeeth2PitchLength#, belt2NTeeth, belt2PitchLength

"""Represents a synchronous belt with parameters:
  `profile::String` - tooth profile name
  `pitch::Unitful.Length` - distance between belt grooves
  `length::Unitful.Length` - belt linear length if cut
  `nTeeth::Int` - number of teeth over the length
  `width::Unitful.Length` - belt width
  `partNumber::String` - reference name
  `supplier::String` - reference name
  `url::String` - sourcing link
  `id::UUID` - unique id
"""
struct SyncBelt # should agree with BeltTable.jl's DataFrame columns; mutable until copy constructor is added
  profile::String #tooth profile name
  pitch::Unitful.Length # distance between belt grooves
  length::Unitful.Length # belt linear length if cut
  nTeeth::Int #number of teeth over the length
  width::Unitful.Length # belt width
  partNumber::String # reference name
  supplier::String # reference name
  url::String #sourcing link
  id::UUID #unique id
end 
# 220526: KeywordDispatch can't have default arguments: https://github.com/simonbyrne/KeywordDispatch.jl/issues/1
@kwdispatch SyncBelt()
@kwmethod SyncBelt(; pitch::Unitful.Length, length::Unitful.Length, nTeeth::Int,  width::Unitful.Length, profile::String, partNumber::String, supplier::String, url::String, id::UUID ) = SyncBelt( profile, pitch, length, nTeeth, width, partNumber, supplier, url, id)
@kwmethod SyncBelt(; pitch::Unitful.Length, length::Unitful.Length,               width::Unitful.Length, profile::String) = SyncBelt( profile, pitch, length, pitchLength2NTeeth(pitch=pitch, length=length), width, "pn00", "spA", "url0", UUIDs.uuid4() )
@kwmethod SyncBelt(; pitch::Unitful.Length, nTeeth::Int,                          width::Unitful.Length, profile::String) = SyncBelt( profile, pitch, nTeeth2PitchLength(pitch=pitch, nTeeth=nTeeth), nTeeth,                width, "pn00", "spA", "url0", UUIDs.uuid4() )

"""
`SyncBelt( belt::SyncBelt; partNumber="", supplier="", url="" ) :: SyncBelt`
A copy constructor for adding/changing `partNumber`, `supplier`, or `url`
  """
function SyncBelt( belt::SyncBelt; partNumber="", supplier="", url="" ) :: SyncBelt
  pn = belt.partNumber
  if partNumber != ""
      pn = partNumber
  end
  sp = belt.supplier
  if supplier != ""
      sp = supplier
  end
  ur = belt.url
  if url != ""
      ur = url
  end
  return SyncBelt( belt.profile, belt.pitch, belt.length, belt.nTeeth, belt.width, pn, sp, ur, belt.id )
end


"""
plots the free section of a segment, does not plot the pulleys
"""
@recipe function plotRecipe(belt::SyncBelt; n=100, lengthUnit=u"mm")#, segmentColor=:magenta, arrowFactor=0.03)
  seriestype := :path 
  linecolor --> segmentColor
  linewidth --> 3 #would like this to be 3x default...above lwd is ":auto" not a number when this runs...
  aspect_ratio := :equal 
  label --> toString(seg)
  legend_background_color --> :transparent
  legend_position --> :outerright

  ustrip.(lengthUnit,x), ustrip.(lengthUnit,y) #return the data
end



"""
`pitchLength2NTeeth(; pitch::Unitful.Length, length::Unitful.Length )::Integer`
`nTeeth` is simply `length`/`pitch`
"""
function pitchLength2NTeeth(; pitch::Unitful.Length, length::Unitful.Length )::Integer
  return convert(Int64, round(length/pitch))
end

"""
`nTeeth2PitchLength(; pitch::Unitful.Length, nTeeth::Integer) :: Unitful.Length`
Belt `length` is `pitch` * `nTeeth`
"""
function nTeeth2PitchLength(; pitch::Unitful.Length, nTeeth::Integer) :: Unitful.Length
  return pitch * nTeeth
end


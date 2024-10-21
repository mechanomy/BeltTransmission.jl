


export PlainPulley, pulley2String

"""
  Models a cylindrical plain pulley in a BeltTransmission with:
  $FIELDS
"""
struct PlainPulley <: AbstractPulley
  """the pitch Circle"""
  pitch::Geometry2D.Circle #the pitch circle
  """the rotation axis for the pulley with +/- defining the 'positive' rotation direction"""
  axis::Geometry2D.UnitVector #unit vector in the direction of positive axis rotation
  """angle of the radial vector of the belt's point of arrival"""
  arrive::AbstractAngle#angle of the point of tangency, arrive comes first in the struct from the view of positive rotation..
  """angle of the radial vector of the belt's point of departure"""
  depart::AbstractAngle
  """convenience name of the pulley"""
  name::String
end

"""
    PlainPulley(pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) 
  Models a PlainPulley in a BeltTransmission, described by a `circle`, rotation `axis`, and `name`.
"""
PlainPulley(pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) = PlainPulley(pitch,axis,Radian(0),Radian(0),name) 

"""
    PlainPulley(pp::PlainPulley, arrive=0u"rad", depart=0u"rad")
  Copy constructor setting `arrive` and `depart`.
"""
PlainPulley(pp::PlainPulley, arrive::AbstractAngle=Radian(0), depart::AbstractAngle=Radian(0)) = PlainPulley(pp.pitch,pp.axis,arrive,depart,pp.name) 

@kwdispatch PlainPulley()

"""
    PlainPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) 
    PlainPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, arrive::AbstractAngle, depart::AbstractAngle, name::String) 
  Models a PlainPulley in a BeltTransmission through keyword arguments.
"""
@kwmethod PlainPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) = PlainPulley(pitch,axis,Radian(0),Radian(0),name)
@kwmethod PlainPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, arrive::AbstractAngle, depart::AbstractAngle, name::String) = PlainPulley(pitch,axis,arrive,depart,name)


@testitem "Test constructors" begin
  using Geometry2D, UnitTypes

  ctr = Geometry2D.Point2D(MilliMeter(3),MilliMeter(5))
  rad = MilliMeter(4)
  aa = Radian(1)
  ad = Radian(2)

  @test typeof( PlainPulley(Geometry2D.Circle(ctr, rad), Geometry2D.uk, aa, ad, "struct" ) ) <: AbstractPulley
  @test typeof( PlainPulley(Geometry2D.Circle(ctr, rad), Geometry2D.uk, aa, ad, "struct" ) ) <: PlainPulley
  @test typeof( PlainPulley(pitch=Geometry2D.Circle(ctr, rad), axis=Geometry2D.uk, name="circle key" ) ) <: PlainPulley

  tp = PlainPulley(Geometry2D.Circle(MilliMeter(1), MilliMeter(2), MilliMeter(3)), Geometry2D.uk, Radian(1), Radian(2), "struct" ) 
  tc = PlainPulley(tp, Radian(1.1), Radian(2.2))
  @test typeof(tc) <: AbstractPulley
end

"""
    pulley2String(p::PlainPulley) :: String
  Returns a descriptive string of the given PlainPulley `p` of the form:
    PlainPulley[struct] @ [1.000mm,2.000mm] r[3.000mm] arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.000mm]"
"""
function pulley2String(p::PlainPulley)::String 
  pad = Degree(p.arrive)
  pdd = Degree(p.depart)
  cwa = Degree(calculateWrappedAngle(p))
  cwl = calculateWrappedLength(p)

  return @sprintf("PlainPulley[%s] @ [%3.3f%s,%3.3f%s] r[%3.3f%s] arrive[%3.3f%s] depart[%3.3f%s] aWrap[%3.3f%s] lWrap[%3.3f%s]",
    p.name, 
    p.pitch.center.x.value, p.pitch.center.x.unit, # manually elaborate these to be able to get %3.3
    p.pitch.center.y.value, p.pitch.center.y.unit, 
    p.pitch.radius.value, p.pitch.radius.unit, 
    pad.value, pad.unit,
    pdd.value, pdd.unit,
    cwa.value, cwa.unit,
    cwl.value, cwl.unit
  )
end

@testitem "pulley2String" begin
  using Geometry2D, UnitTypes
  p = PlainPulley(Geometry2D.Circle(MilliMeter(1), MilliMeter(2), MilliMeter(3)), Geometry2D.uk, Radian(1), Radian(2), "planey" ) 
  @test pulley2String(p) == "PlainPulley[planey] @ [1.000mm,2.000mm] r[3.000mm] arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.000mm]"
end


# # Is there a way to overload PlotPulley with pulley-specific defaults?
# @recipe(PlotPlainPulley, pulley) do scene # creates plotplainpulley() and plotplainpulley!() 
#   Theme()
#   Attributes(
#     widthBelt=3,
#     colorBelt=:magenta,
#     colorPulley="#4050ff55", # slightly differs from Pulley
#     nCircle=100 # number of points on a circle
#   )
# end
# # function Makie.plot!(ppp::PlotPlainPulley{<:Tuple{<:Makie.Axis, <:PlainPulley}}) # ERROR: No recipe for plotplainpulley with args: Tuple{BeltTransmission.PlainPulley}
# # function Makie.plot!(ppp::PlotPlainPulley{<:Tuple{<:PlainPulley}}) # ERROR: No recipe for plotpulley with args: Tuple{}
# function Makie.plot!(ppp::PlotPlainPulley{<:Tuple{PlainPulley}}) # ERROR: No recipe for plotpulley with args: Tuple{}
#   plotpulley!(ppp, widthBelt=ppp[:widthBelt][], colorBelt=ppp[:colorBelt][], colorPulley=ppp[:colorPulley][], nCircle=ppp[:nCircle][], )
#   return ppp
# end

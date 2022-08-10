


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
  arrive::Geometry2D.Radian #angle of the point of tangency, arrive comes first in the struct from the view of positive rotation..
  """angle of the radial vector of the belt's point of departure"""
  depart::Geometry2D.Radian
  """convenience name of the pulley"""
  name::String
end

"""
    PlainPulley(circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) :: PlainPulley
  Models a PlainPulley in a BeltTransmission, described by a `circle`, rotation `axis`, and `name`.
"""
PlainPulley(pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) = PlainPulley(pitch,axis,0u"rad",0u"rad",name) 

"""
    PlainPulley(pp::PlainPulley, arrive=0u"rad", depart=0u"rad")
  Copy constructor setting `arrive` and `depart`
"""
PlainPulley(pp::PlainPulley, arrive=0u"rad", depart=0u"rad") = PlainPulley(pp.pitch,pp.axis,arrive,depart,pp.name) 

@kwdispatch PlainPulley()

"""
    PlainPulley(; circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) :: PlainPulley
    PlainPulley(; circle::Geometry2D.Circle, axis::Geometry2D.UnitVector, arrive::Geometry2D.Radian, depart::Geometry2D.Radian, name::String) :: PlainPulley
  Models a PlainPulley in a BeltTransmission through keyword arguments.
"""
@kwmethod PlainPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, name::String) = PlainPulley(pitch,axis,0u"rad",0u"rad",name)
@kwmethod PlainPulley(; pitch::Geometry2D.Circle, axis::Geometry2D.UnitVector, arrive::Geometry2D.Radian, depart::Geometry2D.Radian, name::String) = PlainPulley(pitch,axis,arrive,depart,name)



"""
    pulley2String(p::PlainPulley) :: String
  Returns a descriptive string of the given PlainPulley `p` of the form:
    pulley[struct] @ [1.000,2.000] r[3.000] mm arrive[57.296°] depart[114.592°] aWrap[57.296°] lWrap[3.000]"
"""
function pulley2String(p::PlainPulley)::String 
  un = unit(p.pitch.radius)
  return @sprintf("pulley[%s] @ [%3.3f,%3.3f] r[%3.3f] %s arrive[%3.3f°] depart[%3.3f°] aWrap[%3.3f°] lWrap[%3.3f]",
    p.name, 
    ustrip(un, p.pitch.center.x), ustrip(un, p.pitch.center.y), ustrip(un, p.pitch.radius),
    string(un),
    ustrip(u"°",p.arrive), ustrip(u"°",p.depart),
    ustrip(u"°",calculateWrappedAngle(p)), ustrip(un,calculateWrappedLength(p)) )

  # #without computing wrapped angle or length:
  # return @sprintf("pulley[%s] @ [%3.3f,%3.3f] r[%3.3f] %s arrive[%3.3f°] depart[%3.3f°]", 
  #   p.name, 
  #   ustrip(un, p.pitch.center.x), ustrip(un, p.pitch.center.y), ustrip(un, p.pitch.radius),
  #   string(un),
  #   ustrip(u"°",p.arrive), ustrip(u"°",p.depart) )
end



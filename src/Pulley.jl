export AbstractPulley, getDeparturePoint, getArrivalPoint, calculateWrappedAngle, calculateWrappedLength, pulley2Circle, pulley2String, printPulley


"""
Subtypes of AbstractPulley model a particular form of pulley.
All subtypes have basic fields of `pitch::Circle`, `axis::UnitVector`, `arrive::Angle`, `aDepart::Angle`, and a `name::String`.
"""
abstract type AbstractPulley end

# #Is there any point to having more intermediate types? 
# # How about the backside of a timing belt engaging a PlainPulley?
# #  This would have TimingBelt <: Timing, TimingPulley <: Timing, with AbstractTiming entailing a pitch?
# abstract type AbstractPlainPulley <: AbstractPulley end
# abstract type AbstractTimingPulley <: AbstractPulley end
# struct TimingPulley <: AbstractTimingPulley
# end
# # One use case is when modeling both the TimingPulley and modeling a RealTimingPulley, the latter have all sorts of attributes that are not relevant to the BeltTransmission calculations.  Here the AbstractTiming could be used to permit BeltTransmission functions to be called on both TP&RTP, with other non-BeltTransmission functions restricted to RTP.


# these methods work on all AbstractPulleys:


"""
    Base.show(io::IO, p::AbstractPulley)
Function to `show()` a AbstractPulley via [`pulley2String`](@ref).
"""
function Base.show(io::IO, p::AbstractPulley)
  print(io, pulley2String(p))
end

"""
    getDeparturePoint(p::AbstractPulley)::Geometry2D.Point
Returns the point of departure.
"""
function getDeparturePoint(p::AbstractPulley)::Geometry2D.Point
  return Geometry2D.pointOnCircle( p.pitch, p.aDepart )
end

"""
    getArrivalPoint(p::AbstractPulley)::Geometry2D.Point
Returns the point of arrival.
"""
function getArrivalPoint(p::AbstractPulley)::Geometry2D.Point
  return Geometry2D.pointOnCircle( p.pitch, p.arrive )
end


"""
    calculateWrappedAngle(p::AbstractPulley) :: Geometry2D.Angle
Given `p`, calculate the wrapped angle from `p.arrive` to `p.aDepart`.
Note that the wrapped angle is not restricted to <= 1 revolution, as the pulley may be wrapped multiple times.
"""
function calculateWrappedAngle(p::AbstractPulley) :: Geometry2D.Angle
  if Geometry2D.isapprox(p.axis, Geometry2D.uk, rtol=1e-3) #+z == cw
    if p.aDepart < p.arrive #negative to positive zero crossing
      angle = (2u"rad"*pi - p.arrive) + p.aDepart 
      # @printf("W] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.arrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.arrive, p.aDepart, angle)
      return uconvert(u"rad", angle) #lest Unitful drop the angle units
    else
      angle = p.aDepart - p.arrive
      # @printf("X] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.arrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.arrive, p.aDepart, angle)
      return uconvert(u"rad", angle)
    end
  elseif Geometry2D.isapprox(p.axis, -Geometry2D.uk, rtol=1e-3) #-z == cw
    if p.aDepart < p.arrive
      angle = p.arrive-p.aDepart
      # @printf("Y] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.arrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.arrive, p.aDepart, angle)
      return uconvert(u"rad", angle)
    else
      angle = 2u"rad"*pi - p.aDepart + p.arrive
      # @printf("Z] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.arrive), uconvert(u"°",p.aDepart), uconvert(u"°",angle), p.arrive, p.aDepart, angle)
      return uconvert(u"rad", angle)
    end       
  else
    error("calculateWrappedAngle: pulley axis is neither +- uk, is $(p.axis)")
    return 0°
  end
end

"""
    calculateWrappedLength(p::AbstractPulley) :: Unitful.Length
Given `p`, calculate the arclength of the wrapped segment from `p.arrive` to `p.aDepart`
Note that the wrapped length is not restricted to <= 1 revolution, as the pulley may be wrapped multiple times.
"""
function calculateWrappedLength(p::AbstractPulley) :: Unitful.Length
  # cwa = calculateWrappedAngle(p)
  # cal = Geometry2D.circleArcLength(p.pitch, cwa)
  # return cal

  # return Geometry2D.circleArcLength( p.pitch, calculateWrappedAngle(p)) 
  return uconvert(u"m", Geometry2D.circleArcLength( p.pitch, calculateWrappedAngle(p)) ) #cancel m*rad
end

"""
    pulley2Circle(p::AbstractPulley) :: Geometry2D.Circle
Returns the pitch Circle of `p`.
"""
function pulley2Circle(p::AbstractPulley) :: Geometry2D.Circle
    return p.pitch
end

"""
    printPulley(p::AbstractPulley)
Prints the result of [`pulley2String`](@ref) to the standard output
"""
function printPulley(p::AbstractPulley)
  println(pulley2String(p))
end



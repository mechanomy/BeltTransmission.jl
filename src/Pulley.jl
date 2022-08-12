export AbstractPulley, getDeparturePoint, getArrivalPoint, calculateWrappedAngle, calculateWrappedLength, pulley2Circle, pulley2String, printPulley, pitchLength, calculateRatio, calculateRatios


"""
  Subtypes of AbstractPulley model a particular form of pulley.
  At present that includes [PlainPulley](#BeltTransmission.PlainPulley)s, having cylindrical faces, and [SynchronousPulley](#BeltTransmission.TimingPulley).
  All subtypes have basic fields of `pitch::Circle`, `axis::UnitVector`, `arrive::Angle`, `depart::Angle`, and a `name::String`.
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
  Function to `show()` a AbstractPulley via [`pulley2String`](#BeltTransmission.pulley2String).
"""
function Base.show(io::IO, p::AbstractPulley)
  print(io, pulley2String(p))
end

"""
    getDeparturePoint(p::AbstractPulley)::Geometry2D.Point
  Returns the point of departure.
"""
function getDeparturePoint(p::AbstractPulley)::Geometry2D.Point
  return Geometry2D.pointOnCircle( p.pitch, p.depart )
end

"""
    getArrivalPoint(p::AbstractPulley)::Geometry2D.Point
  Returns the point of arrival.
"""
function getArrivalPoint(p::AbstractPulley)::Geometry2D.Point
  return Geometry2D.pointOnCircle( p.pitch, p.arrive )
end

"""
    pitchLength(p::AbstractPulley) :: Unitful.Length
  Returns the circumferential length of the pitch diameter of the pulley.
"""
function pitchLength(p::AbstractPulley) :: Unitful.Length
  # return Geometry2D.circumference(p.pitch)
  return p.pitch.radius * 2 * π
end

"""
    calculateWrappedAngle(p::AbstractPulley) :: Geometry2D.Angle
  Given `p`, calculate the wrapped angle from `p.arrive` to `p.depart`.
  Note that the wrapped angle is not restricted to <= 1 revolution, as the pulley may be wrapped multiple times.
"""
function calculateWrappedAngle(p::AbstractPulley) :: Geometry2D.Angle
  if Geometry2D.isapprox(p.axis, Geometry2D.uk, rtol=1e-3) #+z == cw
    if p.depart < p.arrive #negative to positive zero crossing
      angle = (2u"rad"*pi - p.arrive) + p.depart 
      # @printf("W] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.arrive), uconvert(u"°",p.depart), uconvert(u"°",angle), p.arrive, p.depart, angle)
      return uconvert(u"rad", angle) #lest Unitful drop the angle units
    else
      angle = p.depart - p.arrive
      # @printf("X] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.arrive), uconvert(u"°",p.depart), uconvert(u"°",angle), p.arrive, p.depart, angle)
      return uconvert(u"rad", angle)
    end
  elseif Geometry2D.isapprox(p.axis, -Geometry2D.uk, rtol=1e-3) #-z == cw
    if p.depart < p.arrive
      angle = p.arrive-p.depart
      # @printf("Y] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.arrive), uconvert(u"°",p.depart), uconvert(u"°",angle), p.arrive, p.depart, angle)
      return uconvert(u"rad", angle)
    else
      angle = 2u"rad"*pi - p.depart + p.arrive
      # @printf("Z] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.arrive), uconvert(u"°",p.depart), uconvert(u"°",angle), p.arrive, p.depart, angle)
      return uconvert(u"rad", angle)
    end       
  else
    error("calculateWrappedAngle: pulley axis is neither +- uk, is $(p.axis)")
    return 0°
  end
end

"""
    calculateWrappedLength(p::AbstractPulley) :: Unitful.Length
  Given `p`, calculate the arclength of the wrapped segment from `p.arrive` to `p.depart`
  Note that the wrapped length is not restricted to <= 1 revolution, as the pulley may be wrapped multiple times.
"""
function calculateWrappedLength(p::AbstractPulley) :: Unitful.Length
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
  Prints the result of [`pulley2String`](#BeltTransmission.pulley2String) to the standard output
"""
function printPulley(p::AbstractPulley)
  println(pulley2String(p))
end


"""
  $TYPEDSIGNATURES
  Calculate the transmission ratio between pulleys `driving` and `driven`, with the ratio defined as `driven/driving`, being >1 when the driven pulley rotates more than the driving and <1 less.
  This can be developed from the belt translation or velocity, as:

    xBelt = thA*rA = thB * rB; thB = thA * rA/rB
    vBelt = wA*rA = wB*rB; wB = wA * rA/rB 

  Pulleys having a positive transmission ratio rotate in the same direction, negative opposing.
"""
function calculateRatio( driving::T, driven::U)::Real where {T<:AbstractPulley, U<:AbstractPulley} 
  si = dot( Geometry2D.toVector(driving.axis), Geometry2D.toVector(driven.axis))  #if they align
  if abs(si) ≈ 1
    return driving.pitch.radius / driven.pitch.radius * si
  else
    @warn "Pulley axes not parallel when calculating ratio: [$(driving.axis)] vs [$(driven.axis)], this is a planar analysis!"
    return driving.pitch.radius / driven.pitch.radius 
  end
end

"""
  $TYPEDSIGNATURES
  Calculate the transmission ratio matrix between all pulleys, returning a matrix of ratios.
  Pulleys are numbered according to their order in `pulleys`, with the ratio as in [calculateRatio](#BeltTransmission.calculateRatio).
"""
function calculateRatios( pulleys::Vector{T} ) where T<:AbstractPulley
  np = length(pulleys)
  ratios = zeros(np,np)
  for i in 1:np
    for j in 1:np
      ratios[i,j] = calculateRatio( pulleys[i], pulleys[j])
    end
  end
  return ratios
end


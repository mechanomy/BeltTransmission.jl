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
    getDeparturePoint(p::AbstractPulley)::Geometry2D.Point2D
  Returns the point of departure.
"""
function getDeparturePoint(p::AbstractPulley)::Geometry2D.Point2D
  return Geometry2D.pointOnCircle( p.pitch, p.depart )
end

"""
    getArrivalPoint(p::AbstractPulley)::Geometry2D.Point2D
  Returns the point of arrival.
"""
function getArrivalPoint(p::AbstractPulley)::Geometry2D.Point2D
  return Geometry2D.pointOnCircle( p.pitch, p.arrive )
end

"""
    pitchLength(p::AbstractPulley) :: AbstractLength
  Returns the circumferential length of the pitch diameter of the pulley.
"""
function pitchLength(p::AbstractPulley) :: AbstractLength
  # return Geometry2D.circumference(p.pitch)
  return p.pitch.radius * 2 * π
end

"""
    calculateWrappedAngle(p::AbstractPulley) :: Geometry2D.Angle
  Given `p`, calculate the wrapped angle from `p.arrive` to `p.depart`.
  Note that the wrapped angle is not restricted to <= 1 revolution, as the pulley may be wrapped multiple times.
"""
function calculateWrappedAngle(p::AbstractPulley) :: AbstractAngle
  if Geometry2D.isapprox(p.axis, Geometry2D.uk, rtol=1e-3) #+z == cw
    if p.depart < p.arrive #negative to positive zero crossing
      angle = (Radian(2)*pi - p.arrive) + p.depart 
      # @printf("W] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.arrive), uconvert(u"°",p.depart), uconvert(u"°",angle), p.arrive, p.depart, angle)
      return angle
    else
      angle = p.depart - p.arrive
      # @printf("X] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.arrive), uconvert(u"°",p.depart), uconvert(u"°",angle), p.arrive, p.depart, angle)
      return angle
    end
  elseif Geometry2D.isapprox(p.axis, -Geometry2D.uk, rtol=1e-3) #-z == cw
    if p.depart < p.arrive
      angle = p.arrive-p.depart
      # @printf("Y] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.arrive), uconvert(u"°",p.depart), uconvert(u"°",angle), p.arrive, p.depart, angle)
      return angle
    else
      angle = Radian(2)*pi - p.depart + p.arrive
      # @printf("Z] %s: %s -- %s = %s == %s -- %s = %s\n", p.name, uconvert(u"°",p.arrive), uconvert(u"°",p.depart), uconvert(u"°",angle), p.arrive, p.depart, angle)
      return angle
    end       
  else
    error("calculateWrappedAngle: pulley axis is neither +- uk, is $(p.axis)")
    return Radian(0)
  end
end
@testitem "calculateWrappedAngle" begin
  using Geometry2D
  using UnitTypes

  cir = Geometry2D.Circle(MilliMeter(3),MilliMeter(5), MilliMeter(4) )
  pa = PlainPulley(cir, Geometry2D.uk, Radian(1), Radian(2), "struct" ) 
  @test calculateWrappedAngle( pa ) ≈ Radian(1)

  pa = PlainPulley(cir, Geometry2D.uk, Radian(1), Radian(0), "struct" ) 
  @test calculateWrappedAngle( pa ) ≈ Radian(2*π-1) #from arrive to depart

  pa = PlainPulley(cir, Geometry2D.uk, Radian(0), Radian(7), "struct" ) 
  @test calculateWrappedAngle( pa ) ≈ Radian(7) 
end


"""
    calculateWrappedLength(p::AbstractPulley) :: AbstractLengthAbstractLength
  Given `p`, calculate the arclength of the wrapped segment from `p.arrive` to `p.depart`
  Note that the wrapped length is not restricted to <= 1 revolution, as the pulley may be wrapped multiple times.
"""
function calculateWrappedLength(p::AbstractPulley) :: AbstractLength
  return Geometry2D.circleArcLength( p.pitch, calculateWrappedAngle(p) )
end
@testitem "calculateWrappedLength" begin
  using Geometry2D
  using UnitTypes
  cir = Geometry2D.Circle(MilliMeter(3),MilliMeter(5), MilliMeter(4) )
  pa = PlainPulley(cir, Geometry2D.uk, Radian(1), Radian(2), "struct" ) 
  @test calculateWrappedLength( pa ) ≈ MilliMeter(4)

  @test typeof(pa) <: AbstractPulley
  @test pitchLength(pa) ≈ 2*π*MilliMeter(4)
end

@testitem "calculateWrappedLength" begin
  using Geometry2D
  using UnitTypes
  pa = PlainPulley(Geometry2D.Circle(MilliMeter(0),MilliMeter(0), MilliMeter(4)), Geometry2D.uk, Radian(1), Radian(2), "pulley") 
  @test typeof( pulley2String(pa) ) <: String #this can't break...but still want to exercise the function
end

"""
    pulley2Circle(p::AbstractPulley) :: Geometry2D.Circle
  Returns the pitch Circle of `p`.
"""
function pulley2Circle(p::AbstractPulley) :: Geometry2D.Circle
    return p.pitch
end
@testitem "pulley2Circle" begin #not a useful test
  using Geometry2D
  using UnitTypes
  pa = PlainPulley(Geometry2D.Circle(MilliMeter(0),MilliMeter(0), MilliMeter(4)), Geometry2D.uk, Radian(1), Radian(2), "pulley") 
  circle = pulley2Circle( pa )
  @test typeof(circle) <: Geometry2D.Circle
  @test circle.center.x ≈ MilliMeter(0)
  @test circle.center.y ≈ MilliMeter(0)
  @test circle.radius ≈ MilliMeter(4)
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
    return toBaseFloat(driving.pitch.radius) / toBaseFloat(driven.pitch.radius) * si
  else
    @warn "Pulley axes not parallel when calculating ratio: [$(driving.axis)] vs [$(driven.axis)], this is a planar analysis!"
    return toBaseFloat(driving.pitch.radius) / toBaseFloat(driven.pitch.radius)
  end
end
@testitem "calculateRatio" begin
  using Geometry2D
  using UnitTypes
  uk = Geometry2D.uk
  pA = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(100), MilliMeter(100),  MilliMeter(10)), axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100),MilliMeter(100),  MilliMeter(15)), axis=uk, name="B")
  pC = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100),MilliMeter(-100), MilliMeter(43)), axis=uk, name="C")
  pD = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(100), MilliMeter(-100), MilliMeter(14)), axis=uk, name="D") 
  pE = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(80),  MilliMeter(-200), MilliMeter(14)), axis=-uk, name="E") 
  solved = calculateRouteAngles([pA,pB,pC,pD,pE])
  @test calculateRatio(pA, pB) < 1 # vbelt = wA*rA = wB*rB; wB = wA * rA/rB = wA * 1+
  @test calculateRatio(pA, pB) ≈ toBaseFloat(pA.pitch.radius)/toBaseFloat(pB.pitch.radius)
  @test calculateRatio(pA, pC) ≈ toBaseFloat(pA.pitch.radius)/toBaseFloat(pC.pitch.radius)
  @test calculateRatio(pA, pE) ≈ -toBaseFloat(pA.pitch.radius)/toBaseFloat(pE.pitch.radius) # A and E rotate oppositely
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
@testitem "calculateRatios" begin
  using Geometry2D
  using UnitTypes
  uk = Geometry2D.uk
  pA = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100), MilliMeter(100), MilliMeter(10)), axis=uk, name="A")
  pB = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100), MilliMeter(100), MilliMeter(15)), axis=uk, name="B")
  pC = PlainPulley( pitch=Geometry2D.Circle(MilliMeter(-100),MilliMeter(-100), MilliMeter(43)), axis=uk, name="C")
  pD = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(100),MilliMeter(-100), MilliMeter(14)), axis=uk, name="D") 
  pE = PlainPulley( pitch=Geometry2D.Circle( MilliMeter(80),MilliMeter(-200), MilliMeter(14)), axis=-uk, name="E") 

  solved = calculateRouteAngles([pA,pB,pC,pD,pE])
  rats = calculateRatios( solved )
  @test rats[1,1] ≈ 1
  @test rats[1,2] ≈ calculateRatio(pA, pB)
  @test rats[2,1] ≈ calculateRatio(pB, pA)
end


@recipe(PlotPulley, pulley) do scene # creates pulleyplot() and pulleyplot!() 
  Theme()
  Attributes(
    widthBelt=3,
    colorBelt=:magenta,
    colorPulley="#4040ff55",
    nCircle=100 # number of points on a circle
  )
end
# function Makie.plot!(pp::PlotPulley)
function Makie.plot!(pp::PlotPulley{<:Tuple{<:AbstractPulley}})
  pulley = pp[:pulley][] # extract the Pulley from the pp, [] to unroll the observable

  # pulley body
  x = toBaseFloat(pulley.pitch.center.x) # all plotting is in base unit, user can change axes if wanted
  y = toBaseFloat(pulley.pitch.center.y)
  rOut = toBaseFloat(pulley.pitch.radius)
  rIn = rOut*0.1
  ths = LinRange(0, 2*π, pp[:nCircle][])
  ptsOut = map(t->Point2f(x + rOut*cos(t), y + rOut*sin(t)), ths)
  ptsIn  = map(t->Point2f(x + rIn*cos(t) , y + rIn*sin(t)),  ths) # put rIn* inside Point2F to ensure it comes out as 2f!
  pulleyGon = Makie.GeometryBasics.Polygon( ptsOut, [ptsIn] )
  poly!(pp, pulleyGon, color=pp[:colorPulley][]) # needs to be given pp in place of the axs... https://github.com/MakieOrg/Makie.jl/issues/4039
  
  # wrapped segment:
  #  fix zero crossings:
  pad = pulley.depart
  if pulley.axis≈Geometry2D.uk && pulley.depart < pulley.arrive #positive rotation, need to increase depart by 2pi
    pad += Radian(2*π)
  end
  paa = pulley.arrive
  if pulley.axis ≈ -Geometry2D.uk && pulley.arrive < pulley.depart
    paa += Radian(2*π)
  end

  ths = LinRange(paa, pad, pp[:nCircle][])
  xs = x .+ rOut .* cos.(ths)
  ys = y .+ rOut .* sin.(ths)
  lines!(pp, xs,ys, color=pp[:colorBelt][], linewidth=pp[:widthBelt][] )

  return pp
end

@testitem "plotPulley recipe" begin
  using UnitTypes, Geometry2D
  using CairoMakie, MakieCore
  ppa = PlainPulley(Geometry2D.Circle(MilliMeter(0),MilliMeter(0), MilliMeter(4)), Geometry2D.uk, Radian(1), Radian(4), "PlainPulleyA") 
  p = plotpulley(ppa, widthBelt=4, colorBelt=:red, colorPulley=:blue, nCircle=80)
  @test typeof(p) <: Makie.FigureAxisPlot
  # display(p);

  fig = Figure(backgroundcolor="#bbb", size=(1000,1000))
  axs = Axis(fig[1,1], xlabel="X", ylabel="Y", aspect=DataAspect())
  p = plotpulley!(axs, ppa, widthBelt=4, colorBelt=:red, colorPulley=:blue, nCircle=80)
  @test typeof(p) <: MakieCore.Plot
  # display(p);
end


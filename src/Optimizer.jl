
export Optimizer

"""
Provides functions for optimizing belt transmissions according to various metrics.
"""
module Optimizer
using DocStringExtensions 
import NLopt
using UnitTypes
using TestItems

import Geometry2D
import ..BeltTransmission # ...module loading?


export OptimizationVariable, config, addVariable!, solveSystem

"""
  Enum defining optimizable entities as:
  * `xPosition` = the x position of the pulley center
  * `yPosition` = the y position of the pulley center
  * `radius` = the pulley pitch radius
"""
@enum OptimizationVariable begin
  xPosition
  yPosition
  radius
end

"""
  The `Config` struct holds optimization configuration options and system information.
  $TYPEDFIELDS
"""
mutable struct Config # options for optimizing pulley positions
  """Belt information"""
  belt::BeltTransmission.AbstractBelt
  """Routing of the belt through the pulleys."""
  routing::Vector{BeltTransmission.AbstractPulley} #overall routing, with length=all pulleys
  """Vector of pulleys to be optimized, set via `addVariable`."""
  pulley::Vector{BeltTransmission.AbstractPulley} #pulley instances, with length = optimization vector
  """Vector of variables on each pulley be optimized, set via `addVariable`."""
  variable::Vector{OptimizationVariable} #with length = optimization vector
  """Vector of start values of each `variable`, set via `addVariable`."""
  start::Vector{Real} #with length = optimization vector
  """Vector of lower bounds of each `variable`, set via `addVariable`."""
  lower::Vector{Real} #with length = optimization vector
  """Vector of upper bounds of each `variable`, set via `addVariable`."""
  upper::Vector{Real} #with length = optimization vector
  """Options for the NLOpt optimization algorithm, see [NLOpt's documentation](https://github.com/JuliaOpt/NLopt.jl)."""
  nlOptions::NLopt.Opt
end

"""
  $TYPEDSIGNATURES
  Constructor of `Config` objects, sets default optimization options in the `.nlOptions` field.
  `nConstraints` is the number of constraints that will be added through `addVariable`.
"""
function Config(belt::BeltTransmission.AbstractBelt, routing::Vector{BeltTransmission.AbstractPulley}, nConstraints::Int) 
  nop = NLopt.Opt(NLopt.LN_COBYLA, nConstraints) 
  nop.stopval = 1e-3
  nop.ftol_rel = 1e-3
  nop.ftol_abs = 1e-3
  nop.maxeval = 1000
  nop.maxtime = 60
  return Config(belt, routing, [], [], [], [], [], nop )
end

"""
  $TYPEDSIGNATURES
  Find the index of `p` in `routing`.
"""
function lookupPulley(routing::Vector{BeltTransmission.AbstractPulley}, p::BeltTransmission.AbstractPulley) :: Int
  for (ip,rp) in enumerate(routing)
    if rp.name == p.name
      return ip
    end
  end
  @warn "Given pulley [$p] is not in the given routing."
  return nothing
end

@testitem "lookupPulley" begin
  using UnitTypes, Geometry2D
  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(100), MilliMeter(100)), axis=uk, nGrooves=62, beltPitch=MilliMeter(2), name="1A" )
  pB = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(-100), MilliMeter(100)), axis=uk, nGrooves=30, beltPitch=MilliMeter(2), name="2B" )
  pC = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(-100),MilliMeter(-100)), axis=uk, nGrooves=80, beltPitch=MilliMeter(2), name="3C" )
  pD = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(100),MilliMeter(-100)), axis=uk, nGrooves=30, beltPitch=MilliMeter(2), name="4D" )
  pE = PlainPulley( pitch=Geometry2D.Circle(   MilliMeter(0),   MilliMeter(0), MilliMeter(14)), axis=-uk, name="5E") # -uk axis engages the backside of the belt
  pRoute = [pA, pB, pC, pD, pE]

  @test BeltTransmission.Optimizer.lookupPulley(pRoute, pB) == 2
  @test BeltTransmission.Optimizer.lookupPulley(pRoute, pC) == 3
  @test BeltTransmission.Optimizer.lookupPulley(pRoute, pE) == 5
end

"""
  $TYPEDSIGNATURES
  Adds `variable` on `pulley` to the list of entities to optimize over.
  [`solveSystem`](#BeltTransmission.Optimizer.solveSystem) will evaluate values of the `variable`, starting at `start`, between `low` and `up`.
"""
function addVariable!(opts::Config, pulley::BeltTransmission.AbstractPulley, variable::OptimizationVariable; low::Real, start::Real, up::Real)
  push!(opts.pulley, pulley)
  push!(opts.variable, variable)
  push!(opts.start, start)
  push!(opts.lower, low)
  push!(opts.upper, up)
end

"""
  $TYPEDSIGNATURES
  Converts optmization vector `ox` into a solved belt system via the system description in `opts`.
"""
function x2route(opts::Config, ox::Vector{T}) where T<:Real
  route = opts.routing
  for iv in 1:length(opts.variable)
    ir = lookupPulley(route, opts.pulley[iv])
    x = MilliMeter(route[ir].pitch.center.x ).value
    y = MilliMeter(route[ir].pitch.center.y ).value
    r = MilliMeter(route[ir].pitch.radius ).value
    if opts.variable[iv] == xPosition
      x = ox[iv]
    end
    if opts.variable[iv] == yPosition
      y = ox[iv]
    end
    if opts.variable[iv] == radius
      r = ox[iv]
    end

    if typeof(route[ir]) <: BeltTransmission.PlainPulley
      route[ir] = BeltTransmission.PlainPulley(pitch=Geometry2D.Circle(MilliMeter(x), MilliMeter(y), MilliMeter(r)), axis=route[ir].axis, name=route[ir].name)
    end
    if typeof(route[ir]) <: BeltTransmission.SynchronousPulley
      ng = BeltTransmission.radius2NGrooves(route[ir].beltPitch, MilliMeter(r))
      route[ir] = BeltTransmission.SynchronousPulley(center=Geometry2D.Point2D(MilliMeter(x), MilliMeter(y)), nGrooves=ng, beltPitch=route[ir].beltPitch, axis=route[ir].axis, name=route[ir].name)
    end
    # println("$iv: $x vs $(route[ir].pitch.center.x)")
  end
  opts.routing = route
  return route
end

"""
  $TYPEDSIGNATURES
  Solves the system descriped by `opts`, returning the solved system.  
"""
function solveSystem( opts::Config )::BeltTransmission.AbstractVectorPulley
# function solveSystem( opts::Config )::Vector{T} where T <: BeltTransmission.AbstractPulley
  function objfun(ox::Vector, ::Vector) #define within solveSystem() to inherit opts
    try #catch the invalid acos() from over-large steps
      solved = BeltTransmission.calculateRouteAngles(x2route(opts, ox))
      l = BeltTransmission.calculateBeltLength(solved)
      return (opts.belt.length-l).value^2
    catch err
      if isa(err, DomainError) && err.msg == "acos(x) not defined for |x| > 1"
        return Inf
      else
        rethrow(err)
      end
    end
    return Inf
  end
  
  if isnothing(opts.nlOptions)
    opts.nlOptions = NLopt.Opt(NLopt.LN_COBYLA, length(opts.pulley)) #the need for opts.pulley prevents this from being in the constructor
    opts.nlOptions.stopval = 1e-3
    opts.nlOptions.ftol_rel = 1e-3
    opts.nlOptions.ftol_abs = 1e-3
    opts.nlOptions.maxeval = 1000
    opts.nlOptions.maxtime = 60
  end

  opts.nlOptions.min_objective = objfun
  opts.nlOptions.lower_bounds = float.(opts.lower)
  opts.nlOptions.upper_bounds = float.(opts.upper)

  (optf, optx, ret) = NLopt.optimize(opts.nlOptions, float.(opts.start) )
  # x0 = float([100.1, 100.2, 100.3, 25.46])
  # @show objfun(x0)
  # (optf, optx, ret) = NLopt.optimize(opts.nlOptions, x0 )
  # @show optf
  # @show optx
  # @show ret

  solved = BeltTransmission.calculateRouteAngles(x2route(opts, optx))

  if ret == NLopt.ROUNDOFF_LIMITED
    l = BeltTransmission.calculateBeltLength(solved)
    @warn "Optimizer could not achieve the desired belt length given other constraints, desired[$(opts.belt.length)] vs solved[$l]. Try reducing the number of constraints or expanding their range."
  end
  if ret == NLopt.FORCED_STOP
    @warn "Optimizer stopped prior to completion, consider changing the starting point or constraints."
  end

  return solved
end #solveSystem()

@testitem "solveSystem" begin
  using UnitTypes, Geometry2D
  uk = Geometry2D.UnitVector(0,0,1)
  #a square of pulleys, arranged ccw from quadrant1
  pA = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(100), MilliMeter(100)), axis=uk, nGrooves=62, beltPitch=MilliMeter(2), name="1A" )
  pB = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(-100), MilliMeter(100)), axis=uk, nGrooves=30, beltPitch=MilliMeter(2), name="2B" )
  pC = SynchronousPulley( center=Geometry2D.Point2D(MilliMeter(-100),MilliMeter(-100)), axis=uk, nGrooves=80, beltPitch=MilliMeter(2), name="3C" )
  pD = SynchronousPulley( center=Geometry2D.Point2D( MilliMeter(100),MilliMeter(-100)), axis=uk, nGrooves=30, beltPitch=MilliMeter(2), name="4D" )
  pE = PlainPulley( pitch=Geometry2D.Circle(   MilliMeter(0),   MilliMeter(0), MilliMeter(14)), axis=-uk, name="5E") # -uk axis engages the backside of the belt
  pRoute = [pA, pB, pC, pD, pE]

  # x0 = float([100.1, 100.2, 100.3, 25.46])

  #x0 has l=1050mm, now reduce that to force the pulleys to move
  l = MilliMeter(1000)
  pitch = MilliMeter(8)
  n = Int(round(toBaseFloat(l)/toBaseFloat(pitch)))
  belt = BeltTransmission.SynchronousBelt(pitch=pitch, nTeeth=n, width=MilliMeter(6), profile="gt2")
  # println("Closest belt is $belt")

  po = BeltTransmission.Optimizer.Config(belt, pRoute, 4)
  BeltTransmission.Optimizer.addVariable!(po, pA, BeltTransmission.Optimizer.xPosition, low=60, start=100.1, up=113  )
  BeltTransmission.Optimizer.addVariable!(po, pA, BeltTransmission.Optimizer.yPosition, low=90, start=100.2, up=111  )
  BeltTransmission.Optimizer.addVariable!(po, pB, BeltTransmission.Optimizer.yPosition, low=90, start=100.3, up=112  )
  BeltTransmission.Optimizer.addVariable!(po, pC, BeltTransmission.Optimizer.radius, low=20, start=25, up=95  )

  solved0 = BeltTransmission.calculateRouteAngles( BeltTransmission.Optimizer.x2route(po, po.start) )
  l0 = BeltTransmission.calculateBeltLength(solved0)
  # BeltTransmission.printRoute(solved0)
  # p = plot(solved0, segmentColor=:magenta)

  solved = BeltTransmission.Optimizer.solveSystem(po)
  solvedL = BeltTransmission.calculateBeltLength(solved)
  # BeltTransmission.printRoute(solved)
  # p = plot!(solved, segmentColor=:yellow)
  # display(p)
  # @test typeof(p) <: AbstractPlot

  @test isapprox(po.belt.length, solvedL, rtol=1e-3) #check sucessful belt length
  @test po.lower[1] < MilliMeter(solved[1].pitch.center.x).value && MilliMeter(solved[1].pitch.center.x).value <  po.upper[1] 
  @test po.lower[2] < MilliMeter(solved[1].pitch.center.y).value && MilliMeter(solved[1].pitch.center.y).value <  po.upper[2] 
  @test po.lower[3] < MilliMeter(solved[2].pitch.center.y).value && MilliMeter(solved[2].pitch.center.y).value <  po.upper[3] 
  @test po.lower[4] < MilliMeter(solved[3].pitch.radius).value && MilliMeter(solved[3].pitch.radius).value <  po.upper[4] 
end


end #Optimizer

export Optimizer

"""
Provides functions for optimizing belt transmissions according to various metrics.
"""
module Optimizer
using DocStringExtensions 
using Unitful
import NLopt

import Geometry2D
import ..BeltTransmission


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
    x = ustrip(u"mm", route[ir].pitch.center.x )
    y = ustrip(u"mm", route[ir].pitch.center.y )
    r = ustrip(u"mm", route[ir].pitch.radius )
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
      route[ir] = BeltTransmission.PlainPulley(pitch=Geometry2D.Circle(x*1.0u"mm", y*1.0u"mm", r*1.0u"mm"), axis=route[ir].axis, name=route[ir].name)
    end
    if typeof(route[ir]) <: BeltTransmission.SynchronousPulley
      ng = BeltTransmission.radius2NGrooves(route[ir].beltPitch, r*1.0u"mm")
      route[ir] = BeltTransmission.SynchronousPulley(center=Geometry2D.Point(x*1.0u"mm", y*1.0u"mm"), nGrooves=ng, beltPitch=route[ir].beltPitch, axis=route[ir].axis, name=route[ir].name)
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
      return ustrip(u"mm", opts.belt.length-l)^2
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

end #Optimizer

export Optimizer

"""
Provides functions for optimizing belt transmissions according to various metrics.
"""
module Optimizer

using Unitful
import NLopt

import Geometry2D
import ..BeltTransmission


# export OptimizationVariable

# uk = Geometry2D.UnitVector(0,0,1)
# #a square of pulleys, arranged ccw from quadrant1
# pA = SynchronousPulley( center=Geometry2D.Point( 100u"mm", 100u"mm"), axis=uk, nGrooves=62, beltPitch=2u"mm", name="1A" )
# pB = SynchronousPulley( center=Geometry2D.Point(-100u"mm", 100u"mm"), axis=uk, nGrooves=30, beltPitch=2u"mm", name="2B" )
# pC = SynchronousPulley( center=Geometry2D.Point(-100u"mm",-100u"mm"), axis=uk, nGrooves=80, beltPitch=2u"mm", name="3C" )
# pD = SynchronousPulley( center=Geometry2D.Point( 100u"mm",-100u"mm"), axis=uk, nGrooves=30, beltPitch=2u"mm", name="4D" )
# pE = PlainPulley( pitch=Geometry2D.Circle(   0u"mm",   0u"mm", 14u"mm"), axis=-uk, name="5E") # -uk axis engages the backside of the belt
# pRoute = [pA, pB, pC, pD, pE]

@enum OptimizationVariable begin
  # "Optimize the pulley's position in x."
  xPosition
  # "Optimize the pulley's position in x."
  yPosition
  # "Optimize the pulley radius."
  radius
end

mutable struct PositionOpts # options for optimizing pulley positions
  belt::BeltTransmission.AbstractBelt
  routing::Vector{BeltTransmission.AbstractPulley} #overall routing, with length=all pulleys
  pulley::Vector{BeltTransmission.AbstractPulley} #pulley instances, with length = optimization vector
  variable::Vector{OptimizationVariable} #with length = optimization vector
  start::Vector{Real} #with length = optimization vector
  lower::Vector{Real} #with length = optimization vector
  upper::Vector{Real} #with length = optimization vector
end
PositionOpts(belt, routing ) = PositionOpts(belt, routing, [], [], [], [], [] )

function lookupPulley(routing::Vector{BeltTransmission.AbstractPulley}, p::BeltTransmission.AbstractPulley)
  for (ip,rp) in enumerate(routing)
    # if rp == p
    if rp.name == p.name
      return ip
    end
  end
  @warn "Given pulley [$p] is not in the given routing."
  return nothing
end

"""
  Adds the 
"""
function addVariable!(opts::PositionOpts, pulley::BeltTransmission.AbstractPulley, variable::OptimizationVariable; low::Real, start::Real, up::Real)
  push!(opts.pulley, pulley)
  push!(opts.variable, variable)
  push!(opts.start, start)
  push!(opts.lower, low)
  push!(opts.upper, up)
end

function x2route(opts::PositionOpts, ox::Vector)
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

function solveSystem( opts::PositionOpts )
  @show opts.belt
  @show opts.routing
  @show opts.pulley
  @show opts.lower
  @show opts.start
  @show opts.upper

  function objfun(ox::Vector, ::Vector) #define within solveSystem() to inherit opts
    try #catch the invalid acos() from over-large steps
      @show ox
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

  nop = NLopt.Opt(NLopt.LN_COBYLA, length(opts.pulley))
  # nop = Opt(NLopt.LN_COBYLA, 4)
  nop.min_objective = objfun
  nop.lower_bounds = float.(opts.lower)
  nop.upper_bounds = float.(opts.upper)

  nop.stopval = 1e-3
  nop.ftol_rel = 1e-3
  nop.ftol_abs = 1e-3
  nop.maxeval = 1000
  # nop.maxtime = 60

  (optf, optx, ret) = NLopt.optimize(nop, float.(opts.start) )
  # x0 = float([100.1, 100.2, 100.3, 25.46])
  # @show objfun(x0)
  # (optf, optx, ret) = NLopt.optimize(nop, x0 )
  @show optf
  @show optx
  @show ret

  solved = BeltTransmission.calculateRouteAngles(x2route(opts, optx))
  # # println("Correct idler position is [$(solved[5].pitch.center)]")

  if ret == NLopt.ROUNDOFF_LIMITED
    l = BeltTransmission.calculateBeltLength(solved)
    @warn "Solver could not achive the desired belt length given other constraints, desired[$(opts.belt.length)] vs solved[$l]"
  end
  if ret == NLopt.FORCED_STOP
    @warn "Solver stopped prior to completion"
  end

  return solved
end #solveSystem()

end #Optimizer
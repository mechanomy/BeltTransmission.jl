export BeltSystem, calculateRatios, calculateLength

"""
  A BeltSystem is an ordered set of `pulleys` connected by `segments` of some `belt`.
  $TYPEDFIELDS
"""
struct BeltSystem
  pulleys::Vector{AbstractPulley}
  segments::Vector{AbstractSegment}
  belt::AbstractBelt
end

"""
  $TYPEDSIGNATURES
  Construct a new BeltSystem, creating segments from `pulleys` and `belt`.
"""
BeltSystem(pulleys::Vector{AbstractPulley}, belt::AbstractBelt ) = BeltSystem(pulleys, route2Segments(pulleys), belt )
# calcPowerLimits(BT)

"""
  $TYPEDSIGNATURES
  Calculate the transmission ratio matrix between all pulleys, returning a matrix of ratios.
  Pulleys are numbered according to their order in `bs`, with the ratio as in [calculateRatio](#BeltTransmission.calculateRatio).
"""
function calculateRatios( bs::BeltSystem )
  return calculateRatios( bs.pulleys )
end

"""
  $TYPEDSIGNATURES
  Pass-through to [calculateBeltLength](#BeltTransmission.calculateBeltLength).
"""
function calculateLength( bs::BeltSystem )
  return calculateBeltLength( bs.pulleys )
end


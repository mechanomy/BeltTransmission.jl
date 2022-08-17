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

"""
  $TYPEDSIGNATURES
  Given a belt system, find the pulley position(s) that satisfy the given belt length.
  It does this through a linear optmization whose objective is to minimze the error between the given belt's length and the [calculateBeltLength()](#BeltTransmission.calculateBeltLength).
  Since pulleys can each move in <x,y>, the 

  `which` is an index or array to the pulley(s) that may be moved; by default all pulleys may be moved and the algorithm minimizes the total pulley movement.
  The pulleys in the `belt` system need to be placed in approximate locations in order to determine the belt routing.
  That is even if their positions are not final some position must be given when creating the pulleys to permit the belt length to be accurately calculated.
  Pulleys are constrained from overlap

  In a two-belt system this problem devolves to calculating the center distance between two pulleys:
  '''@example
    
  '''

  In larger systems, 
"""
function calculateCenterDistance( bs::BeltSystem, which::Integer )
# function calculateCenterDistance( a::AbstractPulley, b::AbstractPulley, belt::AbstractBelt )
  

end

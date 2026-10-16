class_name AeroSurfaceConfig
extends Resource

## Configuration parameters for 6-DoF aerodynamic surfaces.
## Implements finite-wing lift-slope approximation and non-linear stall envelopes.

@export var surface_name: String = "Wing"
@export var chord: float = 1.6          ## Mean Aerodynamic Chord (m)
@export var span: float = 4.8           ## Surface Span (m)
@export var aspect_ratio: float = 6.0   ## Aspect Ratio (span / chord)
@export var zero_lift_aoa: float = -0.035  ## Zero-lift Angle of Attack alpha_0 (rad, ~ -2.0 deg)
@export var positive_stall_angle: float = 0.2618 ## Stall AoA positive (rad, 15.0 deg)
@export var negative_stall_angle: float = -0.2094 ## Stall AoA negative (rad, -12.0 deg)
@export var skin_friction_drag: float = 0.024 ## Parasitic zero-lift profile drag coefficient C_d0
@export var oswald_efficiency: float = 0.82   ## Oswald efficiency factor e (0.70 - 0.90)
@export var flap_fraction: float = 0.28       ## Fraction of chord covered by flap/control surface (0.0 - 0.4)
@export var pitch_moment_c0: float = -0.05    ## Zero-lift pitching moment coefficient C_m0
@export var pitch_moment_slope: float = -0.15 ## Pitching moment slope C_m_alpha (dCm/dalpha)

## Returns the total planform area S = chord * span (m^2)
func get_area() -> float:
	return chord * span

## Computes finite-wing lift-slope approximation:
## a = 2*PI * AR / (AR + 2) [rad^-1]
func get_finite_lift_slope() -> float:
	var ar = aspect_ratio
	if ar <= 0.001:
		ar = span / max(chord, 0.001)
	return (2.0 * PI * ar) / (ar + 2.0)

## Computes control effectiveness parameter tau = dAlpha / dDelta
## Based on flap chord fraction approximation tau ~ 1.15 * sqrt(flap_fraction)
func get_control_effectiveness() -> float:
	if flap_fraction <= 0.0:
		return 0.0
	return clamp(1.15 * sqrt(flap_fraction), 0.1, 0.75)

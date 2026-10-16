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
@export var sweep_angle_rad: float = 0.0      ## Quarter-chord wing sweep angle Lambda (rad)

## Returns the total planform area S = chord * span (m^2)
func get_area() -> float:
	return chord * span

## Computes finite-wing lift-slope approximation:
## a = 2*PI * AR / (AR + 2) [rad^-1] (Helmbold approximation for unswept wings)
func get_finite_lift_slope() -> float:
	var ar = aspect_ratio
	if ar <= 0.001:
		ar = span / max(chord, 0.001)
	if sweep_angle_rad != 0.0:
		return get_exact_finite_lift_slope(sweep_angle_rad)
	return (2.0 * PI * ar) / (ar + 2.0)

## Computes exact finite-wing lift-slope including quarter-chord sweep angle Lambda:
## C_L_alpha = (2*PI * AR) / (2 + sqrt(4 + AR^2 * (1 + tan^2(Lambda))))
func get_exact_finite_lift_slope(sweep: float = 0.0) -> float:
	var ar = aspect_ratio
	if ar <= 0.001:
		ar = span / max(chord, 0.001)
	var tan_sweep = tan(sweep)
	var term = 4.0 + (ar * ar) * (1.0 + tan_sweep * tan_sweep)
	return (2.0 * PI * ar) / (2.0 + sqrt(term))

## Computes induced drag coefficient C_Di = (C_L^2 / (PI * e * AR)) * sigma_ground
func get_induced_drag_coefficient(cl: float, sigma_ground: float = 1.0) -> float:
	var ar = max(aspect_ratio, 0.1)
	var e = max(oswald_efficiency, 0.1)
	var cd_induced_clean = (cl * cl) / (PI * ar * e)
	return cd_induced_clean * clamp(sigma_ground, 0.05, 1.0)

## Computes control effectiveness parameter tau = dAlpha / dDelta
## Based on flap chord fraction approximation tau ~ 1.15 * sqrt(flap_fraction)
func get_control_effectiveness() -> float:
	if flap_fraction <= 0.0:
		return 0.0
	return clamp(1.15 * sqrt(flap_fraction), 0.1, 0.75)

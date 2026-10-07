class_name ApexSensitivity
## Apex Legends mouse and FOV math.
##
## Apex inherits Source's yaw: one raw mouse count turns the view 0.022 degrees at
## sensitivity 1. Its FOV is a horizontal FOV measured on a 4:3 screen, stored in
## profile.cfg as cl_fovScale (true 4:3 FOV = cl_fovScale * 70).

const DEGREES_PER_COUNT := 0.022
const CM_PER_INCH := 2.54
const FOV_SCALE_BASE := 70.0
## The in-game slider moves cl_fovScale by this much per step, so slider 110 is 108.5 degrees.
const FOV_SLIDER_STEP := 0.01375


## Degrees the view turns for one raw mouse count.
static func degrees_per_count(sensitivity: float, zoom_scalar: float = 1.0) -> float:
	return DEGREES_PER_COUNT * sensitivity * zoom_scalar


## Mouse travel for a full 360 degree turn.
static func cm_per_360(sensitivity: float, dpi: float, zoom_scalar: float = 1.0) -> float:
	var counts := 360.0 / degrees_per_count(sensitivity, zoom_scalar)
	return counts / dpi * CM_PER_INCH


## The 4:3 horizontal FOV Apex actually renders for an in-game slider value.
static func fov_from_slider(slider: float) -> float:
	return FOV_SCALE_BASE * (1.0 + (slider - FOV_SCALE_BASE) * FOV_SLIDER_STEP)


static func fov_from_scale(cl_fov_scale: float) -> float:
	return FOV_SCALE_BASE * cl_fov_scale


## The in-game slider value that writes a given cl_fovScale.
static func slider_from_scale(cl_fov_scale: float) -> float:
	return FOV_SCALE_BASE + (cl_fov_scale - 1.0) / FOV_SLIDER_STEP


## Vertical FOV for Camera3D.fov (keep_aspect = KEEP_HEIGHT). Apex keeps the vertical FOV
## of its 4:3 frame and shows more horizontally on wider screens.
static func vertical_fov(fov_4_3: float) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(fov_4_3) / 2.0) * 3.0 / 4.0))


## Horizontal FOV seen on a screen with the given aspect ratio.
static func horizontal_fov(fov_4_3: float, aspect: float) -> float:
	return rad_to_deg(2.0 * atan(tan(deg_to_rad(fov_4_3) / 2.0) * aspect * 3.0 / 4.0))

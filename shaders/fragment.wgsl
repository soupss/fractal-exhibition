struct Color {
    colors: array<vec4<f32>>,
}

struct Camera {
    pos: vec3<f32>,
    right: vec3<f32>,
    forward: vec3<f32>,
    up: vec3<f32>,
}

struct Uniform {
    resolution: vec2<f32>,
    t: f32,
    camera: Camera,
}

struct FragmentOutput {
    @location(0) color_frag: vec4<f32>,
}

@group(0) @binding(0) 
var<storage> global: Color;
@group(1) @binding(0) 
var<uniform> u: Uniform;
var<private> color_frag: vec4<f32>;
var<private> gl_FragCoord_1: vec4<f32>;

fn main_1() {
    var x: u32;
    var y: u32;
    var i: u32;

    let _e11 = gl_FragCoord_1;
    x = u32(_e11.x);
    let _e15 = gl_FragCoord_1;
    y = u32(_e15.y);
    let _e19 = y;
    let _e20 = u;
    let _e26 = x;
    i = ((_e19 * u32(i32(_e20.resolution.x))) + _e26);
    let _e29 = i;
    let _e31 = global.colors[_e29];
    color_frag = _e31;
    return;
}

@fragment 
fn main(@builtin(position) gl_FragCoord: vec4<f32>) -> FragmentOutput {
    gl_FragCoord_1 = gl_FragCoord;
    main_1();
    let _e14 = color_frag;
    return FragmentOutput(_e14);
}

struct state {
    world_global: i32,
}

struct Camera {
    pos: vec3<f32>,
    right: vec3<f32>,
    forward: vec3<f32>,
    up: vec3<f32>,
}

struct frame {
    resolution: vec2<f32>,
    t: f32,
    t_start: f32,
    camera: Camera,
    camera_pos_prev: vec3<f32>,
}

struct Material {
    albedo: vec3<f32>,
    roughness: f32,
    metallic: f32,
}

struct Light {
    pos: vec3<f32>,
    color: vec3<f32>,
    strength: f32,
}

const SUB_WORLDS: array<i32, 5> = array<i32, 5>(2i, 1i, 3i, 4i, 5i);

@group(0) @binding(0) 
var rendertarget: texture_storage_2d<rgba8unorm,write>;
@group(0) @binding(1) 
var<storage, read_write> global: state;
var<private> world_ray: i32;
@group(1) @binding(0) 
var<uniform> u_2: frame;
var<private> g_trap: vec4<f32> = vec4(10000000000f);
var<private> gl_GlobalInvocationID_1: vec3<u32>;

fn use_heightmap() -> bool {
    var res: bool;

    let _e6 = world_ray;
    let _e9 = world_ray;
    let _e13 = world_ray;
    let _e17 = world_ray;
    if ((((_e6 == 0i) || (_e9 == 1i)) || (_e13 == 2i)) || (_e17 == 5i)) {
        {
            res = false;
        }
    } else {
        let _e22 = world_ray;
        let _e25 = world_ray;
        if ((_e22 == 3i) || (_e25 == 4i)) {
            {
                res = true;
            }
        }
    }
    let _e30 = res;
    return _e30;
}

fn sd_sphere(p: vec3<f32>, r: f32) -> f32 {
    var p_1: vec3<f32>;
    var r_1: f32;

    p_1 = p;
    r_1 = r;
    let _e20 = p_1;
    let _e22 = r_1;
    return (length(_e20) - _e22);
}

fn sd_plane(p_2: vec3<f32>, n: vec3<f32>) -> f32 {
    var p_3: vec3<f32>;
    var n_1: vec3<f32>;

    p_3 = p_2;
    n_1 = n;
    let _e20 = p_3;
    let _e21 = n_1;
    return dot(_e20, _e21);
}

fn sd_box(p_4: vec3<f32>, b: vec3<f32>) -> f32 {
    var p_5: vec3<f32>;
    var b_1: vec3<f32>;
    var q: vec3<f32>;

    p_5 = p_4;
    b_1 = b;
    let _e20 = p_5;
    let _e22 = b_1;
    q = (abs(_e20) - _e22);
    let _e25 = q;
    let _e30 = q;
    let _e32 = q;
    let _e34 = q;
    return (length(max(_e25, vec3(0f))) + min(max(_e30.x, max(_e32.y, _e34.z)), 0f));
}

fn sd_ellipsoid(p_6: vec3<f32>, r_2: vec3<f32>) -> f32 {
    var p_7: vec3<f32>;
    var r_3: vec3<f32>;
    var k0_: f32;
    var k1_: f32;

    p_7 = p_6;
    r_3 = r_2;
    let _e20 = p_7;
    let _e21 = r_3;
    k0_ = length((_e20 / _e21));
    let _e25 = p_7;
    let _e26 = r_3;
    let _e27 = r_3;
    k1_ = length((_e25 / (_e26 * _e27)));
    let _e32 = k0_;
    let _e33 = k0_;
    let _e37 = k1_;
    return ((_e32 * (_e33 - 1f)) / _e37);
}

fn rotate_2d(a: f32) -> mat2x2<f32> {
    var a_1: f32;
    var c: f32;
    var s: f32;

    a_1 = a;
    let _e18 = a_1;
    c = cos(_e18);
    let _e21 = a_1;
    s = sin(_e21);
    let _e24 = c;
    let _e25 = s;
    let _e26 = s;
    let _e28 = c;
    return mat2x2<f32>(vec2<f32>(_e24, _e25), vec2<f32>(-(_e26), _e28));
}

fn smootherstep(edge0_: f32, edge1_: f32, x: vec3<f32>) -> vec3<f32> {
    var edge0_1: f32;
    var edge1_1: f32;
    var x_1: vec3<f32>;

    edge0_1 = edge0_;
    edge1_1 = edge1_;
    x_1 = x;
    let _e22 = x_1;
    let _e23 = edge0_1;
    let _e24 = edge1_1;
    x_1 = clamp(_e22, vec3(_e23), vec3(_e24));
    let _e28 = x_1;
    let _e29 = x_1;
    let _e31 = x_1;
    let _e33 = x_1;
    let _e34 = x_1;
    return (((_e28 * _e29) * _e31) * ((_e33 * ((_e34 * 6f) - vec3(15f))) + vec3(10f)));
}

fn sd_portal(p_8: vec3<f32>, n_2: vec3<f32>) -> f32 {
    var p_9: vec3<f32>;
    var n_3: vec3<f32>;
    var up: vec3<f32> = vec3<f32>(0f, 1f, 0f);
    var right: vec3<f32>;
    var p_local: vec3<f32>;

    p_9 = p_8;
    n_3 = n_2;
    let _e25 = up;
    let _e26 = n_3;
    right = normalize(cross(_e25, _e26));
    let _e30 = p_9;
    let _e31 = right;
    let _e33 = p_9;
    let _e34 = up;
    let _e36 = p_9;
    let _e37 = n_3;
    p_local = vec3<f32>(dot(_e30, _e31), dot(_e33, _e34), dot(_e36, _e37));
    let _e41 = p_local;
    let _e50 = sd_ellipsoid(_e41, vec3<f32>(2.3f, 3.7f, 1f));
    let _e51 = p_local;
    let _e60 = sd_box(_e51, vec3<f32>(2.3f, 3.7f, 0.00000001f));
    return max(_e50, _e60);
}

fn hash(k: f32) -> f32 {
    var k_1: f32;

    k_1 = k;
    let _e18 = k_1;
    return fract((sin((_e18 * 12.9898f)) * 43758.547f));
}

fn hash31_(p3_: vec3<f32>) -> f32 {
    var p3_1: vec3<f32>;

    p3_1 = p3_;
    let _e18 = p3_1;
    p3_1 = fract((_e18 * 0.1031f));
    let _e22 = p3_1;
    let _e23 = p3_1;
    let _e24 = p3_1;
    p3_1 = (_e22 + vec3(dot(_e23, (_e24.yzx + vec3(33.33f)))));
    let _e32 = p3_1;
    let _e34 = p3_1;
    let _e37 = p3_1;
    return fract(((_e32.x + _e34.y) * _e37.z));
}

fn hash21_(p_10: vec2<f32>) -> f32 {
    var p_11: vec2<f32>;
    var p3_2: vec3<f32>;

    p_11 = p_10;
    let _e18 = p_11;
    p3_2 = fract((vec3<f32>(_e18.xyx) * 0.1031f));
    let _e25 = p3_2;
    let _e26 = p3_2;
    let _e27 = p3_2;
    p3_2 = (_e25 + vec3(dot(_e26, (_e27.yzx + vec3(33.33f)))));
    let _e35 = p3_2;
    let _e37 = p3_2;
    let _e40 = p3_2;
    return fract(((_e35.x + _e37.y) * _e40.z));
}

fn hash23_(p_12: vec2<f32>) -> vec3<f32> {
    var p_13: vec2<f32>;
    var p3_3: vec3<f32>;

    p_13 = p_12;
    let _e18 = p_13;
    p3_3 = fract((vec3<f32>(_e18.xyx) * vec3<f32>(0.1031f, 0.103f, 0.0973f)));
    let _e28 = p3_3;
    let _e29 = p3_3;
    let _e30 = p3_3;
    p3_3 = (_e28 + vec3(dot(_e29, (_e30.yxz + vec3(33.33f)))));
    let _e38 = p3_3;
    let _e40 = p3_3;
    let _e43 = p3_3;
    return fract(((_e38.xxy + _e40.yzz) * _e43.zyx));
}

fn hash22_(p_14: vec2<f32>) -> vec2<f32> {
    var p_15: vec2<f32>;
    var p3_4: vec3<f32>;

    p_15 = p_14;
    let _e18 = p_15;
    p3_4 = fract((vec3<f32>(_e18.xyx) * vec3<f32>(0.1031f, 0.103f, 0.0973f)));
    let _e28 = p3_4;
    let _e29 = p3_4;
    let _e30 = p3_4;
    p3_4 = (_e28 + vec3(dot(_e29, (_e30.yzx + vec3(33.33f)))));
    let _e38 = p3_4;
    let _e40 = p3_4;
    let _e43 = p3_4;
    return ((fract(((_e38.xx + _e40.yz) * _e43.zy)) * 2f) - vec2(1f));
}

fn hash12_(p_16: f32) -> vec2<f32> {
    var p_17: f32;
    var p3_5: vec3<f32>;

    p_17 = p_16;
    let _e18 = p_17;
    p3_5 = fract((vec3(_e18) * vec3<f32>(0.1031f, 0.103f, 0.0973f)));
    let _e27 = p3_5;
    let _e28 = p3_5;
    let _e29 = p3_5;
    p3_5 = (_e27 + vec3(dot(_e28, (_e29.yzx + vec3(33.33f)))));
    let _e37 = p3_5;
    let _e39 = p3_5;
    let _e42 = p3_5;
    return fract(((_e37.xx + _e39.yz) * _e42.zy));
}

fn hash13_(p_18: f32) -> vec3<f32> {
    var p_19: f32;
    var p3_6: vec3<f32>;

    p_19 = p_18;
    let _e18 = p_19;
    p3_6 = fract((vec3(_e18) * vec3<f32>(0.1031f, 0.103f, 0.0973f)));
    let _e27 = p3_6;
    let _e28 = p3_6;
    let _e29 = p3_6;
    p3_6 = (_e27 + vec3(dot(_e28, (_e29.yzx + vec3(33.33f)))));
    let _e37 = p3_6;
    let _e39 = p3_6;
    let _e42 = p3_6;
    return fract(((_e37.xxy + _e39.yzz) * _e42.zyx));
}

fn hash33_(p3_7: vec3<f32>) -> vec3<f32> {
    var p3_8: vec3<f32>;

    p3_8 = p3_7;
    let _e18 = p3_8;
    p3_8 = fract((_e18 * vec3<f32>(0.1031f, 0.103f, 0.0973f)));
    let _e25 = p3_8;
    let _e26 = p3_8;
    let _e27 = p3_8;
    p3_8 = (_e25 + vec3(dot(_e26, (_e27.yxz + vec3(33.33f)))));
    let _e36 = p3_8;
    let _e38 = p3_8;
    let _e41 = p3_8;
    return ((2f * fract(((_e36.xxy + _e38.yxx) * _e41.zyx))) - vec3(1f));
}

fn smin(a_2: f32, b_2: f32, k_2: f32) -> f32 {
    var a_3: f32;
    var b_3: f32;
    var k_3: f32;
    var x_2: f32;

    a_3 = a_2;
    b_3 = b_2;
    k_3 = k_2;
    let _e22 = k_3;
    k_3 = (_e22 * 2f);
    let _e25 = b_3;
    let _e26 = a_3;
    x_2 = (_e25 - _e26);
    let _e30 = a_3;
    let _e31 = b_3;
    let _e33 = x_2;
    let _e34 = x_2;
    let _e36 = k_3;
    let _e37 = k_3;
    return (0.5f * ((_e30 + _e31) - sqrt(((_e33 * _e34) + (_e36 * _e37)))));
}

fn u_op(a_4: vec2<f32>, b_4: vec2<f32>) -> vec2<f32> {
    var a_5: vec2<f32>;
    var b_5: vec2<f32>;
    var local: vec2<f32>;

    a_5 = a_4;
    b_5 = b_4;
    let _e20 = a_5;
    let _e22 = b_5;
    if (_e20.x < _e22.x) {
        let _e25 = a_5;
        local = _e25;
    } else {
        let _e26 = b_5;
        local = _e26;
    }
    let _e28 = local;
    return _e28;
}

fn palette(k_4: f32, a_6: vec3<f32>, b_6: vec3<f32>, c_1: vec3<f32>, d: vec3<f32>) -> vec3<f32> {
    var k_5: f32;
    var a_7: vec3<f32>;
    var b_7: vec3<f32>;
    var c_2: vec3<f32>;
    var d_1: vec3<f32>;

    k_5 = k_4;
    a_7 = a_6;
    b_7 = b_6;
    c_2 = c_1;
    d_1 = d;
    let _e26 = a_7;
    let _e27 = b_7;
    let _e29 = c_2;
    let _e30 = k_5;
    let _e32 = d_1;
    return (_e26 + (_e27 * cos((6.28318f * ((_e29 * _e30) + _e32)))));
}

fn noised_value(p_20: vec2<f32>) -> vec3<f32> {
    var p_21: vec2<f32>;
    var i: vec2<f32>;
    var f: vec2<f32>;
    var u: vec2<f32>;
    var du: vec2<f32>;
    var a_8: f32;
    var b_8: f32;
    var c_3: f32;
    var d_2: f32;
    var k0_1: f32;
    var k1_1: f32;
    var k2_: f32;
    var k3_: f32;
    var noise: f32;
    var grad: vec2<f32>;

    p_21 = p_20;
    let _e18 = p_21;
    i = floor(_e18);
    let _e21 = p_21;
    f = fract(_e21);
    let _e24 = f;
    let _e25 = f;
    let _e27 = f;
    let _e29 = f;
    let _e30 = f;
    u = (((_e24 * _e25) * _e27) * ((_e29 * ((_e30 * 6f) - vec2(15f))) + vec2(10f)));
    let _e43 = f;
    let _e45 = f;
    let _e47 = f;
    let _e48 = f;
    du = (((30f * _e43) * _e45) * ((_e47 * (_e48 - vec2(2f))) + vec2(1f)));
    let _e58 = i;
    let _e59 = hash21_(_e58);
    a_8 = _e59;
    let _e61 = i;
    let _e66 = hash21_((_e61 + vec2<f32>(1f, 0f)));
    b_8 = _e66;
    let _e68 = i;
    let _e73 = hash21_((_e68 + vec2<f32>(0f, 1f)));
    c_3 = _e73;
    let _e75 = i;
    let _e80 = hash21_((_e75 + vec2<f32>(1f, 1f)));
    d_2 = _e80;
    let _e82 = a_8;
    k0_1 = _e82;
    let _e84 = b_8;
    let _e85 = a_8;
    k1_1 = (_e84 - _e85);
    let _e88 = c_3;
    let _e89 = a_8;
    k2_ = (_e88 - _e89);
    let _e92 = a_8;
    let _e93 = b_8;
    let _e95 = c_3;
    let _e97 = d_2;
    k3_ = (((_e92 - _e93) - _e95) + _e97);
    let _e100 = k0_1;
    let _e101 = k1_1;
    let _e102 = u;
    let _e106 = k2_;
    let _e107 = u;
    let _e111 = k3_;
    let _e112 = u;
    let _e115 = u;
    noise = (((_e100 + (_e101 * _e102.x)) + (_e106 * _e107.y)) + ((_e111 * _e112.x) * _e115.y));
    let _e120 = du;
    let _e121 = k1_1;
    let _e122 = k3_;
    let _e123 = u;
    let _e127 = k2_;
    let _e128 = k3_;
    let _e129 = u;
    grad = (_e120 * vec2<f32>((_e121 + (_e122 * _e123.y)), (_e127 + (_e128 * _e129.x))));
    let _e136 = noise;
    let _e137 = grad;
    let _e139 = grad;
    return vec3<f32>(_e136, _e137.x, _e139.y);
}

fn noised_gradient(p_22: vec2<f32>) -> vec3<f32> {
    var p_23: vec2<f32>;
    var i_1: vec2<f32>;
    var f_1: vec2<f32>;
    var u_1: vec2<f32>;
    var du_1: vec2<f32>;
    var ga: vec2<f32>;
    var gb: vec2<f32>;
    var gc: vec2<f32>;
    var gd: vec2<f32>;
    var va: f32;
    var vb: f32;
    var vc: f32;
    var vd: f32;
    var k0_2: f32;
    var k1_2: f32;
    var k2_1: f32;
    var k3_1: f32;
    var noise_1: f32;
    var grad_g: vec2<f32>;
    var grad_v: vec2<f32>;
    var grad_1: vec2<f32>;

    p_23 = p_22;
    let _e18 = p_23;
    i_1 = floor(_e18);
    let _e21 = p_23;
    f_1 = fract(_e21);
    let _e24 = f_1;
    let _e25 = f_1;
    let _e27 = f_1;
    let _e29 = f_1;
    let _e30 = f_1;
    u_1 = (((_e24 * _e25) * _e27) * ((_e29 * ((_e30 * 6f) - vec2(15f))) + vec2(10f)));
    let _e43 = f_1;
    let _e45 = f_1;
    let _e47 = f_1;
    let _e48 = f_1;
    du_1 = (((30f * _e43) * _e45) * ((_e47 * (_e48 - vec2(2f))) + vec2(1f)));
    let _e58 = i_1;
    let _e59 = hash22_(_e58);
    ga = _e59;
    let _e61 = i_1;
    let _e66 = hash22_((_e61 + vec2<f32>(1f, 0f)));
    gb = _e66;
    let _e68 = i_1;
    let _e73 = hash22_((_e68 + vec2<f32>(0f, 1f)));
    gc = _e73;
    let _e75 = i_1;
    let _e80 = hash22_((_e75 + vec2<f32>(1f, 1f)));
    gd = _e80;
    let _e82 = ga;
    let _e83 = f_1;
    va = dot(_e82, (_e83 - vec2<f32>(0f, 0f)));
    let _e90 = gb;
    let _e91 = f_1;
    vb = dot(_e90, (_e91 - vec2<f32>(1f, 0f)));
    let _e98 = gc;
    let _e99 = f_1;
    vc = dot(_e98, (_e99 - vec2<f32>(0f, 1f)));
    let _e106 = gd;
    let _e107 = f_1;
    vd = dot(_e106, (_e107 - vec2<f32>(1f, 1f)));
    let _e114 = va;
    k0_2 = _e114;
    let _e116 = vb;
    let _e117 = va;
    k1_2 = (_e116 - _e117);
    let _e120 = vc;
    let _e121 = va;
    k2_1 = (_e120 - _e121);
    let _e124 = va;
    let _e125 = vb;
    let _e127 = vc;
    let _e129 = vd;
    k3_1 = (((_e124 - _e125) - _e127) + _e129);
    let _e132 = k0_2;
    let _e133 = k1_2;
    let _e134 = u_1;
    let _e138 = k2_1;
    let _e139 = u_1;
    let _e143 = k3_1;
    let _e144 = u_1;
    let _e147 = u_1;
    noise_1 = (((_e132 + (_e133 * _e134.x)) + (_e138 * _e139.y)) + ((_e143 * _e144.x) * _e147.y));
    let _e152 = ga;
    let _e153 = gb;
    let _e154 = u_1;
    let _e158 = gc;
    let _e159 = gd;
    let _e160 = u_1;
    let _e164 = u_1;
    grad_g = mix(mix(_e152, _e153, vec2(_e154.x)), mix(_e158, _e159, vec2(_e160.x)), vec2(_e164.y));
    let _e169 = du_1;
    let _e170 = k1_2;
    let _e171 = k3_1;
    let _e172 = u_1;
    let _e176 = k2_1;
    let _e177 = k3_1;
    let _e178 = u_1;
    grad_v = (_e169 * vec2<f32>((_e170 + (_e171 * _e172.y)), (_e176 + (_e177 * _e178.x))));
    let _e185 = grad_v;
    let _e186 = grad_g;
    grad_1 = (_e185 + _e186);
    let _e190 = noise_1;
    let _e194 = grad_1;
    return (vec3<f32>(((0.5f * _e190) + 0.5f), _e194.x, _e194.y) / vec3(0.807f));
}

fn fbm(p_24: vec2<f32>, octaves: i32) -> f32 {
    var p_25: vec2<f32>;
    var octaves_1: i32;
    var h: f32 = 0f;
    var amp: f32 = 1f;
    var rot: mat2x2<f32> = mat2x2<f32>(vec2<f32>(0.8f, -0.6f), vec2<f32>(0.6f, 0.8f));
    var i_2: i32 = 0i;

    p_25 = p_24;
    octaves_1 = octaves;
    loop {
        let _e35 = i_2;
        let _e36 = octaves_1;
        if !((_e35 < _e36)) {
            break;
        }
        {
            let _e42 = h;
            let _e43 = amp;
            let _e44 = p_25;
            let _e45 = noised_gradient(_e44);
            h = (_e42 + (_e43 * _e45.x));
            let _e49 = amp;
            amp = (_e49 * 0.5f);
            let _e52 = rot;
            let _e53 = p_25;
            p_25 = ((_e52 * _e53) * 2f);
        }
        continuing {
            let _e39 = i_2;
            i_2 = (_e39 + 1i);
        }
    }
    let _e58 = h;
    return ((0.5f * _e58) + 0.5f);
}

fn terrain(p_26: vec2<f32>, octaves_2: i32) -> vec3<f32> {
    var p_27: vec2<f32>;
    var octaves_3: i32;
    var h_1: f32 = 0f;
    var grad_2: vec2<f32> = vec2(0f);
    var grad_eroded: vec2<f32> = vec2(0f);
    var amp_1: f32 = 1f;
    var rot_1: mat2x2<f32> = mat2x2<f32>(vec2<f32>(0.8f, -0.6f), vec2<f32>(0.6f, 0.8f));
    var m: mat2x2<f32> = mat2x2<f32>(vec2<f32>(1f, 0f), vec2<f32>(0f, 1f));
    var i_3: i32 = 0i;
    var n_4: vec3<f32>;
    var grad_octave: vec2<f32>;
    var erosion: f32;

    p_27 = p_26;
    octaves_3 = octaves_2;
    loop {
        let _e49 = i_3;
        let _e50 = octaves_3;
        if !((_e49 < _e50)) {
            break;
        }
        {
            let _e57 = p_27;
            let _e59 = noised_gradient((0.5f * _e57));
            n_4 = _e59;
            let _e61 = m;
            let _e62 = n_4;
            grad_octave = (_e61 * _e62.yz);
            let _e66 = grad_2;
            let _e67 = grad_octave;
            grad_2 = (_e66 + _e67);
            let _e71 = grad_2;
            let _e72 = grad_2;
            erosion = (1f / (1f + dot(_e71, _e72)));
            let _e77 = h_1;
            let _e78 = n_4;
            let _e80 = amp_1;
            let _e82 = erosion;
            h_1 = (_e77 + ((_e78.x * _e80) * _e82));
            let _e85 = grad_eroded;
            let _e86 = grad_octave;
            let _e87 = erosion;
            grad_eroded = (_e85 + (_e86 * _e87));
            let _e90 = amp_1;
            amp_1 = (_e90 * 0.5f);
            let _e93 = rot_1;
            let _e94 = p_27;
            p_27 = ((_e93 * _e94) * 2f);
            let _e98 = rot_1;
            let _e100 = m;
            m = (transpose(_e98) * _e100);
        }
        continuing {
            let _e53 = i_3;
            i_3 = (_e53 + 1i);
        }
    }
    let _e102 = h_1;
    let _e103 = grad_eroded;
    return vec3<f32>(_e102, _e103.x, _e103.y);
}

fn get_portal(world: i32) -> mat2x3<f32> {
    var world_1: i32;
    var pos: vec3<f32>;
    var n_5: vec3<f32>;

    world_1 = world;
    let _e20 = world_1;
    if (_e20 == 2i) {
        {
            pos = vec3<f32>(10f, 4f, 0f);
            n_5 = vec3<f32>(-1f, 0f, 0f);
        }
    } else {
        let _e32 = world_1;
        if (_e32 == 1i) {
            {
                pos = vec3<f32>(3.09017f, 4f, 9.51057f);
                n_5 = vec3<f32>(-0.309017f, 0f, -0.951057f);
            }
        } else {
            let _e45 = world_1;
            if (_e45 == 3i) {
                {
                    pos = vec3<f32>(-8.09017f, 4f, 5.87785f);
                    n_5 = vec3<f32>(0.809017f, 0f, -0.587785f);
                }
            } else {
                let _e58 = world_1;
                if (_e58 == 4i) {
                    {
                        pos = vec3<f32>(-8.09017f, 4f, -5.87785f);
                        n_5 = vec3<f32>(0.809017f, 0f, 0.587785f);
                    }
                } else {
                    let _e71 = world_1;
                    if (_e71 == 5i) {
                        {
                            pos = vec3<f32>(3.09017f, 4f, -9.51057f);
                            n_5 = vec3<f32>(-0.309017f, 0f, 0.951057f);
                        }
                    } else {
                        {
                            pos = vec3(0f);
                            n_5 = vec3<f32>(0f, 0f, 1f);
                        }
                    }
                }
            }
        }
    }
    let _e90 = pos;
    let _e91 = n_5;
    return mat2x3<f32>(vec3<f32>(_e90.x, _e90.y, _e90.z), vec3<f32>(_e91.x, _e91.y, _e91.z));
}

fn portal_entered(world_2: i32) -> bool {
    var world_3: i32;
    var portal: mat2x3<f32>;
    var pos_1: vec3<f32>;
    var n_6: vec3<f32>;
    var cam_pos_relative: vec3<f32>;
    var cam_pos_relative_prev: vec3<f32>;
    var z: f32;
    var z_prev: f32;
    var up_1: vec3<f32> = vec3<f32>(0f, 1f, 0f);
    var right_1: vec3<f32>;
    var x_3: f32;
    var y: f32;
    var x2_: f32;
    var y2_: f32;
    var w: f32 = 2.3f;
    var h_2: f32 = 3.7f;
    var w2_: f32;
    var h2_: f32;
    var intersects_xy: bool;

    world_3 = world_2;
    let _e18 = world_3;
    let _e19 = get_portal(_e18);
    portal = _e19;
    let _e23 = portal[0];
    pos_1 = _e23;
    let _e27 = portal[1];
    n_6 = _e27;
    let _e29 = u_2;
    let _e32 = pos_1;
    cam_pos_relative = (_e29.camera.pos - _e32);
    let _e35 = u_2;
    let _e37 = pos_1;
    cam_pos_relative_prev = (_e35.camera_pos_prev - _e37);
    let _e40 = cam_pos_relative;
    let _e41 = n_6;
    z = dot(_e40, _e41);
    let _e44 = cam_pos_relative_prev;
    let _e45 = n_6;
    z_prev = dot(_e44, _e45);
    let _e48 = z;
    let _e50 = z_prev;
    if (sign(_e48) != sign(_e50)) {
        {
            let _e58 = up_1;
            let _e59 = n_6;
            right_1 = normalize(cross(_e58, _e59));
            let _e63 = cam_pos_relative;
            let _e64 = right_1;
            x_3 = dot(_e63, _e64);
            let _e67 = cam_pos_relative;
            let _e68 = up_1;
            y = dot(_e67, _e68);
            let _e71 = x_3;
            let _e72 = x_3;
            x2_ = (_e71 * _e72);
            let _e75 = y;
            let _e76 = y;
            y2_ = (_e75 * _e76);
            let _e87 = w;
            let _e88 = w;
            w2_ = (_e87 * _e88);
            let _e91 = h_2;
            let _e92 = h_2;
            h2_ = (_e91 * _e92);
            let _e95 = x2_;
            let _e96 = w2_;
            let _e98 = y2_;
            let _e99 = h2_;
            intersects_xy = (((_e95 / _e96) + (_e98 / _e99)) <= 1f);
            let _e105 = intersects_xy;
            return _e105;
        }
    }
    return false;
}

fn get_world() -> i32 {
    var i_4: i32 = 0i;
    var local_1: array<i32, 5> = SUB_WORLDS;
    var world_4: i32;

    let _e16 = global.world_global;
    if (_e16 == 0i) {
        {
            loop {
                let _e21 = i_4;
                if !((_e21 < 5i)) {
                    break;
                }
                {
                    let _e28 = i_4;
                    let _e32 = local_1[_e28];
                    world_4 = _e32;
                    let _e34 = world_4;
                    let _e35 = portal_entered(_e34);
                    if _e35 {
                        let _e36 = world_4;
                        return _e36;
                    }
                }
                continuing {
                    let _e25 = i_4;
                    i_4 = (_e25 + 1i);
                }
            }
            return 0i;
        }
    } else {
        {
            let _e38 = global.world_global;
            let _e39 = portal_entered(_e38);
            if _e39 {
                return 0i;
            }
            let _e41 = global.world_global;
            return _e41;
        }
    }
    return -1i;
}

fn get_bg(world_5: i32) -> vec3<f32> {
    var world_6: i32;

    world_6 = world_5;
    let _e18 = world_6;
    if (_e18 == 0i) {
        return vec3(1f);
    } else {
        let _e23 = world_6;
        if (_e23 == 3i) {
            return vec3<f32>(0.53f, 0.81f, 0.92f);
        } else {
            let _e30 = world_6;
            if (_e30 == 4i) {
                return vec3<f32>(0.265f, 0.405f, 0.46f);
            } else {
                return vec3(0f);
            }
        }
    }
}

fn map_hub(p_28: vec3<f32>) -> vec2<f32> {
    var p_29: vec3<f32>;

    p_29 = p_28;
    return vec2<f32>(100000000f, 0f);
}

fn map_fractal(p_30: vec3<f32>) -> vec2<f32> {
    var p_31: vec3<f32>;
    var portal_1: mat2x3<f32>;
    var up_2: vec3<f32> = vec3<f32>(0f, 1f, 0f);
    var forward: vec3<f32>;
    var right_2: vec3<f32>;
    var q_1: vec3<f32>;
    var res_1: vec2<f32>;
    var s_1: f32 = 11f;
    var id: vec2<f32>;
    var d_bound: f32;
    var rot_xz: mat2x2<f32>;
    var rot_xy: mat2x2<f32>;
    var scale: f32 = 2f;
    var scaled: f32 = 1f;
    var i_5: i32 = 0i;
    var d_3: f32;

    p_31 = p_30;
    let _e20 = get_portal(1i);
    portal_1 = _e20;
    let _e29 = portal_1[1];
    forward = _e29;
    let _e31 = up_2;
    let _e32 = forward;
    right_2 = normalize(cross(_e31, _e32));
    let _e36 = p_31;
    let _e37 = right_2;
    let _e39 = p_31;
    let _e40 = up_2;
    let _e42 = p_31;
    let _e43 = forward;
    q_1 = vec3<f32>(dot(_e36, _e37), dot(_e39, _e40), dot(_e42, _e43));
    let _e47 = q_1;
    let _e57 = sd_plane((_e47 + vec3<f32>(0f, 4f, 0f)), vec3<f32>(0f, 1f, 0f));
    res_1 = vec2<f32>(_e57, 1.1f);
    let _e61 = q_1;
    let _e66 = u_2;
    q_1 = (_e61 - vec3<f32>(0f, (3.5f + (0.35f * sin((0.8f * _e66.t)))), -18f));
    let _e78 = q_1;
    let _e80 = s_1;
    id = round((_e78.xy / vec2(_e80)));
    let _e85 = id;
    let _e90 = id;
    if ((_e85.y > 0f) && (_e90.y < 15f)) {
        {
            let _e96 = q_1;
            let _e98 = q_1;
            let _e100 = s_1;
            let _e101 = id;
            let _e104 = (_e98.xy - (_e100 * round(_e101)));
            q_1.x = _e104.x;
            q_1.y = _e104.y;
            let _e109 = q_1;
            let _e111 = q_1;
            let _e114 = u_2;
            let _e117 = rotate_2d((0.1f * _e114.t));
            let _e118 = (_e111.xz * _e117);
            q_1.x = _e118.x;
            q_1.z = _e118.y;
            let _e123 = q_1;
            let _e125 = q_1;
            let _e128 = u_2;
            let _e131 = rotate_2d((0.05f * _e128.t));
            let _e132 = (_e125.yz * _e131);
            q_1.y = _e132.x;
            q_1.z = _e132.y;
            let _e137 = q_1;
            let _e139 = q_1;
            let _e142 = u_2;
            let _e146 = rotate_2d((0.05f * -(_e142.t)));
            let _e147 = (_e139.xz * _e146);
            q_1.x = _e147.x;
            q_1.z = _e147.y;
            let _e152 = q_1;
            let _e154 = sd_sphere(_e152, 10f);
            d_bound = _e154;
            let _e156 = d_bound;
            if (_e156 > 2f) {
                {
                    let _e159 = res_1;
                    let _e160 = d_bound;
                    let _e163 = u_op(_e159, vec2<f32>(_e160, 0f));
                    res_1 = _e163;
                }
            } else {
                {
                    let _e165 = u_2;
                    let _e168 = rotate_2d((0.2f * _e165.t));
                    rot_xz = _e168;
                    let _e171 = u_2;
                    let _e174 = rotate_2d((0.15f * _e171.t));
                    rot_xy = _e174;
                    loop {
                        let _e182 = i_5;
                        let _e183 = id;
                        if !((f32(_e182) < _e183.y)) {
                            break;
                        }
                        {
                            let _e191 = q_1;
                            q_1 = abs(_e191);
                            let _e193 = q_1;
                            q_1 = (_e193 - vec3<f32>(1f, 0.4f, 0.7f));
                            let _e199 = q_1;
                            let _e201 = q_1;
                            let _e203 = rot_xz;
                            let _e204 = (_e201.xz * _e203);
                            q_1.x = _e204.x;
                            q_1.z = _e204.y;
                            let _e209 = q_1;
                            let _e211 = q_1;
                            let _e213 = rot_xy;
                            let _e214 = (_e211.xy * _e213);
                            q_1.x = _e214.x;
                            q_1.y = _e214.y;
                            let _e219 = q_1;
                            let _e220 = scale;
                            q_1 = (_e219 * (_e220 * 0.8f));
                            let _e224 = scaled;
                            let _e225 = scale;
                            scaled = (_e224 * _e225);
                            let _e227 = g_trap;
                            let _e228 = q_1;
                            let _e229 = abs(_e228);
                            let _e230 = q_1;
                            g_trap = min(_e227, vec4<f32>(_e229.x, _e229.y, _e229.z, length(_e230)));
                        }
                        continuing {
                            let _e188 = i_5;
                            i_5 = (_e188 + 1i);
                        }
                    }
                    let _e237 = q_1;
                    let _e242 = sd_box(_e237, vec3<f32>(1f, 1.2f, 1f));
                    d_3 = _e242;
                    let _e244 = d_3;
                    let _e245 = scaled;
                    d_3 = (_e244 / _e245);
                    let _e247 = res_1;
                    let _e248 = d_3;
                    let _e251 = u_op(_e247, vec2<f32>(_e248, 1f));
                    res_1 = _e251;
                }
            }
        }
    }
    let _e252 = res_1;
    return _e252;
}

fn map_lavalamp(p_32: vec3<f32>) -> vec2<f32> {
    var p_33: vec3<f32>;
    var res_2: vec2<f32> = vec2<f32>(100000000f, 5f);
    var world_height: f32 = 20f;
    var d_floor: f32;
    var p_roof: vec3<f32>;
    var d_roof: f32;
    var d_world: f32;
    var s_2: f32 = 20f;
    var id_1: vec2<f32>;
    var y_1: f32;
    var d_blob: f32 = 100f;

    p_33 = p_32;
    let _e26 = p_33;
    p_33.y = (_e26.y + 4f);
    let _e31 = p_33;
    p_33.x = (_e31.x - 35f);
    let _e35 = p_33;
    let _e40 = sd_plane(_e35, vec3<f32>(0f, 1f, 0f));
    d_floor = _e40;
    let _e42 = p_33;
    let _e44 = world_height;
    p_roof = (_e42 - vec3<f32>(0f, _e44, 0f));
    let _e49 = p_roof;
    let _e55 = sd_plane(_e49, vec3<f32>(0f, -1f, 0f));
    d_roof = _e55;
    let _e57 = d_floor;
    let _e58 = d_roof;
    d_world = min(_e57, _e58);
    let _e63 = p_33;
    let _e65 = s_2;
    id_1 = round((_e63.xz / vec2(_e65)));
    let _e70 = p_33;
    let _e72 = p_33;
    let _e74 = s_2;
    let _e75 = id_1;
    let _e77 = (_e72.xz - (_e74 * _e75));
    p_33.x = _e77.x;
    p_33.z = _e77.y;
    let _e82 = world_height;
    let _e85 = world_height;
    let _e91 = id_1;
    let _e92 = hash21_(_e91);
    let _e94 = u_2;
    y_1 = ((_e82 / 2f) + ((_e85 * 0.7f) * sin(((6.2831855f * _e92) + (_e94.t * 0.6f)))));
    let _e104 = y_1;
    y_1 = (5f + (_e104 * 0.65f));
    let _e110 = id_1;
    if any((_e110 != vec2<f32>(-1f, 0f))) {
        {
            let _e117 = p_33;
            let _e119 = y_1;
            let _e129 = id_1;
            let _e130 = hash21_(_e129);
            let _e132 = u_2;
            let _e138 = sd_sphere((_e117 - vec3<f32>(0f, _e119, 0f)), (5f + (3f * sin(((6.2831855f * _e130) + _e132.t)))));
            d_blob = _e138;
        }
    }
    let _e139 = d_world;
    let _e140 = d_blob;
    let _e142 = smin(_e139, _e140, 0.5f);
    d_world = _e142;
    let _e143 = d_world;
    return vec2<f32>(_e143, 5f);
}

fn map_cloud(p_34: vec3<f32>) -> vec2<f32> {
    var p_35: vec3<f32>;
    var q_2: vec3<f32>;
    var d_4: f32;

    p_35 = p_34;
    let _e19 = p_35;
    q_2 = (_e19 - vec3<f32>(15f, 10f, -30f));
    let _e27 = q_2;
    let _e29 = sd_sphere(_e27, 10f);
    let _e32 = q_2;
    let _e36 = q_2;
    let _e41 = q_2;
    let _e45 = u_2;
    d_4 = (_e29 + (0.2f * sin(((((5f * _e32.x) + (3f * _e36.z)) - (10f * _e41.y)) - _e45.t))));
    let _e52 = d_4;
    d_4 = (_e52 * 0.2f);
    let _e55 = d_4;
    return vec2<f32>(_e55, 4f);
}

fn get_heightmap_amplitude(world_7: i32) -> f32 {
    var world_8: i32;

    world_8 = world_7;
    let _e19 = world_8;
    if (_e19 == 4i) {
        return 3f;
    }
    let _e23 = world_8;
    if (_e23 == 3i) {
        return 60f;
    } else {
        return -1f;
    }
}

fn heightmap_water(p_36: vec2<f32>) -> vec4<f32> {
    var p_37: vec2<f32>;
    var amp_2: f32;
    var h_3: f32;

    p_37 = p_36;
    let _e20 = get_heightmap_amplitude(4i);
    amp_2 = _e20;
    let _e24 = amp_2;
    let _e26 = p_37;
    let _e29 = u_2;
    h_3 = (-20f + (_e24 * sin(((0.3f * _e26.x) + _e29.t))));
    let _e36 = h_3;
    return vec4<f32>(_e36, 0f, 0f, 3f);
}

fn heightmap_mountain_octaves(p_38: vec2<f32>, octaves_4: i32) -> vec4<f32> {
    var p_39: vec2<f32>;
    var octaves_5: i32;
    var freq: f32 = 0.01f;
    var fbm_1: vec3<f32>;
    var h_4: f32;
    var amp_3: f32;
    var grad_3: vec2<f32>;

    p_39 = p_38;
    octaves_5 = octaves_4;
    let _e24 = u_2;
    let _e26 = hash12_(_e24.t_start);
    let _e28 = freq;
    let _e29 = p_39;
    let _e32 = octaves_5;
    let _e33 = terrain(((100f * _e26) + (_e28 * _e29)), _e32);
    fbm_1 = _e33;
    let _e35 = fbm_1;
    h_4 = _e35.x;
    let _e39 = get_heightmap_amplitude(3i);
    amp_3 = _e39;
    let _e41 = h_4;
    let _e42 = amp_3;
    h_4 = (_e41 * _e42);
    let _e44 = h_4;
    let _e45 = amp_3;
    h_4 = (_e44 - _e45);
    let _e47 = fbm_1;
    let _e49 = freq;
    let _e51 = amp_3;
    grad_3 = ((_e47.yz * _e49) * _e51);
    let _e54 = h_4;
    let _e55 = grad_3;
    return vec4<f32>(_e54, _e55.x, _e55.y, 2f);
}

fn heightmap_mountain(p_40: vec2<f32>, t: f32, t_max: f32) -> vec4<f32> {
    var p_41: vec2<f32>;
    var t_1: f32;
    var t_max_1: f32;
    var oct_max: i32 = 6i;
    var oct_min: i32 = 2i;
    var octaves_6: i32;

    p_41 = p_40;
    t_1 = t;
    t_max_1 = t_max;
    let _e27 = oct_min;
    let _e28 = oct_max;
    let _e29 = oct_min;
    let _e32 = t_max_1;
    let _e35 = t_max_1;
    let _e36 = t_1;
    octaves_6 = i32(round((f32(_e27) + (f32((_e28 - _e29)) * (1f - smoothstep((_e32 / 2f), _e35, _e36))))));
    let _e46 = p_41;
    let _e47 = octaves_6;
    let _e48 = heightmap_mountain_octaves(_e46, _e47);
    return _e48;
}

fn map(p_42: vec3<f32>) -> vec2<f32> {
    var p_43: vec3<f32>;

    p_43 = p_42;
    let _e19 = world_ray;
    if (_e19 == 0i) {
        let _e22 = p_43;
        let _e23 = map_hub(_e22);
        return _e23;
    } else {
        let _e24 = world_ray;
        if (_e24 == 1i) {
            let _e27 = p_43;
            let _e28 = map_fractal(_e27);
            return _e28;
        } else {
            let _e29 = world_ray;
            if (_e29 == 2i) {
                let _e32 = p_43;
                let _e33 = map_lavalamp(_e32);
                return _e33;
            } else {
                let _e34 = world_ray;
                if (_e34 == 5i) {
                    let _e37 = p_43;
                    let _e38 = map_cloud(_e37);
                    return _e38;
                } else {
                    let _e39 = world_ray;
                    if (_e39 == 3i) {
                        let _e42 = p_43;
                        let _e44 = p_43;
                        let _e48 = heightmap_mountain(_e44.xz, 0f, 0f);
                        return vec2<f32>((_e42.y - _e48.x), 2f);
                    } else {
                        let _e53 = world_ray;
                        if (_e53 == 4i) {
                            let _e56 = p_43;
                            let _e58 = p_43;
                            let _e60 = heightmap_water(_e58.xz);
                            return vec2<f32>((_e56.y - _e60.x), 3f);
                        } else {
                            return vec2<f32>(100000000f, 0f);
                        }
                    }
                }
            }
        }
    }
}

fn map_portals(p_44: vec3<f32>) -> vec2<f32> {
    var p_45: vec3<f32>;
    var res_3: vec2<f32> = vec2<f32>(100000000f, 0f);
    var i_6: i32 = 0i;
    var local_2: array<i32, 5> = SUB_WORLDS;
    var world_dst: i32;
    var portal_2: mat2x3<f32>;
    var d_5: f32;
    var portal_3: mat2x3<f32>;
    var d_6: f32;

    p_45 = p_44;
    let _e23 = world_ray;
    if (_e23 == 0i) {
        {
            loop {
                let _e28 = i_6;
                if !((_e28 < 5i)) {
                    break;
                }
                {
                    let _e35 = i_6;
                    let _e39 = local_2[_e35];
                    world_dst = _e39;
                    let _e41 = world_dst;
                    let _e42 = get_portal(_e41);
                    portal_2 = _e42;
                    let _e44 = p_45;
                    let _e47 = portal_2[0];
                    let _e51 = portal_2[1];
                    let _e52 = sd_portal((_e44 - _e47), _e51);
                    d_5 = _e52;
                    let _e54 = res_3;
                    let _e55 = d_5;
                    let _e57 = world_dst;
                    let _e61 = u_op(_e54, vec2<f32>(_e55, (100f + f32(_e57))));
                    res_3 = _e61;
                }
                continuing {
                    let _e32 = i_6;
                    i_6 = (_e32 + 1i);
                }
            }
        }
    } else {
        {
            let _e62 = world_ray;
            let _e63 = get_portal(_e62);
            portal_3 = _e63;
            let _e65 = p_45;
            let _e68 = portal_3[0];
            let _e74 = portal_3[1];
            let _e76 = sd_portal((_e65 - _e68), (-1f * _e74));
            d_6 = _e76;
            let _e78 = res_3;
            let _e79 = d_6;
            let _e85 = u_op(_e78, vec2<f32>(_e79, 100f));
            res_3 = _e85;
        }
    }
    let _e86 = res_3;
    return _e86;
}

fn heightmap(p_46: vec2<f32>, t_2: f32, t_max_2: f32) -> vec4<f32> {
    var p_47: vec2<f32>;
    var t_3: f32;
    var t_max_3: f32;

    p_47 = p_46;
    t_3 = t_2;
    t_max_3 = t_max_2;
    let _e23 = world_ray;
    if (_e23 == 3i) {
        let _e26 = p_47;
        let _e27 = t_3;
        let _e28 = t_max_3;
        let _e29 = heightmap_mountain(_e26, _e27, _e28);
        return _e29;
    }
    let _e30 = world_ray;
    if (_e30 == 4i) {
        let _e33 = p_47;
        let _e34 = heightmap_water(_e33);
        return _e34;
    }
    return vec4(0f);
}

fn raymarch_sdf(ro: vec3<f32>, rd: vec3<f32>, t_global: f32) -> vec3<f32> {
    var ro_1: vec3<f32>;
    var rd_1: vec3<f32>;
    var t_global_1: f32;
    var t_tot: f32 = 0.001f;
    var t_candidate: f32 = 0.001f;
    var err_candidate: f32 = 100000000f;
    var id_candidate: f32 = 0f;
    var t_4: f32 = 0.001f;
    var omega: f32 = 1.2f;
    var r_prev: f32 = 0f;
    var t_max_4: f32 = 400f;
    var pixel_radius: f32;
    var steps: f32 = 0f;
    var i_7: i32 = 0i;
    var p_48: vec3<f32>;
    var hit: vec2<f32>;
    var r_4: f32;
    var id_2: f32;
    var overstep: bool;
    var err: f32;

    ro_1 = ro;
    rd_1 = rd;
    t_global_1 = t_global;
    let _e40 = u_2;
    pixel_radius = (1f / _e40.resolution.y);
    loop {
        let _e49 = i_7;
        if !((_e49 < 256i)) {
            break;
        }
        {
            let _e56 = steps;
            steps = (_e56 + 1f);
            let _e59 = ro_1;
            let _e60 = t_tot;
            let _e61 = rd_1;
            p_48 = (_e59 + (_e60 * _e61));
            let _e65 = p_48;
            let _e66 = map(_e65);
            hit = _e66;
            let _e68 = hit;
            let _e69 = p_48;
            let _e70 = map_portals(_e69);
            let _e71 = u_op(_e68, _e70);
            hit = _e71;
            let _e72 = hit;
            r_4 = _e72.x;
            let _e75 = hit;
            id_2 = _e75.y;
            let _e78 = omega;
            let _e81 = r_4;
            let _e82 = r_prev;
            let _e84 = t_4;
            overstep = ((_e78 > 1f) && ((_e81 + _e82) < _e84));
            let _e88 = overstep;
            if _e88 {
                {
                    let _e89 = t_4;
                    let _e90 = r_prev;
                    t_4 = -((_e89 - _e90));
                    omega = 1f;
                }
            } else {
                {
                    let _e94 = omega;
                    let _e95 = r_4;
                    t_4 = (_e94 * _e95);
                }
            }
            let _e97 = r_4;
            r_prev = _e97;
            let _e98 = r_4;
            let _e99 = t_global_1;
            let _e100 = t_tot;
            err = abs((_e98 / (_e99 + _e100)));
            let _e105 = overstep;
            let _e107 = err;
            let _e108 = err_candidate;
            if (!(_e105) && (_e107 < _e108)) {
                {
                    let _e111 = err;
                    err_candidate = _e111;
                    let _e112 = t_tot;
                    t_candidate = _e112;
                    let _e113 = id_2;
                    id_candidate = _e113;
                }
            }
            let _e114 = overstep;
            let _e116 = err;
            let _e117 = pixel_radius;
            if (!(_e114) && (_e116 < _e117)) {
                {
                    break;
                }
            }
            let _e120 = t_tot;
            let _e121 = t_4;
            t_tot = (_e120 + _e121);
            let _e123 = t_tot;
            let _e124 = t_max_4;
            if (_e123 > _e124) {
                {
                    t_candidate = -1f;
                    break;
                }
            }
        }
        continuing {
            let _e53 = i_7;
            i_7 = (_e53 + 1i);
        }
    }
    let _e128 = err_candidate;
    let _e129 = pixel_radius;
    if (_e128 > (_e129 * 1.5f)) {
        t_candidate = -1f;
    }
    let _e135 = t_candidate;
    let _e136 = id_candidate;
    let _e137 = steps;
    return vec3<f32>(_e135, _e136, _e137);
}

fn raymarch_terrain(ro_2: vec3<f32>, rd_2: vec3<f32>) -> vec3<f32> {
    var ro_3: vec3<f32>;
    var rd_3: vec3<f32>;
    var t_5: f32 = 0.01f;
    var t_candidate_1: f32 = 0.01f;
    var id_candidate_1: f32 = 0.01f;
    var err_candidate_1: f32 = 100000000f;
    var t_max_5: f32 = 1600f;
    var pixel_radius_1: f32;
    var h_max: f32;
    var rd_is_up: bool;
    var portal_4: mat2x3<f32>;
    var h_portal: f32;
    var steps_1: f32 = 0f;
    var i_8: i32 = 0i;
    var p_49: vec3<f32>;
    var hm: vec4<f32>;
    var h_5: f32;
    var grad_4: vec2<f32>;
    var id_3: f32;
    var dh: f32;
    var dt: f32;
    var err_1: f32;
    var d_portal: f32;

    ro_3 = ro_2;
    rd_3 = rd_2;
    let _e32 = u_2;
    pixel_radius_1 = (1f / _e32.resolution.y);
    let _e37 = world_ray;
    let _e38 = get_heightmap_amplitude(_e37);
    h_max = _e38;
    let _e40 = rd_3;
    rd_is_up = (_e40.y > 0f);
    let _e45 = world_ray;
    let _e46 = get_portal(_e45);
    portal_4 = _e46;
    let _e50 = portal_4[0];
    h_portal = (_e50.y + 7.4f);
    let _e55 = h_max;
    let _e56 = h_portal;
    h_max = max(_e55, _e56);
    let _e58 = ro_3;
    let _e60 = h_max;
    let _e62 = rd_is_up;
    if ((_e58.y > _e60) && _e62) {
        return vec3(-1f);
    }
    let _e67 = ro_3;
    let _e69 = h_max;
    if (_e67.y > _e69) {
        {
            let _e71 = t_5;
            let _e72 = h_max;
            let _e73 = ro_3;
            let _e76 = rd_3;
            t_5 = max(_e71, ((_e72 - _e73.y) / _e76.y));
        }
    }
    loop {
        let _e84 = i_8;
        if !((_e84 < 256i)) {
            break;
        }
        {
            let _e91 = steps_1;
            steps_1 = (_e91 + 1f);
            let _e94 = ro_3;
            let _e95 = t_5;
            let _e96 = rd_3;
            p_49 = (_e94 + (_e95 * _e96));
            let _e100 = p_49;
            let _e102 = t_5;
            let _e103 = t_max_5;
            let _e104 = heightmap(_e100.xz, _e102, _e103);
            hm = _e104;
            let _e106 = hm;
            h_5 = _e106.x;
            let _e109 = hm;
            grad_4 = _e109.yz;
            let _e112 = hm;
            id_3 = _e112.w;
            let _e115 = p_49;
            let _e117 = h_5;
            dh = (_e115.y - _e117);
            let _e121 = dh;
            let _e124 = grad_4;
            let _e125 = grad_4;
            dt = ((0.65f * _e121) / sqrt((1f + dot(_e124, _e125))));
            let _e131 = dh;
            let _e132 = t_5;
            err_1 = abs((_e131 / _e132));
            let _e136 = err_1;
            let _e137 = err_candidate_1;
            if (_e136 < _e137) {
                {
                    let _e139 = err_1;
                    err_candidate_1 = _e139;
                    let _e140 = t_5;
                    t_candidate_1 = _e140;
                    let _e141 = id_3;
                    id_candidate_1 = _e141;
                }
            }
            let _e142 = err_1;
            let _e143 = pixel_radius_1;
            if (_e142 < _e143) {
                {
                    break;
                }
            }
            let _e145 = p_49;
            let _e148 = portal_4[0];
            let _e154 = portal_4[1];
            let _e156 = sd_portal((_e145 - _e148), (-1f * _e154));
            d_portal = _e156;
            let _e158 = d_portal;
            if (_e158 < 0.001f) {
                {
                    let _e161 = t_5;
                    let _e166 = steps_1;
                    return vec3<f32>(_e161, 100f, _e166);
                }
            }
            let _e168 = dt;
            let _e169 = d_portal;
            dt = min(_e168, _e169);
            let _e171 = t_5;
            let _e172 = dt;
            t_5 = (_e171 + _e172);
            let _e174 = t_5;
            let _e175 = t_max_5;
            if (_e174 > _e175) {
                {
                    t_candidate_1 = -1f;
                    break;
                }
            }
        }
        continuing {
            let _e88 = i_8;
            i_8 = (_e88 + 1i);
        }
    }
    let _e180 = t_candidate_1;
    let _e181 = id_candidate_1;
    let _e182 = steps_1;
    return vec3<f32>(_e180, _e181, _e182);
}

fn raymarch(ro_4: vec3<f32>, rd_4: vec3<f32>) -> vec3<f32> {
    var ro_5: vec3<f32>;
    var rd_5: vec3<f32>;
    var t_res: f32 = 0f;
    var steps_2: f32 = 0f;
    var ro_current: vec3<f32>;
    var hit_1: vec3<f32>;
    var t_6: f32;
    var id_4: f32;
    var n_7: vec3<f32>;
    var a_9: f32;

    ro_5 = ro_4;
    rd_5 = rd_4;
    loop {
        let _e25 = t_res;
        if !((_e25 < 150f)) {
            break;
        }
        {
            let _e30 = ro_5;
            let _e31 = rd_5;
            let _e32 = t_res;
            ro_current = (_e30 + (_e31 * _e32));
            let _e37 = use_heightmap();
            if _e37 {
                let _e38 = ro_current;
                let _e39 = rd_5;
                let _e40 = raymarch_terrain(_e38, _e39);
                hit_1 = _e40;
            } else {
                let _e41 = ro_current;
                let _e42 = rd_5;
                let _e43 = t_res;
                let _e44 = raymarch_sdf(_e41, _e42, _e43);
                hit_1 = _e44;
            }
            let _e45 = hit_1;
            t_6 = _e45.x;
            let _e48 = hit_1;
            id_4 = _e48.y;
            let _e51 = hit_1;
            steps_2 = _e51.z;
            let _e53 = t_6;
            if (_e53 > 0f) {
                {
                    let _e56 = t_res;
                    let _e57 = t_6;
                    t_res = (_e56 + _e57);
                    let _e59 = id_4;
                    if (_e59 >= 100f) {
                        {
                            let _e62 = id_4;
                            world_ray = i32((_e62 - 100f));
                            let _e67 = world_ray;
                            let _e68 = get_portal(_e67);
                            n_7 = _e68[1];
                            let _e71 = n_7;
                            let _e72 = rd_5;
                            a_9 = max(abs(dot(_e71, _e72)), 0.000001f);
                            let _e78 = t_res;
                            let _e80 = a_9;
                            t_res = (_e78 + (0.5f / _e80));
                            continue;
                        }
                    }
                    let _e83 = t_res;
                    let _e84 = id_4;
                    let _e85 = steps_2;
                    return vec3<f32>(_e83, _e84, _e85);
                }
            } else {
                break;
            }
        }
    }
    return vec3(-1f);
}

fn normal_numerical(p_50: vec3<f32>, t_7: f32) -> vec3<f32> {
    var p_51: vec3<f32>;
    var t_8: f32;
    var e: vec2<f32>;
    var n_8: vec3<f32>;
    var o: i32 = 11i;

    p_51 = p_50;
    t_8 = t_7;
    let _e27 = t_8;
    e = (vec2<f32>(1f, -1f) * max(0.001f, (0.001f * _e27)));
    let _e33 = world_ray;
    if (_e33 == 3i) {
        {
            let _e38 = e;
            let _e40 = p_51;
            let _e42 = e;
            let _e45 = p_51;
            let _e47 = e;
            let _e50 = o;
            let _e51 = heightmap_mountain_octaves((_e45.xz + _e47.xy), _e50);
            let _e55 = e;
            let _e57 = p_51;
            let _e59 = e;
            let _e62 = p_51;
            let _e64 = e;
            let _e67 = o;
            let _e68 = heightmap_mountain_octaves((_e62.xz + _e64.yx), _e67);
            let _e73 = e;
            let _e75 = p_51;
            let _e77 = e;
            let _e80 = p_51;
            let _e82 = e;
            let _e85 = o;
            let _e86 = heightmap_mountain_octaves((_e80.xz + _e82.yy), _e85);
            let _e91 = e;
            let _e93 = p_51;
            let _e95 = e;
            let _e98 = p_51;
            let _e100 = e;
            let _e103 = o;
            let _e104 = heightmap_mountain_octaves((_e98.xz + _e100.xx), _e103);
            n_8 = normalize(((((_e38.xyy * ((_e40.y + _e42.y) - _e51.x)) + (_e55.yyx * ((_e57.y + _e59.y) - _e68.x))) + (_e73.yxy * ((_e75.y + _e77.x) - _e86.x))) + (_e91.xxx * ((_e93.y + _e95.x) - _e104.x))));
        }
    } else {
        {
            let _e110 = e;
            let _e112 = p_51;
            let _e113 = e;
            let _e116 = map((_e112 + _e113.xyy));
            let _e119 = e;
            let _e121 = p_51;
            let _e122 = e;
            let _e125 = map((_e121 + _e122.yyx));
            let _e129 = e;
            let _e131 = p_51;
            let _e132 = e;
            let _e135 = map((_e131 + _e132.yxy));
            let _e139 = e;
            let _e141 = p_51;
            let _e142 = e;
            let _e145 = map((_e141 + _e142.xxx));
            n_8 = normalize(((((_e110.xyy * _e116.x) + (_e119.yyx * _e125.x)) + (_e129.yxy * _e135.x)) + (_e139.xxx * _e145.x)));
        }
    }
    let _e150 = n_8;
    return _e150;
}

fn normal_analytical(p_52: vec2<f32>) -> vec3<f32> {
    var p_53: vec2<f32>;
    var grad_5: vec2<f32>;
    var n_9: vec3<f32>;

    p_53 = p_52;
    let _e19 = p_53;
    let _e21 = heightmap_mountain_octaves(_e19, 11i);
    grad_5 = _e21.yz;
    let _e24 = grad_5;
    let _e28 = grad_5;
    n_9 = normalize(vec3<f32>(-(_e24.x), 1f, -(_e28.y)));
    let _e34 = n_9;
    return _e34;
}

fn normal(p_54: vec3<f32>, t_9: f32) -> vec3<f32> {
    var p_55: vec3<f32>;
    var t_10: f32;
    var n_10: vec3<f32>;

    p_55 = p_54;
    t_10 = t_9;
    if false {
    } else {
        let _e23 = p_55;
        let _e24 = t_10;
        let _e25 = normal_numerical(_e23, _e24);
        n_10 = _e25;
    }
    let _e26 = n_10;
    return _e26;
}

fn shadow(ro_6: vec3<f32>, rd_6: vec3<f32>, d_max: f32) -> f32 {
    var ro_7: vec3<f32>;
    var rd_7: vec3<f32>;
    var d_max_1: f32;
    var d_7: f32 = 0.1f;
    var occlusion: f32 = 1f;
    var i_9: i32 = 0i;
    var p_56: vec3<f32>;
    var h_6: f32;

    ro_7 = ro_6;
    rd_7 = rd_6;
    d_max_1 = d_max;
    loop {
        let _e29 = i_9;
        let _e32 = d_7;
        let _e33 = d_max_1;
        if !(((_e29 < 256i) && (_e32 < _e33))) {
            break;
        }
        {
            let _e40 = ro_7;
            let _e41 = rd_7;
            let _e42 = d_7;
            p_56 = (_e40 + (_e41 * _e42));
            let _e46 = p_56;
            let _e47 = map(_e46);
            h_6 = _e47.x;
            let _e50 = h_6;
            if (_e50 < 0.001f) {
                return 0f;
            }
            let _e54 = occlusion;
            let _e56 = h_6;
            let _e58 = d_7;
            occlusion = min(_e54, ((32f * _e56) / _e58));
            let _e61 = d_7;
            let _e62 = h_6;
            d_7 = (_e61 + _e62);
        }
        continuing {
            let _e37 = i_9;
            i_9 = (_e37 + 1i);
        }
    }
    let _e64 = occlusion;
    return _e64;
}

fn shadow_terrain(ro_8: vec3<f32>, rd_8: vec3<f32>, d_max_2: f32) -> f32 {
    var ro_9: vec3<f32>;
    var rd_9: vec3<f32>;
    var d_max_3: f32;

    ro_9 = ro_8;
    rd_9 = rd_8;
    d_max_3 = d_max_2;
    return 0f;
}

fn ambient_occlusion_sdf(p_57: vec3<f32>, n_11: vec3<f32>) -> f32 {
    var p_58: vec3<f32>;
    var n_12: vec3<f32>;
    var scale_1: f32 = 1f;
    var occlusion_1: f32 = 0f;
    var i_10: i32 = 1i;
    var h_7: f32;
    var d_8: f32;

    p_58 = p_57;
    n_12 = n_11;
    loop {
        let _e27 = i_10;
        if !((_e27 <= 4i)) {
            break;
        }
        {
            let _e35 = i_10;
            h_7 = (0.04f * f32(_e35));
            let _e39 = p_58;
            let _e40 = h_7;
            let _e41 = n_12;
            let _e44 = map((_e39 + (_e40 * _e41)));
            d_8 = _e44.x;
            let _e47 = occlusion_1;
            let _e48 = h_7;
            let _e49 = d_8;
            let _e51 = scale_1;
            occlusion_1 = (_e47 + ((_e48 - _e49) * _e51));
            let _e54 = scale_1;
            scale_1 = (_e54 * 0.95f);
        }
        continuing {
            let _e31 = i_10;
            i_10 = (_e31 + 1i);
        }
    }
    let _e58 = occlusion_1;
    return (1f - clamp(_e58, 0f, 1f));
}

fn ambient_occlusion_terrain(p_59: vec3<f32>) -> f32 {
    var p_60: vec3<f32>;
    var offsets: array<vec2<f32>, 4> = array<vec2<f32>, 4>(vec2<f32>(1f, 0f), vec2<f32>(0f, 1f), vec2<f32>(-1f, 0f), vec2<f32>(0f, -1f));
    var occlusion_2: f32 = 1f;
    var i_11: i32 = 0i;
    var q_3: vec2<f32>;
    var h_8: f32;
    var dh_1: f32;

    p_60 = p_59;
    loop {
        let _e39 = i_11;
        if !((_e39 < 4i)) {
            break;
        }
        {
            let _e46 = p_60;
            let _e49 = i_11;
            let _e51 = offsets[_e49];
            q_3 = (_e46.xz + (0.1f * _e51));
            let _e55 = p_60;
            let _e59 = heightmap(_e55.xz, 0f, 0f);
            h_8 = _e59.x;
            let _e62 = p_60;
            let _e64 = h_8;
            dh_1 = (_e62.y - _e64);
            let _e67 = occlusion_2;
            let _e69 = dh_1;
            occlusion_2 = (_e67 - (0.5f * max(-(_e69), 0f)));
        }
        continuing {
            let _e43 = i_11;
            i_11 = (_e43 + 1i);
        }
    }
    let _e75 = occlusion_2;
    return _e75;
}

fn ambient_occlusion(p_61: vec3<f32>, n_13: vec3<f32>) -> f32 {
    var p_62: vec3<f32>;
    var n_14: vec3<f32>;
    var ao: f32;

    p_62 = p_61;
    n_14 = n_13;
    let _e22 = p_62;
    let _e23 = n_14;
    let _e24 = ambient_occlusion_sdf(_e22, _e23);
    ao = _e24;
    let _e25 = ao;
    return _e25;
}

fn distribution(n_15: vec3<f32>, h_9: vec3<f32>, roughness: f32) -> f32 {
    var n_16: vec3<f32>;
    var h_10: vec3<f32>;
    var roughness_1: f32;
    var a_10: f32;
    var a2_: f32;
    var nh: f32;
    var nh2_: f32;
    var num: f32;
    var denom: f32;

    n_16 = n_15;
    h_10 = h_9;
    roughness_1 = roughness;
    let _e23 = roughness_1;
    let _e24 = roughness_1;
    a_10 = (_e23 * _e24);
    let _e27 = a_10;
    let _e28 = a_10;
    a2_ = (_e27 * _e28);
    let _e31 = n_16;
    let _e32 = h_10;
    nh = max(dot(_e31, _e32), 0f);
    let _e37 = nh;
    let _e38 = nh;
    nh2_ = (_e37 * _e38);
    let _e41 = a2_;
    num = _e41;
    let _e43 = nh2_;
    let _e44 = a2_;
    denom = ((_e43 * (_e44 - 1f)) + 1f);
    let _e52 = denom;
    let _e54 = denom;
    denom = ((3.1415927f * _e52) * _e54);
    let _e56 = num;
    let _e57 = denom;
    return (_e56 / _e57);
}

fn fresnel(v: vec3<f32>, h_11: vec3<f32>, f0_: vec3<f32>) -> vec3<f32> {
    var v_1: vec3<f32>;
    var h_12: vec3<f32>;
    var f0_1: vec3<f32>;
    var cos_theta: f32;

    v_1 = v;
    h_12 = h_11;
    f0_1 = f0_;
    let _e23 = v_1;
    let _e24 = h_12;
    cos_theta = max(dot(_e23, _e24), 0f);
    let _e29 = f0_1;
    let _e31 = f0_1;
    let _e35 = cos_theta;
    return (_e29 + ((vec3(1f) - _e31) * pow(clamp((1f - _e35), 0f, 1f), 5f)));
}

fn g1_(n_17: vec3<f32>, dir: vec3<f32>, roughness_2: f32) -> f32 {
    var n_18: vec3<f32>;
    var dir_1: vec3<f32>;
    var roughness_3: f32;
    var r_5: f32;
    var k_6: f32;
    var cos_theta_1: f32;
    var num_1: f32;
    var denom_1: f32;

    n_18 = n_17;
    dir_1 = dir;
    roughness_3 = roughness_2;
    let _e23 = roughness_3;
    r_5 = (_e23 + 1f);
    let _e27 = r_5;
    let _e28 = r_5;
    k_6 = ((_e27 * _e28) / 8f);
    let _e33 = n_18;
    let _e34 = dir_1;
    cos_theta_1 = max(dot(_e33, _e34), 0f);
    let _e39 = cos_theta_1;
    num_1 = _e39;
    let _e41 = cos_theta_1;
    let _e43 = k_6;
    let _e46 = k_6;
    denom_1 = ((_e41 * (1f - _e43)) + _e46);
    let _e49 = num_1;
    let _e50 = denom_1;
    return (_e49 / _e50);
}

fn geometry(n_19: vec3<f32>, v_2: vec3<f32>, l: vec3<f32>, roughness_4: f32) -> f32 {
    var n_20: vec3<f32>;
    var v_3: vec3<f32>;
    var l_1: vec3<f32>;
    var roughness_5: f32;
    var masking: f32;
    var shadowing: f32;

    n_20 = n_19;
    v_3 = v_2;
    l_1 = l;
    roughness_5 = roughness_4;
    let _e25 = n_20;
    let _e26 = v_3;
    let _e27 = roughness_5;
    let _e28 = g1_(_e25, _e26, _e27);
    masking = _e28;
    let _e30 = n_20;
    let _e31 = l_1;
    let _e32 = roughness_5;
    let _e33 = g1_(_e30, _e31, _e32);
    shadowing = _e33;
    let _e35 = masking;
    let _e36 = shadowing;
    return (_e35 * _e36);
}

fn light_direct(p_63: vec3<f32>, n_21: vec3<f32>, v_4: vec3<f32>, light: Light, material: Material) -> vec3<f32> {
    var p_64: vec3<f32>;
    var n_22: vec3<f32>;
    var v_5: vec3<f32>;
    var light_1: Light;
    var material_1: Material;
    var l_2: vec3<f32>;
    var h_13: vec3<f32>;
    var f0_2: vec3<f32> = vec3(0.04f);
    var distance_: f32;
    var attenuation: f32;
    var radiance: vec3<f32>;
    var D: f32;
    var G: f32;
    var F: vec3<f32>;
    var num_2: vec3<f32>;
    var denom_2: f32;
    var specular: vec3<f32>;
    var k_s: vec3<f32>;
    var k_d: vec3<f32>;
    var brdf: vec3<f32>;

    p_64 = p_63;
    n_22 = n_21;
    v_5 = v_4;
    light_1 = light;
    material_1 = material;
    let _e27 = light_1;
    let _e29 = p_64;
    l_2 = normalize((_e27.pos - _e29));
    let _e33 = v_5;
    let _e34 = l_2;
    h_13 = normalize((_e33 + _e34));
    let _e41 = f0_2;
    let _e42 = material_1;
    let _e44 = material_1;
    f0_2 = mix(_e41, _e42.albedo, vec3(_e44.metallic));
    let _e48 = light_1;
    let _e50 = p_64;
    distance_ = length((_e48.pos - _e50));
    let _e55 = distance_;
    let _e56 = distance_;
    attenuation = (1f / (_e55 * _e56));
    let _e60 = light_1;
    let _e62 = light_1;
    let _e65 = attenuation;
    radiance = ((_e60.color * _e62.strength) * _e65);
    let _e68 = n_22;
    let _e69 = h_13;
    let _e70 = material_1;
    let _e72 = distribution(_e68, _e69, _e70.roughness);
    D = _e72;
    let _e74 = n_22;
    let _e75 = v_5;
    let _e76 = l_2;
    let _e77 = material_1;
    let _e79 = geometry(_e74, _e75, _e76, _e77.roughness);
    G = _e79;
    let _e81 = v_5;
    let _e82 = h_13;
    let _e83 = f0_2;
    let _e84 = fresnel(_e81, _e82, _e83);
    F = _e84;
    let _e86 = D;
    let _e87 = G;
    let _e89 = F;
    num_2 = ((_e86 * _e87) * _e89);
    let _e93 = n_22;
    let _e94 = v_5;
    let _e99 = n_22;
    let _e100 = l_2;
    denom_2 = (((4f * max(dot(_e93, _e94), 0f)) * max(dot(_e99, _e100), 0f)) + 0.0001f);
    let _e108 = num_2;
    let _e109 = denom_2;
    specular = (_e108 / vec3(_e109));
    let _e113 = F;
    k_s = _e113;
    let _e117 = k_s;
    k_d = (vec3(1f) - _e117);
    let _e120 = k_d;
    let _e122 = material_1;
    k_d = (_e120 * (1f - _e122.metallic));
    let _e126 = k_d;
    let _e127 = material_1;
    let _e133 = specular;
    brdf = (((_e126 * _e127.albedo) / vec3(3.1415927f)) + _e133);
    let _e136 = brdf;
    let _e137 = radiance;
    let _e139 = n_22;
    let _e140 = l_2;
    return ((_e136 * _e137) * max(dot(_e139, _e140), 0f));
}

fn lighting(p_65: vec3<f32>, n_23: vec3<f32>, v_6: vec3<f32>, material_2: Material, t_11: f32) -> vec3<f32> {
    var p_66: vec3<f32>;
    var n_24: vec3<f32>;
    var v_7: vec3<f32>;
    var material_3: Material;
    var t_12: f32;
    var color: vec3<f32> = vec3(0f);
    var dir_sun: vec3<f32> = vec3<f32>(-0.84799826f, 0.42399913f, -0.31799936f);
    var col_sun: vec3<f32> = vec3<f32>(1.64f, 1.27f, 0.99f);
    var col_sky: vec3<f32> = vec3<f32>(0.16f, 0.2f, 0.28f);
    var col_ind: vec3<f32> = vec3<f32>(0.2f, 0.09f, 0.08f);
    var diffuse_sun: f32;
    var diffuse_sky: f32;
    var diffuse_ind: f32;
    var ao_1: f32 = 1f;
    var ro_s: vec3<f32>;
    var s_3: f32;
    var light_2: vec3<f32>;
    var light_pos: vec3<f32>;
    var light_color: vec3<f32> = vec3<f32>(1f, 1f, 1f);
    var lamp: Light;
    var direct: vec3<f32>;
    var l_3: vec3<f32>;
    var s_4: f32;
    var ao_2: f32;
    var ambient: vec3<f32>;

    p_66 = p_65;
    n_24 = n_23;
    v_7 = v_6;
    material_3 = material_2;
    t_12 = t_11;
    let _e30 = use_heightmap();
    if _e30 {
        {
            let _e58 = n_24;
            let _e59 = dir_sun;
            diffuse_sun = clamp(dot(_e58, _e59), 0f, 1f);
            let _e67 = n_24;
            diffuse_sky = clamp((0.5f + (0.5f * _e67.y)), 0f, 1f);
            let _e75 = n_24;
            let _e76 = dir_sun;
            diffuse_ind = clamp(dot(_e75, normalize((_e76 * vec3<f32>(-1f, 0f, -1f)))), 0f, 1f);
            let _e92 = p_66;
            let _e94 = n_24;
            ro_s = (_e92 + (0.15f * _e94));
            let _e98 = ro_s;
            let _e99 = dir_sun;
            let _e101 = shadow(_e98, _e99, 300f);
            s_3 = _e101;
            let _e103 = col_sun;
            let _e104 = diffuse_sun;
            let _e106 = s_3;
            light_2 = ((_e103 * _e104) * _e106);
            let _e109 = light_2;
            let _e111 = col_sky;
            let _e113 = diffuse_sky;
            let _e115 = ao_1;
            light_2 = (_e109 + (((0.2f * _e111) * _e113) * _e115));
            let _e118 = light_2;
            let _e120 = col_ind;
            let _e122 = diffuse_ind;
            let _e124 = ao_1;
            light_2 = (_e118 + (((0.2f * _e120) * _e122) * _e124));
            let _e127 = material_3;
            let _e129 = light_2;
            color = (_e127.albedo * _e129);
        }
    } else {
        {
            let _e131 = u_2;
            light_pos = (_e131.camera.pos + vec3<f32>(0f, 2f, 0f));
            let _e145 = light_pos;
            let _e146 = light_color;
            lamp = Light(_e145, _e146, 500f);
            let _e150 = p_66;
            let _e151 = n_24;
            let _e152 = v_7;
            let _e153 = lamp;
            let _e154 = material_3;
            let _e155 = light_direct(_e150, _e151, _e152, _e153, _e154);
            direct = _e155;
            let _e157 = light_pos;
            let _e158 = p_66;
            l_3 = normalize((_e157 - _e158));
            let _e162 = p_66;
            let _e163 = l_3;
            let _e164 = light_pos;
            let _e165 = p_66;
            let _e168 = shadow(_e162, _e163, length((_e164 - _e165)));
            s_4 = _e168;
            let _e170 = direct;
            let _e171 = s_4;
            direct = (_e170 * _e171);
            let _e173 = p_66;
            let _e174 = n_24;
            let _e175 = ambient_occlusion(_e173, _e174);
            ao_2 = _e175;
            let _e179 = material_3;
            let _e182 = ao_2;
            ambient = ((vec3(0.0001f) * _e179.albedo) * _e182);
            let _e185 = direct;
            let _e186 = ambient;
            color = (_e185 + _e186);
        }
    }
    let _e188 = color;
    return _e188;
}

fn get_material(id_5: f32, p_67: vec3<f32>, n_25: vec3<f32>, t_13: f32, trap: vec4<f32>) -> Material {
    var id_6: f32;
    var p_68: vec3<f32>;
    var n_26: vec3<f32>;
    var t_14: f32;
    var trap_1: vec4<f32>;
    var color_1: vec3<f32>;
    var amp_4: f32;
    var r_6: f32;
    var y_2: f32;
    var rock1_: vec3<f32> = vec3<f32>(0.1f, 0.09f, 0.08f);
    var rock2_: vec3<f32> = vec3<f32>(0.05f, 0.04f, 0.03f);
    var color_2: vec3<f32>;
    var dirt: vec3<f32> = vec3<f32>(0.045f, 0.03f, 0.02f);
    var grass: vec3<f32> = vec3<f32>(0.05f, 0.05f, 0.01f);
    var h_14: f32;
    var s_5: f32;
    var snow: vec3<f32> = vec3(0.95f);

    id_6 = id_5;
    p_68 = p_67;
    n_26 = n_25;
    t_14 = t_13;
    trap_1 = trap;
    let _e27 = id_6;
    if (_e27 == 1f) {
        {
            let _e30 = trap_1;
            let _e44 = palette((_e30.z * 4f), vec3(0.5f), vec3(0.5f), vec3(1f), vec3<f32>(0f, 0.1f, 0.2f));
            color_1 = _e44;
            let _e46 = color_1;
            return Material(_e46, 0.8f, 0.2f);
        }
    } else {
        let _e50 = id_6;
        if (_e50 == 1.1f) {
            {
                return Material(vec3<f32>(0.6f, 0.5f, 0.4f), 0.8f, 0.2f);
            }
        } else {
            let _e60 = id_6;
            if (_e60 == 2f) {
                {
                    let _e64 = get_heightmap_amplitude(3i);
                    amp_4 = _e64;
                    let _e66 = p_68;
                    let _e70 = noised_value((_e66.xz * 0.01f));
                    r_6 = _e70.x;
                    let _e73 = p_68;
                    let _e75 = amp_4;
                    y_2 = (_e73.y + _e75);
                    let _e89 = r_6;
                    let _e95 = rock1_;
                    let _e96 = rock2_;
                    let _e98 = p_68;
                    let _e100 = p_68;
                    let _e106 = noised_value((0.1f * vec2<f32>(_e98.x, (_e100.y * 3f))));
                    color_2 = ((0.9f * ((_e89 * 0.25f) + 0.75f)) * mix(_e95, _e96, vec3(_e106.x)));
                    let _e117 = color_2;
                    let _e118 = dirt;
                    let _e119 = r_6;
                    let _e127 = n_26;
                    color_2 = mix(_e117, (_e118 * ((_e119 * 0.5f) + 0.5f)), vec3(smoothstep(0.75f, 0.9f, _e127.y)));
                    let _e137 = color_2;
                    let _e138 = grass;
                    let _e139 = r_6;
                    let _e147 = n_26;
                    color_2 = mix(_e137, (_e138 * ((_e139 * 0.75f) + 0.25f)), vec3(smoothstep(0.95f, 1f, _e147.y)));
                    let _e153 = amp_4;
                    let _e156 = amp_4;
                    let _e158 = y_2;
                    let _e160 = amp_4;
                    let _e162 = p_68;
                    let _e165 = fbm(_e162.xz, 3i);
                    h_14 = smoothstep((0.85f * _e153), (1f * _e156), (_e158 + ((0.13f * _e160) * _e165)));
                    let _e172 = h_14;
                    let _e177 = h_14;
                    let _e182 = n_26;
                    s_5 = smoothstep((1f - (0.5f * _e172)), (1f - (0.1f * _e177)), (0.25f + (0.75f * _e182.y)));
                    let _e191 = color_2;
                    let _e192 = snow;
                    let _e193 = s_5;
                    color_2 = mix(_e191, _e192, vec3(_e193));
                    let _e196 = color_2;
                    return Material(_e196, 0f, 0.2f);
                }
            } else {
                let _e200 = id_6;
                if (_e200 == 3f) {
                    return Material(vec3<f32>(0f, 0f, 1f), 0.5f, 0.5f);
                } else {
                    let _e210 = id_6;
                    if (_e210 == 4f) {
                        return Material(vec3<f32>(0.8f, 0.8f, 0.8f), 0.5f, 0.5f);
                    } else {
                        let _e220 = id_6;
                        if (_e220 == 5f) {
                            return Material(vec3<f32>(1f, 0f, 1f), 0.5f, 0.5f);
                        }
                    }
                }
            }
        }
    }
    return Material(vec3<f32>(1f, 0f, 1f), 0f, 0f);
}

fn main_1() {
    var x_4: u32;
    var y_3: u32;
    var uv: vec2<f32>;
    var ro_10: vec3<f32>;
    var camera_orientation: mat3x3<f32>;
    var rd_10: vec3<f32>;
    var world_9: i32;
    var hit_2: vec3<f32>;
    var t_15: f32;
    var material_id: f32;
    var steps_3: f32;
    var color_3: vec3<f32> = vec3(0f);
    var p_69: vec3<f32>;
    var hit_trap: vec4<f32>;
    var n_27: vec3<f32>;
    var v_8: vec3<f32>;
    var material_4: Material;
    var light_3: vec3<f32>;

    let _e18 = gl_GlobalInvocationID_1;
    x_4 = _e18.x;
    let _e21 = gl_GlobalInvocationID_1;
    y_3 = _e21.y;
    let _e24 = x_4;
    let _e25 = u_2;
    let _e30 = y_3;
    let _e31 = u_2;
    if ((f32(_e24) >= _e25.resolution.x) || (f32(_e30) >= _e31.resolution.y)) {
        return;
    }
    let _e37 = x_4;
    let _e39 = u_2;
    let _e43 = y_3;
    let _e45 = u_2;
    uv = vec2<f32>((f32(_e37) / _e39.resolution.x), (f32(_e43) / _e45.resolution.y));
    let _e51 = uv;
    uv = ((_e51 * 2f) - vec2(1f));
    let _e58 = uv;
    uv.y = (_e58.y * -1f);
    let _e65 = uv;
    let _e67 = u_2;
    let _e70 = u_2;
    uv.x = (_e65.x * (_e67.resolution.x / _e70.resolution.y));
    let _e75 = u_2;
    ro_10 = _e75.camera.pos;
    let _e79 = u_2;
    let _e82 = u_2;
    let _e85 = u_2;
    camera_orientation = mat3x3<f32>(vec3<f32>(_e79.camera.right.x, _e79.camera.right.y, _e79.camera.right.z), vec3<f32>(_e82.camera.up.x, _e82.camera.up.y, _e82.camera.up.z), vec3<f32>(_e85.camera.forward.x, _e85.camera.forward.y, _e85.camera.forward.z));
    let _e102 = camera_orientation;
    let _e103 = uv;
    rd_10 = (_e102 * normalize(vec3<f32>(_e103.x, _e103.y, 1f)));
    let _e111 = get_world();
    world_9 = _e111;
    let _e113 = x_4;
    let _e117 = y_3;
    if ((_e113 == 0u) && (_e117 == 0u)) {
        {
            let _e122 = world_9;
            global.world_global = _e122;
            let _e123 = world_9;
            world_ray = _e123;
        }
    } else {
        let _e124 = world_9;
        world_ray = _e124;
    }
    let _e125 = ro_10;
    let _e126 = rd_10;
    let _e127 = raymarch(_e125, _e126);
    hit_2 = _e127;
    let _e129 = hit_2;
    t_15 = _e129.x;
    let _e132 = hit_2;
    material_id = _e132.y;
    let _e135 = hit_2;
    steps_3 = _e135.z;
    let _e141 = t_15;
    if (_e141 > 0f) {
        {
            let _e144 = ro_10;
            let _e145 = t_15;
            let _e146 = rd_10;
            p_69 = (_e144 + (_e145 * _e146));
            g_trap = vec4(10000000000f);
            let _e152 = world_ray;
            if (_e152 == 1i) {
                {
                    let _e155 = p_69;
                    let _e156 = map_fractal(_e155);
                }
            }
            let _e157 = g_trap;
            hit_trap = _e157;
            let _e159 = p_69;
            let _e160 = t_15;
            let _e161 = normal(_e159, _e160);
            n_27 = _e161;
            let _e163 = ro_10;
            let _e164 = p_69;
            v_8 = normalize((_e163 - _e164));
            let _e168 = material_id;
            let _e169 = p_69;
            let _e170 = n_27;
            let _e171 = t_15;
            let _e172 = hit_trap;
            let _e173 = get_material(_e168, _e169, _e170, _e171, _e172);
            material_4 = _e173;
            let _e175 = p_69;
            let _e176 = n_27;
            let _e177 = v_8;
            let _e178 = material_4;
            let _e179 = t_15;
            let _e180 = lighting(_e175, _e176, _e177, _e178, _e179);
            light_3 = _e180;
            let _e182 = light_3;
            color_3 = _e182;
        }
    } else {
        {
            let _e183 = world_ray;
            let _e184 = get_bg(_e183);
            color_3 = _e184;
        }
    }
    let _e185 = color_3;
    color_3 = pow(_e185, vec3(0.45454544f));
    let _e191 = x_4;
    let _e192 = y_3;
    let _e196 = color_3;
    textureStore(rendertarget, vec2<i32>(i32(_e191), i32(_e192)), vec4<f32>(_e196.x, _e196.y, _e196.z, 1f));
    return;
}

@compute @workgroup_size(16, 16, 1) 
fn main(@builtin(global_invocation_id) gl_GlobalInvocationID: vec3<u32>) {
    gl_GlobalInvocationID_1 = gl_GlobalInvocationID;
    main_1();
    return;
}

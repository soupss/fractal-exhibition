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
            let _e56 = p_27;
            let _e57 = noised_gradient(_e56);
            n_4 = _e57;
            let _e59 = m;
            let _e60 = n_4;
            grad_octave = (_e59 * _e60.yz);
            let _e64 = grad_2;
            let _e65 = grad_octave;
            grad_2 = (_e64 + _e65);
            let _e69 = grad_2;
            let _e70 = grad_2;
            erosion = (1f / (1f + dot(_e69, _e70)));
            let _e75 = h_1;
            let _e76 = n_4;
            let _e78 = amp_1;
            let _e80 = erosion;
            h_1 = (_e75 + ((_e76.x * _e78) * _e80));
            let _e83 = grad_eroded;
            let _e84 = grad_octave;
            let _e85 = erosion;
            grad_eroded = (_e83 + (_e84 * _e85));
            let _e88 = amp_1;
            amp_1 = (_e88 * 0.5f);
            let _e91 = rot_1;
            let _e92 = p_27;
            p_27 = ((_e91 * _e92) * 2f);
            let _e96 = rot_1;
            let _e98 = m;
            m = (transpose(_e96) * _e98);
        }
        continuing {
            let _e53 = i_3;
            i_3 = (_e53 + 1i);
        }
    }
    let _e100 = h_1;
    let _e101 = grad_eroded;
    return (vec3<f32>(_e100, _e101.x, _e101.y) / vec3(2f));
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
    let _e19 = get_portal(1i);
    portal_1 = _e19;
    let _e28 = portal_1[1];
    forward = _e28;
    let _e30 = up_2;
    let _e31 = forward;
    right_2 = normalize(cross(_e30, _e31));
    let _e35 = p_31;
    let _e36 = right_2;
    let _e38 = p_31;
    let _e39 = up_2;
    let _e41 = p_31;
    let _e42 = forward;
    q_1 = vec3<f32>(dot(_e35, _e36), dot(_e38, _e39), dot(_e41, _e42));
    let _e46 = q_1;
    let _e51 = sd_plane(_e46, vec3<f32>(0f, 1f, 0f));
    res_1 = vec2<f32>(_e51, 1f);
    let _e55 = q_1;
    let _e60 = u_2;
    q_1 = (_e55 - vec3<f32>(0f, (3.5f + (0.35f * sin((0.8f * _e60.t)))), -18f));
    let _e72 = q_1;
    let _e74 = s_1;
    id = round((_e72.xy / vec2(_e74)));
    let _e79 = id;
    let _e84 = id;
    if ((_e79.y > 0f) && (_e84.y < 10f)) {
        {
            let _e90 = q_1;
            let _e92 = q_1;
            let _e94 = s_1;
            let _e95 = id;
            let _e98 = (_e92.xy - (_e94 * round(_e95)));
            q_1.x = _e98.x;
            q_1.y = _e98.y;
            let _e103 = q_1;
            let _e105 = q_1;
            let _e108 = u_2;
            let _e111 = rotate_2d((0.1f * _e108.t));
            let _e112 = (_e105.xz * _e111);
            q_1.x = _e112.x;
            q_1.z = _e112.y;
            let _e117 = q_1;
            let _e119 = q_1;
            let _e122 = u_2;
            let _e125 = rotate_2d((0.05f * _e122.t));
            let _e126 = (_e119.yz * _e125);
            q_1.y = _e126.x;
            q_1.z = _e126.y;
            let _e131 = q_1;
            let _e133 = q_1;
            let _e136 = u_2;
            let _e140 = rotate_2d((0.05f * -(_e136.t)));
            let _e141 = (_e133.xz * _e140);
            q_1.x = _e141.x;
            q_1.z = _e141.y;
            let _e146 = q_1;
            let _e148 = sd_sphere(_e146, 10f);
            d_bound = _e148;
            let _e150 = d_bound;
            if (_e150 > 1f) {
                {
                    let _e153 = res_1;
                    let _e154 = d_bound;
                    let _e157 = u_op(_e153, vec2<f32>(_e154, 1f));
                    res_1 = _e157;
                }
            } else {
                {
                    let _e159 = u_2;
                    let _e162 = rotate_2d((0.2f * _e159.t));
                    rot_xz = _e162;
                    let _e165 = u_2;
                    let _e168 = rotate_2d((0.15f * _e165.t));
                    rot_xy = _e168;
                    loop {
                        let _e176 = i_5;
                        let _e177 = id;
                        if !((f32(_e176) < _e177.y)) {
                            break;
                        }
                        {
                            let _e185 = q_1;
                            q_1 = abs(_e185);
                            let _e187 = q_1;
                            q_1 = (_e187 - vec3<f32>(1f, 0.4f, 0.7f));
                            let _e193 = q_1;
                            let _e195 = q_1;
                            let _e197 = rot_xz;
                            let _e198 = (_e195.xz * _e197);
                            q_1.x = _e198.x;
                            q_1.z = _e198.y;
                            let _e203 = q_1;
                            let _e205 = q_1;
                            let _e207 = rot_xy;
                            let _e208 = (_e205.xy * _e207);
                            q_1.x = _e208.x;
                            q_1.y = _e208.y;
                            let _e213 = q_1;
                            let _e214 = scale;
                            q_1 = (_e213 * (_e214 * 0.8f));
                            let _e218 = scaled;
                            let _e219 = scale;
                            scaled = (_e218 * _e219);
                        }
                        continuing {
                            let _e182 = i_5;
                            i_5 = (_e182 + 1i);
                        }
                    }
                    let _e221 = q_1;
                    let _e226 = sd_box(_e221, vec3<f32>(1f, 1.2f, 1f));
                    d_3 = _e226;
                    let _e228 = d_3;
                    let _e229 = scaled;
                    d_3 = (_e228 / _e229);
                    let _e231 = res_1;
                    let _e232 = d_3;
                    let _e235 = u_op(_e231, vec2<f32>(_e232, 1f));
                    res_1 = _e235;
                }
            }
        }
    }
    let _e236 = res_1;
    return _e236;
}

fn map_lavalamp(p_32: vec3<f32>) -> vec2<f32> {
    var p_33: vec3<f32>;
    var res_2: vec2<f32> = vec2<f32>(100000000f, 5f);
    var world_height: f32 = 20f;
    var d_floor: f32;
    var p_roof: vec3<f32>;
    var d_roof: f32;
    var d_world: f32;
    var y_1: f32;
    var d_blob: f32;

    p_33 = p_32;
    let _e25 = p_33;
    p_33.y = (_e25.y + 4f);
    let _e30 = p_33;
    p_33.x = (_e30.x - 35f);
    let _e34 = p_33;
    let _e39 = sd_plane(_e34, vec3<f32>(0f, 1f, 0f));
    d_floor = _e39;
    let _e41 = p_33;
    let _e43 = world_height;
    p_roof = (_e41 - vec3<f32>(0f, _e43, 0f));
    let _e48 = p_roof;
    let _e54 = sd_plane(_e48, vec3<f32>(0f, -1f, 0f));
    d_roof = _e54;
    let _e56 = d_floor;
    let _e57 = d_roof;
    d_world = min(_e56, _e57);
    let _e60 = world_height;
    let _e63 = world_height;
    let _e69 = u_2;
    let _e71 = hash(_e69.t_start);
    let _e73 = u_2;
    y_1 = ((_e60 / 2f) + ((_e63 * 0.7f) * sin(((6.2831855f * _e71) + (_e73.t * 0.6f)))));
    let _e83 = y_1;
    y_1 = (5f + (_e83 * 0.65f));
    let _e87 = p_33;
    let _e89 = y_1;
    let _e95 = u_2;
    let _e100 = sd_sphere((_e87 - vec3<f32>(0f, _e89, 0f)), (5f + (3f * sin(_e95.t))));
    d_blob = _e100;
    let _e102 = d_world;
    let _e103 = d_blob;
    let _e105 = smin(_e102, _e103, 0.5f);
    d_world = _e105;
    let _e106 = d_world;
    return vec2<f32>(_e106, 5f);
}

fn map_cloud(p_34: vec3<f32>) -> vec2<f32> {
    var p_35: vec3<f32>;
    var q_2: vec3<f32>;
    var d_4: f32;

    p_35 = p_34;
    let _e18 = p_35;
    q_2 = (_e18 - vec3<f32>(15f, 10f, -30f));
    let _e26 = q_2;
    let _e28 = sd_sphere(_e26, 10f);
    let _e31 = q_2;
    let _e35 = q_2;
    let _e40 = q_2;
    let _e44 = u_2;
    d_4 = (_e28 + (0.2f * sin(((((5f * _e31.x) + (3f * _e35.z)) - (10f * _e40.y)) - _e44.t))));
    let _e51 = d_4;
    d_4 = (_e51 * 0.2f);
    let _e54 = d_4;
    return vec2<f32>(_e54, 4f);
}

fn get_heightmap_amplitude(world_7: i32) -> f32 {
    var world_8: i32;

    world_8 = world_7;
    let _e18 = world_8;
    if (_e18 == 4i) {
        return 3f;
    }
    let _e22 = world_8;
    if (_e22 == 3i) {
        return 60f;
    } else {
        return -1f;
    }
}

fn heightmap_water(p_36: vec2<f32>) -> vec4<f32> {
    var p_37: vec2<f32>;
    var offset: f32 = 20f;
    var amp_2: f32;
    var h_3: f32;

    p_37 = p_36;
    let _e21 = p_37;
    let _e23 = offset;
    p_37.y = (_e21.y + _e23);
    let _e26 = get_heightmap_amplitude(4i);
    amp_2 = _e26;
    let _e28 = amp_2;
    let _e30 = p_37;
    let _e33 = u_2;
    h_3 = (_e28 * sin(((0.3f * _e30.x) + _e33.t)));
    let _e39 = h_3;
    return vec4<f32>(_e39, 0f, 0f, 3f);
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
    let _e23 = u_2;
    let _e25 = hash12_(_e23.t_start);
    let _e27 = freq;
    let _e28 = p_39;
    let _e31 = octaves_5;
    let _e32 = terrain(((100f * _e25) + (_e27 * _e28)), _e31);
    fbm_1 = _e32;
    let _e34 = fbm_1;
    h_4 = _e34.x;
    let _e38 = get_heightmap_amplitude(3i);
    amp_3 = _e38;
    let _e40 = h_4;
    let _e41 = amp_3;
    h_4 = (_e40 * _e41);
    let _e43 = h_4;
    let _e45 = amp_3;
    h_4 = (_e43 - (0.5f * _e45));
    let _e48 = fbm_1;
    let _e50 = freq;
    let _e52 = amp_3;
    grad_3 = ((_e48.yz * _e50) * _e52);
    let _e55 = h_4;
    let _e56 = grad_3;
    return vec4<f32>(_e55, _e56.x, _e56.y, 2f);
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
    let _e26 = oct_min;
    let _e27 = oct_max;
    let _e28 = oct_min;
    let _e31 = t_max_1;
    let _e34 = t_max_1;
    let _e35 = t_1;
    octaves_6 = i32(round((f32(_e26) + (f32((_e27 - _e28)) * (1f - smoothstep((_e31 / 2f), _e34, _e35))))));
    let _e45 = p_41;
    let _e46 = octaves_6;
    let _e47 = heightmap_mountain_octaves(_e45, _e46);
    return _e47;
}

fn map(p_42: vec3<f32>) -> vec2<f32> {
    var p_43: vec3<f32>;

    p_43 = p_42;
    let _e18 = world_ray;
    if (_e18 == 0i) {
        let _e21 = p_43;
        let _e22 = map_hub(_e21);
        return _e22;
    } else {
        let _e23 = world_ray;
        if (_e23 == 1i) {
            let _e26 = p_43;
            let _e27 = map_fractal(_e26);
            return _e27;
        } else {
            let _e28 = world_ray;
            if (_e28 == 2i) {
                let _e31 = p_43;
                let _e32 = map_lavalamp(_e31);
                return _e32;
            } else {
                let _e33 = world_ray;
                if (_e33 == 5i) {
                    let _e36 = p_43;
                    let _e37 = map_cloud(_e36);
                    return _e37;
                } else {
                    let _e38 = world_ray;
                    if (_e38 == 3i) {
                        let _e41 = p_43;
                        let _e43 = p_43;
                        let _e47 = heightmap_mountain(_e43.xz, 0f, 0f);
                        return vec2<f32>((_e41.y - _e47.x), 2f);
                    } else {
                        let _e52 = world_ray;
                        if (_e52 == 4i) {
                            let _e55 = p_43;
                            let _e57 = p_43;
                            let _e59 = heightmap_water(_e57.xz);
                            return vec2<f32>((_e55.y - _e59.x), 3f);
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
    let _e22 = world_ray;
    if (_e22 == 0i) {
        {
            loop {
                let _e27 = i_6;
                if !((_e27 < 5i)) {
                    break;
                }
                {
                    let _e34 = i_6;
                    let _e38 = local_2[_e34];
                    world_dst = _e38;
                    let _e40 = world_dst;
                    let _e41 = get_portal(_e40);
                    portal_2 = _e41;
                    let _e43 = p_45;
                    let _e46 = portal_2[0];
                    let _e50 = portal_2[1];
                    let _e51 = sd_portal((_e43 - _e46), _e50);
                    d_5 = _e51;
                    let _e53 = res_3;
                    let _e54 = d_5;
                    let _e56 = world_dst;
                    let _e60 = u_op(_e53, vec2<f32>(_e54, (100f + f32(_e56))));
                    res_3 = _e60;
                }
                continuing {
                    let _e31 = i_6;
                    i_6 = (_e31 + 1i);
                }
            }
        }
    } else {
        {
            let _e61 = world_ray;
            let _e62 = get_portal(_e61);
            portal_3 = _e62;
            let _e64 = p_45;
            let _e67 = portal_3[0];
            let _e73 = portal_3[1];
            let _e75 = sd_portal((_e64 - _e67), (-1f * _e73));
            d_6 = _e75;
            let _e77 = res_3;
            let _e78 = d_6;
            let _e84 = u_op(_e77, vec2<f32>(_e78, 100f));
            res_3 = _e84;
        }
    }
    let _e85 = res_3;
    return _e85;
}

fn heightmap(p_46: vec2<f32>, t_2: f32, t_max_2: f32) -> vec4<f32> {
    var p_47: vec2<f32>;
    var t_3: f32;
    var t_max_3: f32;

    p_47 = p_46;
    t_3 = t_2;
    t_max_3 = t_max_2;
    let _e22 = world_ray;
    if (_e22 == 3i) {
        let _e25 = p_47;
        let _e26 = t_3;
        let _e27 = t_max_3;
        let _e28 = heightmap_mountain(_e25, _e26, _e27);
        return _e28;
    }
    let _e29 = world_ray;
    if (_e29 == 4i) {
        let _e32 = p_47;
        let _e33 = heightmap_water(_e32);
        return _e33;
    }
    return vec4(0f);
}

fn raymarch_sdf(ro: vec3<f32>, rd: vec3<f32>) -> vec2<f32> {
    var ro_1: vec3<f32>;
    var rd_1: vec3<f32>;
    var t_res: f32 = 0.001f;
    var t_max_4: f32 = 100f;
    var i_7: i32 = 0i;
    var p_48: vec3<f32>;
    var hit: vec2<f32>;
    var t_4: f32;
    var id_1: f32;

    ro_1 = ro;
    rd_1 = rd;
    loop {
        let _e26 = i_7;
        if !((_e26 < 256i)) {
            break;
        }
        {
            let _e33 = ro_1;
            let _e34 = t_res;
            let _e35 = rd_1;
            p_48 = (_e33 + (_e34 * _e35));
            let _e39 = p_48;
            let _e40 = map(_e39);
            hit = _e40;
            let _e42 = hit;
            let _e43 = p_48;
            let _e44 = map_portals(_e43);
            let _e45 = u_op(_e42, _e44);
            hit = _e45;
            let _e46 = hit;
            t_4 = _e46.x;
            let _e49 = hit;
            id_1 = _e49.y;
            let _e52 = t_4;
            if (abs(_e52) < 0.001f) {
                {
                    let _e56 = t_res;
                    let _e57 = id_1;
                    return vec2<f32>(_e56, _e57);
                }
            }
            let _e59 = t_res;
            let _e60 = t_4;
            t_res = (_e59 + _e60);
            let _e62 = t_res;
            let _e63 = t_max_4;
            if (_e62 > _e63) {
                {
                    break;
                }
            }
        }
        continuing {
            let _e30 = i_7;
            i_7 = (_e30 + 1i);
        }
    }
    return vec2(-1f);
}

fn raymarch_terrain(ro_2: vec3<f32>, rd_2: vec3<f32>) -> vec2<f32> {
    var ro_3: vec3<f32>;
    var rd_3: vec3<f32>;
    var t_5: f32 = 0.01f;
    var t_max_5: f32 = 1600f;
    var h_max: f32;
    var rd_is_up: bool;
    var portal_4: mat2x3<f32>;
    var h_portal: f32;
    var i_8: i32 = 0i;
    var p_49: vec3<f32>;
    var hm: vec4<f32>;
    var h_5: f32;
    var id_2: f32;
    var dh: f32;
    var d_portal: f32;
    var dt: f32;

    ro_3 = ro_2;
    rd_3 = rd_2;
    let _e24 = world_ray;
    let _e25 = get_heightmap_amplitude(_e24);
    h_max = _e25;
    let _e27 = rd_3;
    rd_is_up = (_e27.y > 0f);
    let _e32 = world_ray;
    let _e33 = get_portal(_e32);
    portal_4 = _e33;
    let _e37 = portal_4[0];
    h_portal = (_e37.y + 7.4f);
    let _e42 = h_max;
    let _e43 = h_portal;
    h_max = max(_e42, _e43);
    let _e45 = ro_3;
    let _e47 = h_max;
    let _e49 = rd_is_up;
    if ((_e45.y > _e47) && _e49) {
        return vec2(-1f);
    }
    let _e54 = ro_3;
    let _e56 = h_max;
    if (_e54.y > _e56) {
        {
            let _e58 = t_5;
            let _e59 = h_max;
            let _e60 = ro_3;
            let _e63 = rd_3;
            t_5 = max(_e58, ((_e59 - _e60.y) / _e63.y));
        }
    }
    loop {
        let _e69 = i_8;
        if !((_e69 < 256i)) {
            break;
        }
        {
            let _e76 = ro_3;
            let _e77 = t_5;
            let _e78 = rd_3;
            p_49 = (_e76 + (_e77 * _e78));
            let _e82 = p_49;
            let _e84 = t_5;
            let _e85 = t_max_5;
            let _e86 = heightmap(_e82.xz, _e84, _e85);
            hm = _e86;
            let _e88 = hm;
            h_5 = _e88.x;
            let _e91 = hm;
            id_2 = _e91.w;
            let _e94 = p_49;
            let _e96 = h_5;
            dh = (_e94.y - _e96);
            let _e99 = dh;
            let _e102 = t_5;
            if (abs(_e99) < (0.001f * _e102)) {
                {
                    let _e105 = t_5;
                    let _e106 = id_2;
                    return vec2<f32>(_e105, _e106);
                }
            }
            let _e108 = p_49;
            let _e111 = portal_4[0];
            let _e117 = portal_4[1];
            let _e119 = sd_portal((_e108 - _e111), (-1f * _e117));
            d_portal = _e119;
            let _e121 = d_portal;
            if (_e121 < 0.001f) {
                {
                    let _e124 = t_5;
                    return vec2<f32>(_e124, 100f);
                }
            }
            let _e131 = dh;
            dt = (0.45f * _e131);
            let _e134 = dt;
            let _e135 = d_portal;
            dt = min(_e134, _e135);
            let _e137 = t_5;
            let _e138 = dt;
            t_5 = (_e137 + _e138);
            let _e140 = t_5;
            let _e141 = t_max_5;
            if (_e140 > _e141) {
                break;
            }
        }
        continuing {
            let _e73 = i_8;
            i_8 = (_e73 + 1i);
        }
    }
    return vec2(-1f);
}

fn raymarch(ro_4: vec3<f32>, rd_4: vec3<f32>) -> vec2<f32> {
    var ro_5: vec3<f32>;
    var rd_5: vec3<f32>;
    var t_res_1: f32 = 0f;
    var ro_current: vec3<f32>;
    var hit_1: vec2<f32>;
    var t_6: f32;
    var id_3: f32;
    var n_7: vec3<f32>;
    var a_9: f32;

    ro_5 = ro_4;
    rd_5 = rd_4;
    loop {
        let _e22 = t_res_1;
        if !((_e22 < 150f)) {
            break;
        }
        {
            let _e27 = ro_5;
            let _e28 = rd_5;
            let _e29 = t_res_1;
            ro_current = (_e27 + (_e28 * _e29));
            let _e34 = use_heightmap();
            if _e34 {
                let _e35 = ro_current;
                let _e36 = rd_5;
                let _e37 = raymarch_terrain(_e35, _e36);
                hit_1 = _e37;
            } else {
                let _e38 = ro_current;
                let _e39 = rd_5;
                let _e40 = raymarch_sdf(_e38, _e39);
                hit_1 = _e40;
            }
            let _e41 = hit_1;
            t_6 = _e41.x;
            let _e44 = hit_1;
            id_3 = _e44.y;
            let _e47 = t_6;
            if (_e47 > 0f) {
                {
                    let _e50 = t_res_1;
                    let _e51 = t_6;
                    t_res_1 = (_e50 + _e51);
                    let _e53 = id_3;
                    if (_e53 >= 100f) {
                        {
                            let _e56 = id_3;
                            world_ray = i32((_e56 - 100f));
                            let _e61 = world_ray;
                            let _e62 = get_portal(_e61);
                            n_7 = _e62[1];
                            let _e65 = n_7;
                            let _e66 = rd_5;
                            a_9 = max(abs(dot(_e65, _e66)), 0.000001f);
                            let _e72 = t_res_1;
                            let _e74 = a_9;
                            t_res_1 = (_e72 + (0.01f / _e74));
                            continue;
                        }
                    }
                    let _e77 = t_res_1;
                    let _e78 = id_3;
                    return vec2<f32>(_e77, _e78);
                }
            } else {
                break;
            }
        }
    }
    return vec2(-1f);
}

fn normal_numerical(p_50: vec3<f32>, t_7: f32) -> vec3<f32> {
    var p_51: vec3<f32>;
    var t_8: f32;
    var e: vec2<f32>;
    var n_8: vec3<f32>;
    var o: i32 = 12i;

    p_51 = p_50;
    t_8 = t_7;
    let _e26 = t_8;
    e = (vec2<f32>(1f, -1f) * max(0.001f, (0.001f * _e26)));
    let _e32 = world_ray;
    if (_e32 == 3i) {
        {
            let _e37 = e;
            let _e39 = p_51;
            let _e41 = e;
            let _e44 = p_51;
            let _e46 = e;
            let _e49 = o;
            let _e50 = heightmap_mountain_octaves((_e44.xz + _e46.xy), _e49);
            let _e54 = e;
            let _e56 = p_51;
            let _e58 = e;
            let _e61 = p_51;
            let _e63 = e;
            let _e66 = o;
            let _e67 = heightmap_mountain_octaves((_e61.xz + _e63.yx), _e66);
            let _e72 = e;
            let _e74 = p_51;
            let _e76 = e;
            let _e79 = p_51;
            let _e81 = e;
            let _e84 = o;
            let _e85 = heightmap_mountain_octaves((_e79.xz + _e81.yy), _e84);
            let _e90 = e;
            let _e92 = p_51;
            let _e94 = e;
            let _e97 = p_51;
            let _e99 = e;
            let _e102 = o;
            let _e103 = heightmap_mountain_octaves((_e97.xz + _e99.xx), _e102);
            n_8 = normalize(((((_e37.xyy * ((_e39.y + _e41.y) - _e50.x)) + (_e54.yyx * ((_e56.y + _e58.y) - _e67.x))) + (_e72.yxy * ((_e74.y + _e76.x) - _e85.x))) + (_e90.xxx * ((_e92.y + _e94.x) - _e103.x))));
        }
    } else {
        {
            let _e109 = e;
            let _e111 = p_51;
            let _e112 = e;
            let _e115 = map((_e111 + _e112.xyy));
            let _e118 = e;
            let _e120 = p_51;
            let _e121 = e;
            let _e124 = map((_e120 + _e121.yyx));
            let _e128 = e;
            let _e130 = p_51;
            let _e131 = e;
            let _e134 = map((_e130 + _e131.yxy));
            let _e138 = e;
            let _e140 = p_51;
            let _e141 = e;
            let _e144 = map((_e140 + _e141.xxx));
            n_8 = normalize(((((_e109.xyy * _e115.x) + (_e118.yyx * _e124.x)) + (_e128.yxy * _e134.x)) + (_e138.xxx * _e144.x)));
        }
    }
    let _e149 = n_8;
    return _e149;
}

fn normal_analytical(p_52: vec2<f32>) -> vec3<f32> {
    var p_53: vec2<f32>;
    var grad_4: vec2<f32>;
    var n_9: vec3<f32>;

    p_53 = p_52;
    let _e18 = p_53;
    let _e20 = heightmap_mountain_octaves(_e18, 12i);
    grad_4 = _e20.yz;
    let _e23 = grad_4;
    let _e27 = grad_4;
    n_9 = normalize(vec3<f32>(-(_e23.x), 1f, -(_e27.y)));
    let _e33 = n_9;
    return _e33;
}

fn normal(p_54: vec3<f32>, t_9: f32) -> vec3<f32> {
    var p_55: vec3<f32>;
    var t_10: f32;
    var n_10: vec3<f32>;

    p_55 = p_54;
    t_10 = t_9;
    if false {
    } else {
        let _e22 = p_55;
        let _e23 = t_10;
        let _e24 = normal_numerical(_e22, _e23);
        n_10 = _e24;
    }
    let _e25 = n_10;
    return _e25;
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
        let _e28 = i_9;
        let _e31 = d_7;
        let _e32 = d_max_1;
        if !(((_e28 < 128i) && (_e31 < _e32))) {
            break;
        }
        {
            let _e39 = ro_7;
            let _e40 = rd_7;
            let _e41 = d_7;
            p_56 = (_e39 + (_e40 * _e41));
            let _e45 = p_56;
            let _e46 = map(_e45);
            h_6 = _e46.x;
            let _e49 = h_6;
            if (_e49 < 0.001f) {
                return 0f;
            }
            let _e53 = occlusion;
            let _e55 = h_6;
            let _e57 = d_7;
            occlusion = min(_e53, ((32f * _e55) / _e57));
            let _e60 = d_7;
            let _e61 = h_6;
            d_7 = (_e60 + _e61);
        }
        continuing {
            let _e36 = i_9;
            i_9 = (_e36 + 1i);
        }
    }
    let _e63 = occlusion;
    return _e63;
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
        let _e26 = i_10;
        if !((_e26 <= 4i)) {
            break;
        }
        {
            let _e34 = i_10;
            h_7 = (0.04f * f32(_e34));
            let _e38 = p_58;
            let _e39 = h_7;
            let _e40 = n_12;
            let _e43 = map((_e38 + (_e39 * _e40)));
            d_8 = _e43.x;
            let _e46 = occlusion_1;
            let _e47 = h_7;
            let _e48 = d_8;
            let _e50 = scale_1;
            occlusion_1 = (_e46 + ((_e47 - _e48) * _e50));
            let _e53 = scale_1;
            scale_1 = (_e53 * 0.95f);
        }
        continuing {
            let _e30 = i_10;
            i_10 = (_e30 + 1i);
        }
    }
    let _e57 = occlusion_1;
    return (1f - clamp(_e57, 0f, 1f));
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
        let _e38 = i_11;
        if !((_e38 < 4i)) {
            break;
        }
        {
            let _e45 = p_60;
            let _e47 = p_60;
            let _e50 = i_11;
            let _e52 = offsets[_e50];
            let _e54 = (_e47.xz + (0.1f * _e52));
            p_60.x = _e54.x;
            p_60.z = _e54.y;
            q_3 = _e54;
            let _e60 = p_60;
            let _e64 = heightmap(_e60.xz, 0f, 0f);
            h_8 = _e64.x;
            let _e67 = p_60;
            let _e69 = h_8;
            dh_1 = (_e67.y - _e69);
            let _e72 = occlusion_2;
            let _e74 = dh_1;
            occlusion_2 = (_e72 - (0.5f * _e74));
        }
        continuing {
            let _e42 = i_11;
            i_11 = (_e42 + 1i);
        }
    }
    let _e77 = occlusion_2;
    return _e77;
}

fn ambient_occlusion(p_61: vec3<f32>, n_13: vec3<f32>) -> f32 {
    var p_62: vec3<f32>;
    var n_14: vec3<f32>;
    var ao: f32;

    p_62 = p_61;
    n_14 = n_13;
    let _e21 = use_heightmap();
    if _e21 {
        {
            let _e22 = p_62;
            let _e23 = ambient_occlusion_terrain(_e22);
            ao = _e23;
        }
    } else {
        {
            let _e24 = p_62;
            let _e25 = n_14;
            let _e26 = ambient_occlusion_sdf(_e24, _e25);
            ao = _e26;
        }
    }
    let _e27 = ao;
    return _e27;
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
    let _e22 = roughness_1;
    let _e23 = roughness_1;
    a_10 = (_e22 * _e23);
    let _e26 = a_10;
    let _e27 = a_10;
    a2_ = (_e26 * _e27);
    let _e30 = n_16;
    let _e31 = h_10;
    nh = max(dot(_e30, _e31), 0f);
    let _e36 = nh;
    let _e37 = nh;
    nh2_ = (_e36 * _e37);
    let _e40 = a2_;
    num = _e40;
    let _e42 = nh2_;
    let _e43 = a2_;
    denom = ((_e42 * (_e43 - 1f)) + 1f);
    let _e51 = denom;
    let _e53 = denom;
    denom = ((3.1415927f * _e51) * _e53);
    let _e55 = num;
    let _e56 = denom;
    return (_e55 / _e56);
}

fn fresnel(v: vec3<f32>, h_11: vec3<f32>, f0_: vec3<f32>) -> vec3<f32> {
    var v_1: vec3<f32>;
    var h_12: vec3<f32>;
    var f0_1: vec3<f32>;
    var cos_theta: f32;

    v_1 = v;
    h_12 = h_11;
    f0_1 = f0_;
    let _e22 = v_1;
    let _e23 = h_12;
    cos_theta = max(dot(_e22, _e23), 0f);
    let _e28 = f0_1;
    let _e30 = f0_1;
    let _e34 = cos_theta;
    return (_e28 + ((vec3(1f) - _e30) * pow(clamp((1f - _e34), 0f, 1f), 5f)));
}

fn g1_(n_17: vec3<f32>, dir: vec3<f32>, roughness_2: f32) -> f32 {
    var n_18: vec3<f32>;
    var dir_1: vec3<f32>;
    var roughness_3: f32;
    var r_4: f32;
    var k_6: f32;
    var cos_theta_1: f32;
    var num_1: f32;
    var denom_1: f32;

    n_18 = n_17;
    dir_1 = dir;
    roughness_3 = roughness_2;
    let _e22 = roughness_3;
    r_4 = (_e22 + 1f);
    let _e26 = r_4;
    let _e27 = r_4;
    k_6 = ((_e26 * _e27) / 8f);
    let _e32 = n_18;
    let _e33 = dir_1;
    cos_theta_1 = max(dot(_e32, _e33), 0f);
    let _e38 = cos_theta_1;
    num_1 = _e38;
    let _e40 = cos_theta_1;
    let _e42 = k_6;
    let _e45 = k_6;
    denom_1 = ((_e40 * (1f - _e42)) + _e45);
    let _e48 = num_1;
    let _e49 = denom_1;
    return (_e48 / _e49);
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
    let _e24 = n_20;
    let _e25 = v_3;
    let _e26 = roughness_5;
    let _e27 = g1_(_e24, _e25, _e26);
    masking = _e27;
    let _e29 = n_20;
    let _e30 = l_1;
    let _e31 = roughness_5;
    let _e32 = g1_(_e29, _e30, _e31);
    shadowing = _e32;
    let _e34 = masking;
    let _e35 = shadowing;
    return (_e34 * _e35);
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
    let _e26 = light_1;
    let _e28 = p_64;
    l_2 = normalize((_e26.pos - _e28));
    let _e32 = v_5;
    let _e33 = l_2;
    h_13 = normalize((_e32 + _e33));
    let _e40 = f0_2;
    let _e41 = material_1;
    let _e43 = material_1;
    f0_2 = mix(_e40, _e41.albedo, vec3(_e43.metallic));
    let _e47 = light_1;
    let _e49 = p_64;
    distance_ = length((_e47.pos - _e49));
    let _e54 = distance_;
    let _e55 = distance_;
    attenuation = (1f / (_e54 * _e55));
    let _e59 = light_1;
    let _e61 = light_1;
    let _e64 = attenuation;
    radiance = ((_e59.color * _e61.strength) * _e64);
    let _e67 = n_22;
    let _e68 = h_13;
    let _e69 = material_1;
    let _e71 = distribution(_e67, _e68, _e69.roughness);
    D = _e71;
    let _e73 = n_22;
    let _e74 = v_5;
    let _e75 = l_2;
    let _e76 = material_1;
    let _e78 = geometry(_e73, _e74, _e75, _e76.roughness);
    G = _e78;
    let _e80 = v_5;
    let _e81 = h_13;
    let _e82 = f0_2;
    let _e83 = fresnel(_e80, _e81, _e82);
    F = _e83;
    let _e85 = D;
    let _e86 = G;
    let _e88 = F;
    num_2 = ((_e85 * _e86) * _e88);
    let _e92 = n_22;
    let _e93 = v_5;
    let _e98 = n_22;
    let _e99 = l_2;
    denom_2 = (((4f * max(dot(_e92, _e93), 0f)) * max(dot(_e98, _e99), 0f)) + 0.0001f);
    let _e107 = num_2;
    let _e108 = denom_2;
    specular = (_e107 / vec3(_e108));
    let _e112 = F;
    k_s = _e112;
    let _e116 = k_s;
    k_d = (vec3(1f) - _e116);
    let _e119 = k_d;
    let _e121 = material_1;
    k_d = (_e119 * (1f - _e121.metallic));
    let _e125 = k_d;
    let _e126 = material_1;
    let _e132 = specular;
    brdf = (((_e125 * _e126.albedo) / vec3(3.1415927f)) + _e132);
    let _e135 = brdf;
    let _e136 = radiance;
    let _e138 = n_22;
    let _e139 = l_2;
    return ((_e135 * _e136) * max(dot(_e138, _e139), 0f));
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
    var ao_1: f32;
    var s_2: f32;
    var light_2: vec3<f32>;
    var light_pos: vec3<f32>;
    var light_color: vec3<f32> = vec3<f32>(1f, 1f, 1f);
    var lamp: Light;
    var direct: vec3<f32>;
    var l_3: vec3<f32>;
    var s_3: f32;
    var ao_2: f32;
    var ambient: vec3<f32>;

    p_66 = p_65;
    n_24 = n_23;
    v_7 = v_6;
    material_3 = material_2;
    t_12 = t_11;
    let _e29 = use_heightmap();
    if _e29 {
        {
            let _e57 = n_24;
            let _e58 = dir_sun;
            diffuse_sun = clamp(dot(_e57, _e58), 0f, 1f);
            let _e66 = n_24;
            diffuse_sky = clamp((0.5f + (0.5f * _e66.y)), 0f, 1f);
            let _e74 = n_24;
            let _e75 = dir_sun;
            diffuse_ind = clamp(dot(_e74, normalize((_e75 * vec3<f32>(-1f, 0f, -1f)))), 0f, 1f);
            let _e89 = p_66;
            let _e90 = n_24;
            let _e91 = ambient_occlusion(_e89, _e90);
            ao_1 = _e91;
            let _e93 = p_66;
            let _e94 = dir_sun;
            let _e96 = shadow(_e93, _e94, 50f);
            s_2 = _e96;
            let _e98 = col_sun;
            let _e99 = diffuse_sun;
            let _e101 = s_2;
            light_2 = ((_e98 * _e99) * _e101);
            let _e104 = light_2;
            let _e105 = col_sky;
            let _e106 = diffuse_sky;
            let _e108 = ao_1;
            light_2 = (_e104 + ((_e105 * _e106) * _e108));
            let _e111 = light_2;
            let _e112 = col_ind;
            let _e113 = diffuse_ind;
            let _e115 = ao_1;
            light_2 = (_e111 + ((_e112 * _e113) * _e115));
            let _e118 = material_3;
            let _e120 = light_2;
            color = (_e118.albedo * _e120);
        }
    } else {
        {
            let _e122 = u_2;
            light_pos = (_e122.camera.pos + vec3<f32>(0f, 5f, 0f));
            let _e136 = light_pos;
            let _e137 = light_color;
            lamp = Light(_e136, _e137, 1500f);
            let _e141 = p_66;
            let _e142 = n_24;
            let _e143 = v_7;
            let _e144 = lamp;
            let _e145 = material_3;
            let _e146 = light_direct(_e141, _e142, _e143, _e144, _e145);
            direct = _e146;
            let _e148 = light_pos;
            let _e149 = p_66;
            l_3 = normalize((_e148 - _e149));
            let _e153 = p_66;
            let _e154 = l_3;
            let _e155 = light_pos;
            let _e156 = p_66;
            let _e159 = shadow(_e153, _e154, length((_e155 - _e156)));
            s_3 = _e159;
            let _e161 = direct;
            let _e162 = s_3;
            direct = (_e161 * _e162);
            let _e164 = p_66;
            let _e165 = n_24;
            let _e166 = ambient_occlusion(_e164, _e165);
            ao_2 = _e166;
            let _e170 = material_3;
            let _e173 = ao_2;
            ambient = ((vec3(0.0001f) * _e170.albedo) * _e173);
            let _e176 = direct;
            let _e177 = ambient;
            color = (_e176 + _e177);
        }
    }
    let _e179 = color;
    return _e179;
}

fn get_material(id_4: f32, p_67: vec3<f32>, n_25: vec3<f32>, t_13: f32) -> Material {
    var id_5: f32;
    var p_68: vec3<f32>;
    var n_26: vec3<f32>;
    var t_14: f32;
    var amp_4: f32;
    var r_5: f32;
    var y_2: f32;
    var rock1_: vec3<f32> = vec3<f32>(0.1f, 0.09f, 0.08f);
    var rock2_: vec3<f32> = vec3<f32>(0.05f, 0.04f, 0.03f);
    var color_1: vec3<f32>;
    var dirt: vec3<f32> = vec3<f32>(0.045f, 0.03f, 0.02f);
    var grass: vec3<f32> = vec3<f32>(0.05f, 0.05f, 0.01f);
    var h_14: f32;
    var s_4: f32;
    var snow: vec3<f32> = vec3(0.95f);

    id_5 = id_4;
    p_68 = p_67;
    n_26 = n_25;
    t_14 = t_13;
    let _e24 = id_5;
    if (_e24 == 1f) {
        return Material(vec3<f32>(1f, 0f, 0f), 0.5f, 0.5f);
    } else {
        let _e34 = id_5;
        if (_e34 == 2f) {
            {
                let _e38 = get_heightmap_amplitude(3i);
                amp_4 = _e38;
                let _e40 = p_68;
                let _e44 = noised_value((_e40.xz * 0.01f));
                r_5 = _e44.x;
                let _e47 = p_68;
                let _e50 = amp_4;
                y_2 = (_e47.y + (0.5f * _e50));
                let _e65 = r_5;
                let _e71 = rock1_;
                let _e72 = rock2_;
                let _e74 = p_68;
                let _e76 = p_68;
                let _e82 = noised_value((0.1f * vec2<f32>(_e74.x, (_e76.y * 3f))));
                color_1 = ((0.9f * ((_e65 * 0.25f) + 0.75f)) * mix(_e71, _e72, vec3(_e82.x)));
                let _e93 = color_1;
                let _e94 = dirt;
                let _e95 = r_5;
                let _e103 = n_26;
                color_1 = mix(_e93, (_e94 * ((_e95 * 0.5f) + 0.5f)), vec3(smoothstep(0.75f, 0.9f, _e103.y)));
                let _e113 = color_1;
                let _e114 = grass;
                let _e115 = r_5;
                let _e123 = n_26;
                color_1 = mix(_e113, (_e114 * ((_e115 * 0.75f) + 0.25f)), vec3(smoothstep(0.95f, 1f, _e123.y)));
                let _e129 = amp_4;
                let _e132 = amp_4;
                let _e134 = y_2;
                let _e136 = amp_4;
                let _e138 = p_68;
                let _e143 = fbm((_e138.xz * 0.5f), 2i);
                h_14 = smoothstep((0.55f * _e129), (0.65f * _e132), (_e134 + ((0.13f * _e136) * _e143)));
                let _e150 = h_14;
                let _e155 = h_14;
                let _e160 = n_26;
                s_4 = smoothstep((1f - (0.5f * _e150)), (1f - (0.1f * _e155)), (0.25f + (0.75f * _e160.y)));
                let _e169 = color_1;
                let _e170 = snow;
                let _e171 = s_4;
                color_1 = mix(_e169, _e170, vec3(_e171));
                let _e174 = color_1;
                return Material(_e174, 0.5f, 0.2f);
            }
        } else {
            let _e178 = id_5;
            if (_e178 == 3f) {
                return Material(vec3<f32>(0f, 0f, 1f), 0.5f, 0.5f);
            } else {
                let _e188 = id_5;
                if (_e188 == 4f) {
                    return Material(vec3<f32>(0.8f, 0.8f, 0.8f), 0.5f, 0.5f);
                } else {
                    let _e198 = id_5;
                    if (_e198 == 5f) {
                        return Material(vec3<f32>(1f, 0f, 1f), 0.5f, 0.5f);
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
    var hit_2: vec2<f32>;
    var t_15: f32;
    var material_id: f32;
    var color_2: vec3<f32> = vec3(0f);
    var p_69: vec3<f32>;
    var n_27: vec3<f32>;
    var v_8: vec3<f32>;
    var material_4: Material;
    var light_3: vec3<f32>;
    var noise_2: f32;

    let _e17 = gl_GlobalInvocationID_1;
    x_4 = _e17.x;
    let _e20 = gl_GlobalInvocationID_1;
    y_3 = _e20.y;
    let _e23 = x_4;
    let _e24 = u_2;
    let _e29 = y_3;
    let _e30 = u_2;
    if ((f32(_e23) >= _e24.resolution.x) || (f32(_e29) >= _e30.resolution.y)) {
        return;
    }
    let _e36 = x_4;
    let _e38 = u_2;
    let _e42 = y_3;
    let _e44 = u_2;
    uv = vec2<f32>((f32(_e36) / _e38.resolution.x), (f32(_e42) / _e44.resolution.y));
    let _e50 = uv;
    uv = ((_e50 * 2f) - vec2(1f));
    let _e57 = uv;
    uv.y = (_e57.y * -1f);
    let _e64 = uv;
    let _e66 = u_2;
    let _e69 = u_2;
    uv.x = (_e64.x * (_e66.resolution.x / _e69.resolution.y));
    let _e74 = u_2;
    ro_10 = _e74.camera.pos;
    let _e78 = u_2;
    let _e81 = u_2;
    let _e84 = u_2;
    camera_orientation = mat3x3<f32>(vec3<f32>(_e78.camera.right.x, _e78.camera.right.y, _e78.camera.right.z), vec3<f32>(_e81.camera.up.x, _e81.camera.up.y, _e81.camera.up.z), vec3<f32>(_e84.camera.forward.x, _e84.camera.forward.y, _e84.camera.forward.z));
    let _e101 = camera_orientation;
    let _e102 = uv;
    rd_10 = (_e101 * normalize(vec3<f32>(_e102.x, _e102.y, 1f)));
    let _e110 = get_world();
    world_9 = _e110;
    let _e112 = x_4;
    let _e116 = y_3;
    if ((_e112 == 0u) && (_e116 == 0u)) {
        {
            let _e121 = world_9;
            global.world_global = _e121;
            let _e122 = world_9;
            world_ray = _e122;
        }
    } else {
        let _e123 = world_9;
        world_ray = _e123;
    }
    let _e124 = ro_10;
    let _e125 = rd_10;
    let _e126 = raymarch(_e124, _e125);
    hit_2 = _e126;
    let _e128 = hit_2;
    t_15 = _e128.x;
    let _e131 = hit_2;
    material_id = _e131.y;
    let _e137 = t_15;
    if (_e137 > 0f) {
        {
            let _e140 = ro_10;
            let _e141 = t_15;
            let _e142 = rd_10;
            p_69 = (_e140 + (_e141 * _e142));
            let _e146 = p_69;
            let _e147 = t_15;
            let _e148 = normal(_e146, _e147);
            n_27 = _e148;
            let _e150 = ro_10;
            let _e151 = p_69;
            v_8 = normalize((_e150 - _e151));
            let _e155 = material_id;
            let _e156 = p_69;
            let _e157 = n_27;
            let _e158 = t_15;
            let _e159 = get_material(_e155, _e156, _e157, _e158);
            material_4 = _e159;
            let _e161 = p_69;
            let _e162 = n_27;
            let _e163 = v_8;
            let _e164 = material_4;
            let _e165 = t_15;
            let _e166 = lighting(_e161, _e162, _e163, _e164, _e165);
            light_3 = _e166;
            let _e168 = light_3;
            color_2 = _e168;
        }
    } else {
        {
            let _e169 = world_ray;
            let _e170 = get_bg(_e169);
            color_2 = _e170;
        }
    }
    let _e171 = color_2;
    color_2 = pow(_e171, vec3(0.45454544f));
    let _e177 = uv;
    let _e178 = u_2;
    let _e182 = hash21_((_e177 + vec2(_e178.t)));
    noise_2 = ((_e182 * 2f) - 1f);
    let _e188 = color_2;
    let _e189 = noise_2;
    color_2 = (_e188 + vec3((_e189 * 0.003921569f)));
    let _e196 = x_4;
    let _e197 = y_3;
    let _e201 = color_2;
    textureStore(rendertarget, vec2<i32>(i32(_e196), i32(_e197)), vec4<f32>(_e201.x, _e201.y, _e201.z, 1f));
    return;
}

@compute @workgroup_size(16, 16, 1) 
fn main(@builtin(global_invocation_id) gl_GlobalInvocationID: vec3<u32>) {
    gl_GlobalInvocationID_1 = gl_GlobalInvocationID;
    main_1();
    return;
}

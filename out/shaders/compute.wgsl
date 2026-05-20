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
    type_: i32,
    albedo: vec3<f32>,
    roughness: f32,
    metallic: f32,
}

struct Light {
    pos: vec3<f32>,
    color: vec3<f32>,
    strength: f32,
}

struct Hit {
    d: f32,
    material: Material,
    world_target: i32,
}

const SUB_WORLDS: array<i32, 5> = array<i32, 5>(2i, 1i, 3i, 4i, 5i);

@group(0) @binding(0) 
var rendertarget: texture_storage_2d<rgba8unorm,write>;
@group(0) @binding(1) 
var<storage, read_write> global: state;
var<private> world_ray: i32;
@group(1) @binding(0) 
var<uniform> u_1: frame;
var<private> g_blub_pos: array<vec3<f32>, 4>;
var<private> g_blub_r: array<f32, 4>;
var<private> gl_GlobalInvocationID_1: vec3<u32>;

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
    let _e46 = sd_ellipsoid(_e41, vec3<f32>(2.3f, 3.7f, 1f));
    let _e47 = p_local;
    let _e52 = sd_box(_e47, vec3<f32>(2.3f, 3.7f, 0.00000001f));
    return max(_e46, _e52);
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

    p_11 = p_10;
    let _e18 = p_11;
    return fract((sin(dot(_e18, vec2<f32>(12.9898f, 78.233f))) * 43758.547f));
}

fn hash23_(p_12: vec2<f32>) -> vec3<f32> {
    var p_13: vec2<f32>;
    var p3_2: vec3<f32>;

    p_13 = p_12;
    let _e18 = p_13;
    p3_2 = fract((vec3<f32>(_e18.xyx) * vec3<f32>(0.1031f, 0.103f, 0.0973f)));
    let _e28 = p3_2;
    let _e29 = p3_2;
    let _e30 = p3_2;
    p3_2 = (_e28 + vec3(dot(_e29, (_e30.yxz + vec3(33.33f)))));
    let _e38 = p3_2;
    let _e40 = p3_2;
    let _e43 = p3_2;
    return fract(((_e38.xxy + _e40.yzz) * _e43.zyx));
}

fn hash22_(p_14: vec2<f32>) -> vec2<f32> {
    var p_15: vec2<f32>;
    var p3_3: vec3<f32>;

    p_15 = p_14;
    let _e18 = p_15;
    p3_3 = fract((vec3<f32>(_e18.xyx) * vec3<f32>(0.1031f, 0.103f, 0.0973f)));
    let _e28 = p3_3;
    let _e29 = p3_3;
    let _e30 = p3_3;
    p3_3 = (_e28 + vec3(dot(_e29, (_e30.yzx + vec3(33.33f)))));
    let _e38 = p3_3;
    let _e40 = p3_3;
    let _e43 = p3_3;
    return ((fract(((_e38.xx + _e40.yz) * _e43.zy)) * 2f) - vec2(1f));
}

fn hash12_(p_16: f32) -> vec2<f32> {
    var p_17: f32;
    var p3_4: vec3<f32>;

    p_17 = p_16;
    let _e18 = p_17;
    p3_4 = fract((vec3(_e18) * vec3<f32>(0.1031f, 0.103f, 0.0973f)));
    let _e27 = p3_4;
    let _e28 = p3_4;
    let _e29 = p3_4;
    p3_4 = (_e27 + vec3(dot(_e28, (_e29.yzx + vec3(33.33f)))));
    let _e37 = p3_4;
    let _e39 = p3_4;
    let _e42 = p3_4;
    return fract(((_e37.xx + _e39.yz) * _e42.zy));
}

fn hash13_(p_18: f32) -> vec3<f32> {
    var p_19: f32;
    var p3_5: vec3<f32>;

    p_19 = p_18;
    let _e18 = p_19;
    p3_5 = fract((vec3(_e18) * vec3<f32>(0.1031f, 0.103f, 0.0973f)));
    let _e27 = p3_5;
    let _e28 = p3_5;
    let _e29 = p3_5;
    p3_5 = (_e27 + vec3(dot(_e28, (_e29.yzx + vec3(33.33f)))));
    let _e37 = p3_5;
    let _e39 = p3_5;
    let _e42 = p3_5;
    return fract(((_e37.xxy + _e39.yzz) * _e42.zyx));
}

fn hash33_(p3_6: vec3<f32>) -> vec3<f32> {
    var p3_7: vec3<f32>;

    p3_7 = p3_6;
    let _e18 = p3_7;
    p3_7 = fract((_e18 * vec3<f32>(0.1031f, 0.103f, 0.0973f)));
    let _e25 = p3_7;
    let _e26 = p3_7;
    let _e27 = p3_7;
    p3_7 = (_e25 + vec3(dot(_e26, (_e27.yxz + vec3(33.33f)))));
    let _e36 = p3_7;
    let _e38 = p3_7;
    let _e41 = p3_7;
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

fn u_op(a_4: Hit, b_4: Hit) -> Hit {
    var a_5: Hit;
    var b_5: Hit;

    a_5 = a_4;
    b_5 = b_4;
    let _e20 = a_5;
    let _e22 = b_5;
    if (_e20.d < _e22.d) {
        let _e25 = a_5;
        return _e25;
    } else {
        let _e26 = b_5;
        return _e26;
    }
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

fn value_noise(p_20: vec3<f32>) -> f32 {
    var p_21: vec3<f32>;
    var id: vec3<f32>;
    var lp: vec3<f32>;
    var n000_: f32;
    var n100_: f32;
    var n010_: f32;
    var n110_: f32;
    var n001_: f32;
    var n101_: f32;
    var n011_: f32;
    var n111_: f32;

    p_21 = p_20;
    let _e18 = p_21;
    id = floor(_e18);
    let _e21 = p_21;
    lp = fract(_e21);
    let _e26 = lp;
    let _e27 = smootherstep(0f, 1f, _e26);
    lp = _e27;
    let _e28 = id;
    let _e29 = hash31_(_e28);
    n000_ = _e29;
    let _e31 = id;
    let _e37 = hash31_((_e31 + vec3<f32>(1f, 0f, 0f)));
    n100_ = _e37;
    let _e39 = id;
    let _e45 = hash31_((_e39 + vec3<f32>(0f, 1f, 0f)));
    n010_ = _e45;
    let _e47 = id;
    let _e53 = hash31_((_e47 + vec3<f32>(1f, 1f, 0f)));
    n110_ = _e53;
    let _e55 = id;
    let _e61 = hash31_((_e55 + vec3<f32>(0f, 0f, 1f)));
    n001_ = _e61;
    let _e63 = id;
    let _e69 = hash31_((_e63 + vec3<f32>(1f, 0f, 1f)));
    n101_ = _e69;
    let _e71 = id;
    let _e77 = hash31_((_e71 + vec3<f32>(0f, 1f, 1f)));
    n011_ = _e77;
    let _e79 = id;
    let _e85 = hash31_((_e79 + vec3<f32>(1f, 1f, 1f)));
    n111_ = _e85;
    let _e87 = n000_;
    let _e88 = n100_;
    let _e89 = lp;
    let _e92 = n010_;
    let _e93 = n110_;
    let _e94 = lp;
    let _e97 = lp;
    let _e100 = n001_;
    let _e101 = n101_;
    let _e102 = lp;
    let _e105 = n011_;
    let _e106 = n111_;
    let _e107 = lp;
    let _e110 = lp;
    let _e113 = lp;
    return mix(mix(mix(_e87, _e88, _e89.x), mix(_e92, _e93, _e94.x), _e97.y), mix(mix(_e100, _e101, _e102.x), mix(_e105, _e106, _e107.x), _e110.y), _e113.z);
}

fn noise_gradient(p_22: vec2<f32>) -> f32 {
    var p_23: vec2<f32>;
    var i: vec2<f32>;
    var f: vec2<f32>;
    var u: vec2<f32>;
    var g00_: vec2<f32>;
    var g10_: vec2<f32>;
    var g01_: vec2<f32>;
    var g11_: vec2<f32>;
    var d00_: f32;
    var d10_: f32;
    var d01_: f32;
    var d11_: f32;
    var x0_: f32;
    var x1_: f32;
    var n_4: f32;

    p_23 = p_22;
    let _e18 = p_23;
    i = floor(_e18);
    let _e21 = p_23;
    f = fract(_e21);
    let _e24 = f;
    let _e25 = f;
    let _e27 = f;
    let _e29 = f;
    let _e30 = f;
    u = (((_e24 * _e25) * _e27) * ((_e29 * ((_e30 * 6f) - vec2(15f))) + vec2(10f)));
    let _e42 = i;
    let _e47 = hash22_((_e42 + vec2<f32>(0f, 0f)));
    g00_ = _e47;
    let _e49 = i;
    let _e54 = hash22_((_e49 + vec2<f32>(1f, 0f)));
    g10_ = _e54;
    let _e56 = i;
    let _e61 = hash22_((_e56 + vec2<f32>(0f, 1f)));
    g01_ = _e61;
    let _e63 = i;
    let _e68 = hash22_((_e63 + vec2<f32>(1f, 1f)));
    g11_ = _e68;
    let _e70 = g00_;
    let _e71 = f;
    d00_ = dot(_e70, (_e71 - vec2<f32>(0f, 0f)));
    let _e78 = g10_;
    let _e79 = f;
    d10_ = dot(_e78, (_e79 - vec2<f32>(1f, 0f)));
    let _e86 = g01_;
    let _e87 = f;
    d01_ = dot(_e86, (_e87 - vec2<f32>(0f, 1f)));
    let _e94 = g11_;
    let _e95 = f;
    d11_ = dot(_e94, (_e95 - vec2<f32>(1f, 1f)));
    let _e102 = d00_;
    let _e103 = d10_;
    let _e104 = u;
    x0_ = mix(_e102, _e103, _e104.x);
    let _e108 = d01_;
    let _e109 = d11_;
    let _e110 = u;
    x1_ = mix(_e108, _e109, _e110.x);
    let _e114 = x0_;
    let _e115 = x1_;
    let _e116 = u;
    n_4 = mix(_e114, _e115, _e116.y);
    let _e120 = n_4;
    return _e120;
}

fn fbm(p_24: vec2<f32>, octaves: i32) -> f32 {
    var p_25: vec2<f32>;
    var octaves_1: i32;
    var n_5: f32 = 0f;
    var freq: f32 = 1f;
    var amp: f32 = 1f;
    var amp_max: f32 = 0f;
    var dfreq: f32 = 2f;
    var damp: f32 = 0.5f;
    var i_1: i32 = 0i;

    p_25 = p_24;
    octaves_1 = octaves;
    loop {
        let _e34 = i_1;
        let _e35 = octaves_1;
        if !((_e34 < _e35)) {
            break;
        }
        {
            let _e41 = n_5;
            let _e42 = freq;
            let _e43 = p_25;
            let _e45 = noise_gradient((_e42 * _e43));
            let _e46 = amp;
            n_5 = (_e41 + (_e45 * _e46));
            let _e49 = amp_max;
            let _e50 = amp;
            amp_max = (_e49 + _e50);
            let _e52 = freq;
            let _e53 = dfreq;
            freq = (_e52 * _e53);
            let _e55 = amp;
            let _e56 = damp;
            amp = (_e55 * _e56);
        }
        continuing {
            let _e38 = i_1;
            i_1 = (_e38 + 1i);
        }
    }
    let _e58 = n_5;
    let _e59 = amp_max;
    return (_e58 / _e59);
}

fn get_portal(world: i32) -> mat2x3<f32> {
    var world_1: i32;
    var pos: vec3<f32>;
    var n_6: vec3<f32>;

    world_1 = world;
    let _e20 = world_1;
    if (_e20 == 2i) {
        {
            pos = vec3<f32>(10f, 4f, 0f);
            n_6 = vec3<f32>(-1f, 0f, 0f);
        }
    } else {
        let _e32 = world_1;
        if (_e32 == 1i) {
            {
                pos = vec3<f32>(3.09017f, 4f, 9.51057f);
                n_6 = vec3<f32>(-0.309017f, 0f, -0.951057f);
            }
        } else {
            let _e45 = world_1;
            if (_e45 == 3i) {
                {
                    pos = vec3<f32>(-8.09017f, 4f, 5.87785f);
                    n_6 = vec3<f32>(0.809017f, 0f, -0.587785f);
                }
            } else {
                let _e58 = world_1;
                if (_e58 == 4i) {
                    {
                        pos = vec3<f32>(-8.09017f, 4f, -5.87785f);
                        n_6 = vec3<f32>(0.809017f, 0f, 0.587785f);
                    }
                } else {
                    let _e71 = world_1;
                    if (_e71 == 5i) {
                        {
                            pos = vec3<f32>(3.09017f, 4f, -9.51057f);
                            n_6 = vec3<f32>(-0.309017f, 0f, 0.951057f);
                        }
                    } else {
                        {
                            pos = vec3(0f);
                            n_6 = vec3<f32>(0f, 0f, 1f);
                        }
                    }
                }
            }
        }
    }
    let _e90 = pos;
    let _e91 = n_6;
    return mat2x3<f32>(vec3<f32>(_e90.x, _e90.y, _e90.z), vec3<f32>(_e91.x, _e91.y, _e91.z));
}

fn portal_entered(world_2: i32) -> bool {
    var world_3: i32;
    var portal: mat2x3<f32>;
    var pos_1: vec3<f32>;
    var n_7: vec3<f32>;
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
    var w2_: f32 = 5.29f;
    var h2_: f32 = 13.690001f;
    var intersects_xy: bool;

    world_3 = world_2;
    let _e18 = world_3;
    let _e19 = get_portal(_e18);
    portal = _e19;
    let _e23 = portal[0];
    pos_1 = _e23;
    let _e27 = portal[1];
    n_7 = _e27;
    let _e29 = u_1;
    let _e32 = pos_1;
    cam_pos_relative = (_e29.camera.pos - _e32);
    let _e35 = u_1;
    let _e37 = pos_1;
    cam_pos_relative_prev = (_e35.camera_pos_prev - _e37);
    let _e40 = cam_pos_relative;
    let _e41 = n_7;
    z = dot(_e40, _e41);
    let _e44 = cam_pos_relative_prev;
    let _e45 = n_7;
    z_prev = dot(_e44, _e45);
    let _e48 = z;
    let _e50 = z_prev;
    if (sign(_e48) != sign(_e50)) {
        {
            let _e58 = up_1;
            let _e59 = n_7;
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
            let _e87 = x2_;
            let _e88 = w2_;
            let _e90 = y2_;
            let _e91 = h2_;
            intersects_xy = (((_e87 / _e88) + (_e90 / _e91)) <= 1f);
            let _e97 = intersects_xy;
            return _e97;
        }
    }
    return false;
}

fn h_portal(p_26: vec3<f32>, world_src: i32, world_dst: i32) -> Hit {
    var p_27: vec3<f32>;
    var world_src_1: i32;
    var world_dst_1: i32;
    var portal_1: mat2x3<f32>;
    var n_dir: f32 = 1f;
    var portal_pos: vec3<f32>;
    var portal_n: vec3<f32>;
    var q_1: vec3<f32>;
    var d_2: f32;
    var m: Material = Material(1i, vec3(1f), 0f, 0f);

    p_27 = p_26;
    world_src_1 = world_src;
    world_dst_1 = world_dst;
    let _e25 = world_src_1;
    if (_e25 == 0i) {
        let _e28 = world_dst_1;
        let _e29 = get_portal(_e28);
        portal_1 = _e29;
    } else {
        {
            let _e30 = world_src_1;
            let _e31 = get_portal(_e30);
            portal_1 = _e31;
            let _e32 = n_dir;
            n_dir = (_e32 * -1f);
        }
    }
    let _e38 = portal_1[0];
    portal_pos = _e38;
    let _e40 = n_dir;
    let _e43 = portal_1[1];
    portal_n = (_e40 * _e43);
    let _e46 = p_27;
    let _e47 = portal_pos;
    q_1 = (_e46 - _e47);
    let _e50 = q_1;
    let _e51 = portal_n;
    let _e52 = sd_portal(_e50, _e51);
    d_2 = _e52;
    let _e61 = d_2;
    let _e62 = m;
    let _e63 = world_dst_1;
    return Hit(_e61, _e62, _e63);
}

fn get_world() -> i32 {
    var i_2: i32 = 0i;
    var local: array<i32, 5> = SUB_WORLDS;
    var world_4: i32;

    let _e16 = global.world_global;
    if (_e16 == 0i) {
        {
            loop {
                let _e21 = i_2;
                if !((_e21 < 5i)) {
                    break;
                }
                {
                    let _e28 = i_2;
                    let _e32 = local[_e28];
                    world_4 = _e32;
                    let _e34 = world_4;
                    let _e35 = portal_entered(_e34);
                    if _e35 {
                        let _e36 = world_4;
                        return _e36;
                    }
                }
                continuing {
                    let _e25 = i_2;
                    i_2 = (_e25 + 1i);
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

fn map_hub_s(p_28: vec3<f32>) -> Hit {
    var p_29: vec3<f32>;
    var hit: Hit;

    p_29 = p_28;
    hit.world_target = 0i;
    hit.d = 100000000f;
    hit.material = Material(0i, vec3(1f), 0f, 0f);
    let _e30 = hit;
    return _e30;
}

fn map_hub_p(p_30: vec3<f32>) -> Hit {
    var p_31: vec3<f32>;
    var hit_1: Hit;
    var i_3: i32 = 0i;
    var local_1: array<i32, 5> = SUB_WORLDS;
    var world_7: i32;
    var h: Hit;

    p_31 = p_30;
    let _e18 = p_31;
    let _e19 = map_hub_s(_e18);
    hit_1 = _e19;
    loop {
        let _e23 = i_3;
        if !((_e23 < 5i)) {
            break;
        }
        {
            let _e30 = i_3;
            let _e34 = local_1[_e30];
            world_7 = _e34;
            let _e36 = p_31;
            let _e38 = world_7;
            let _e39 = h_portal(_e36, 0i, _e38);
            h = _e39;
            let _e41 = hit_1;
            let _e42 = h;
            let _e43 = u_op(_e41, _e42);
            hit_1 = _e43;
        }
        continuing {
            let _e27 = i_3;
            i_3 = (_e27 + 1i);
        }
    }
    let _e44 = hit_1;
    return _e44;
}

fn map_fractal_s(p_32: vec3<f32>) -> Hit {
    var p_33: vec3<f32>;
    var portal_2: mat2x3<f32>;
    var portal_pos_1: vec3<f32>;
    var portal_n_1: vec3<f32>;
    var up_2: vec3<f32> = vec3<f32>(0f, 1f, 0f);
    var forward: vec3<f32>;
    var right_2: vec3<f32>;
    var q_2: vec3<f32>;
    var hit_2: Hit;
    var q_3: vec3<f32>;
    var s_1: f32 = 11f;
    var id_1: vec2<f32>;
    var d_bound: f32;
    var rot_xz: mat2x2<f32>;
    var rot_xy: mat2x2<f32>;
    var scale: f32 = 2f;
    var scaled: f32 = 1f;
    var trap: vec4<f32> = vec4(10000000000f);
    var i_4: i32 = 0i;
    var d_3: f32;
    var color: vec3<f32>;
    var m_1: Material;

    p_33 = p_32;
    let _e19 = get_portal(1i);
    portal_2 = _e19;
    let _e23 = portal_2[0];
    portal_pos_1 = _e23;
    let _e27 = portal_2[1];
    portal_n_1 = _e27;
    let _e34 = portal_n_1;
    forward = _e34;
    let _e36 = up_2;
    let _e37 = forward;
    right_2 = normalize(cross(_e36, _e37));
    let _e41 = p_33;
    let _e42 = right_2;
    let _e44 = p_33;
    let _e45 = up_2;
    let _e47 = p_33;
    let _e48 = forward;
    q_2 = vec3<f32>(dot(_e41, _e42), dot(_e44, _e45), dot(_e47, _e48));
    hit_2.world_target = -1i;
    {
        let _e57 = q_2;
        let _e62 = sd_plane(_e57, vec3<f32>(0f, 1f, 0f));
        hit_2.d = _e62;
        hit_2.material = Material(0i, vec3<f32>(1f, 0f, 0f), 0f, 0f);
    }
    {
        let _e72 = q_2;
        let _e77 = u_1;
        q_3 = (_e72 - vec3<f32>(0f, (3.5f + (0.35f * sin((0.8f * _e77.t)))), -18f));
        let _e90 = q_3;
        let _e92 = s_1;
        id_1 = round((_e90.xy / vec2(_e92)));
        let _e97 = id_1;
        let _e102 = id_1;
        if ((_e97.y < 0f) || (_e102.y > 10f)) {
            let _e108 = hit_2;
            return _e108;
        }
        let _e109 = q_3;
        let _e111 = q_3;
        let _e113 = s_1;
        let _e114 = id_1;
        let _e117 = (_e111.xy - (_e113 * round(_e114)));
        q_3.x = _e117.x;
        q_3.y = _e117.y;
        let _e122 = q_3;
        let _e124 = q_3;
        let _e127 = u_1;
        let _e130 = rotate_2d((0.1f * _e127.t));
        let _e131 = (_e124.xz * _e130);
        q_3.x = _e131.x;
        q_3.z = _e131.y;
        let _e136 = q_3;
        let _e138 = q_3;
        let _e141 = u_1;
        let _e144 = rotate_2d((0.05f * _e141.t));
        let _e145 = (_e138.yz * _e144);
        q_3.y = _e145.x;
        q_3.z = _e145.y;
        let _e150 = q_3;
        let _e152 = q_3;
        let _e155 = u_1;
        let _e159 = rotate_2d((0.05f * -(_e155.t)));
        let _e160 = (_e152.xz * _e159);
        q_3.x = _e160.x;
        q_3.z = _e160.y;
        let _e165 = q_3;
        let _e167 = sd_sphere(_e165, 10f);
        d_bound = _e167;
        let _e169 = d_bound;
        if (_e169 > 1f) {
            {
                let _e173 = hit_2;
                let _e175 = d_bound;
                hit_2.d = min(_e173.d, _e175);
            }
        } else {
            {
                let _e178 = u_1;
                let _e181 = rotate_2d((0.2f * _e178.t));
                rot_xz = _e181;
                let _e184 = u_1;
                let _e187 = rotate_2d((0.15f * _e184.t));
                rot_xy = _e187;
                loop {
                    let _e198 = i_4;
                    let _e199 = id_1;
                    if !((f32(_e198) < _e199.y)) {
                        break;
                    }
                    {
                        let _e207 = q_3;
                        q_3 = abs(_e207);
                        let _e209 = q_3;
                        q_3 = (_e209 - vec3<f32>(1f, 0.4f, 0.7f));
                        let _e215 = q_3;
                        let _e217 = q_3;
                        let _e219 = rot_xz;
                        let _e220 = (_e217.xz * _e219);
                        q_3.x = _e220.x;
                        q_3.z = _e220.y;
                        let _e225 = q_3;
                        let _e227 = q_3;
                        let _e229 = rot_xy;
                        let _e230 = (_e227.xy * _e229);
                        q_3.x = _e230.x;
                        q_3.y = _e230.y;
                        let _e235 = q_3;
                        let _e236 = scale;
                        q_3 = (_e235 * (_e236 * 0.8f));
                        let _e240 = scaled;
                        let _e241 = scale;
                        scaled = (_e240 * _e241);
                        let _e243 = trap;
                        let _e244 = q_3;
                        let _e245 = abs(_e244);
                        let _e246 = q_3;
                        trap = min(_e243, vec4<f32>(_e245.x, _e245.y, _e245.z, length(_e246)));
                    }
                    continuing {
                        let _e204 = i_4;
                        i_4 = (_e204 + 1i);
                    }
                }
                let _e253 = q_3;
                let _e258 = sd_box(_e253, vec3<f32>(1f, 1.2f, 1f));
                d_3 = _e258;
                let _e260 = d_3;
                let _e261 = scaled;
                d_3 = (_e260 / _e261);
                let _e263 = trap;
                let _e277 = palette((_e263.z * 4f), vec3(0.5f), vec3(0.5f), vec3(1f), vec3<f32>(0f, 0.1f, 0.2f));
                color = _e277;
                let _e280 = color;
                m_1 = Material(0i, _e280, 0.4f, 1f);
                let _e285 = hit_2;
                let _e286 = d_3;
                let _e287 = m_1;
                let _e291 = u_op(_e285, Hit(_e286, _e287, -1i));
                hit_2 = _e291;
            }
        }
    }
    let _e292 = hit_2;
    return _e292;
}

fn map_fractal_p(p_34: vec3<f32>) -> Hit {
    var p_35: vec3<f32>;
    var hit_3: Hit;

    p_35 = p_34;
    let _e18 = p_35;
    let _e19 = map_fractal_s(_e18);
    hit_3 = _e19;
    let _e21 = hit_3;
    let _e22 = p_35;
    let _e25 = h_portal(_e22, 1i, 0i);
    let _e26 = u_op(_e21, _e25);
    hit_3 = _e26;
    let _e27 = hit_3;
    return _e27;
}

fn precalculate_blobs() {
    var world_height: f32 = 20f;
    var y_1: f32;
    var r_blob: f32 = 3.5f;
    var i_5: i32 = 0i;
    var rand: vec3<f32>;
    var r_blub_amp: f32;
    var s_2: f32;
    var y2_1: f32;
    var x_4: f32;
    var z_1: f32;

    let _e20 = world_height;
    let _e23 = world_height;
    let _e29 = u_1;
    let _e31 = hash(_e29.t_start);
    let _e33 = u_1;
    y_1 = ((_e20 / 2f) + ((_e23 * 0.7f) * sin(((6.2831855f * _e31) + (_e33.t * 0.6f)))));
    let _e43 = y_1;
    y_1 = (5f + (_e43 * 0.65f));
    loop {
        let _e51 = i_5;
        if !((_e51 < 4i)) {
            break;
        }
        {
            let _e58 = u_1;
            let _e60 = i_5;
            let _e63 = hash23_(vec2<f32>(_e58.t_start, f32(_e60)));
            rand = _e63;
            let _e65 = r_blob;
            r_blub_amp = ((_e65 * 0.5f) * 1.5f);
            let _e71 = i_5;
            let _e73 = r_blob;
            let _e76 = rand;
            g_blub_r[_e71] = ((_e73 * 0.5f) * (_e76.x + 0.5f));
            let _e82 = r_blob;
            s_2 = (1.2f * _e82);
            let _e85 = y_1;
            let _e86 = s_2;
            let _e90 = rand;
            let _e93 = u_1;
            let _e96 = rand;
            y2_1 = (_e85 + (_e86 * sin(((6.2831855f * _e90.y) + (_e93.t * (1.5f + _e96.y))))));
            let _e105 = s_2;
            let _e109 = rand;
            let _e112 = u_1;
            let _e115 = rand;
            x_4 = (_e105 * sin(((6.2831855f * _e109.x) + (_e112.t * (1.5f + _e115.x)))));
            let _e123 = s_2;
            let _e127 = rand;
            let _e130 = u_1;
            let _e133 = rand;
            z_1 = (_e123 * sin(((6.2831855f * _e127.z) + (_e130.t * (1.5f + _e133.z)))));
            let _e141 = i_5;
            let _e143 = x_4;
            let _e144 = y2_1;
            let _e145 = z_1;
            g_blub_pos[_e141] = vec3<f32>(_e143, _e144, _e145);
        }
        continuing {
            let _e55 = i_5;
            i_5 = (_e55 + 1i);
        }
    }
    return;
}

fn map_lavalamp_s(p_36: vec3<f32>) -> Hit {
    var p_37: vec3<f32>;
    var hit_4: Hit;
    var world_height_1: f32 = 20f;
    var q_4: vec3<f32>;
    var d_4: f32;
    var m_2: Material = Material(0i, vec3<f32>(1f, 0f, 0f), 0f, 0f);
    var q_5: vec3<f32>;
    var y_2: f32;
    var q_blob: vec3<f32>;
    var r_blob_1: f32 = 3.5f;
    var d_5: f32;
    var i_6: i32 = 0i;
    var q_blub: vec3<f32>;
    var r_4: f32;
    var d2_: f32;
    var color_1: vec3<f32>;
    var m_3: Material;

    p_37 = p_36;
    hit_4.world_target = -1i;
    let _e27 = p_37;
    p_37.y = (_e27.y + 4f);
    let _e32 = p_37;
    p_37.x = (_e32.x - 35f);
    {
        let _e37 = p_37;
        let _e42 = sd_plane(_e37, vec3<f32>(0f, 1f, 0f));
        hit_4.d = _e42;
        hit_4.material = Material(0i, vec3<f32>(0f, 0f, 1f), 0f, 0f);
    }
    {
        let _e52 = p_37;
        let _e54 = world_height_1;
        q_4 = (_e52 - vec3<f32>(0f, _e54, 0f));
        let _e59 = q_4;
        let _e65 = sd_plane(_e59, vec3<f32>(0f, -1f, 0f));
        d_4 = _e65;
        let _e76 = hit_4;
        let _e77 = d_4;
        let _e78 = m_2;
        let _e81 = u_op(_e76, Hit(_e77, _e78, 2i));
        hit_4 = _e81;
    }
    {
        let _e82 = p_37;
        q_5 = _e82;
        let _e84 = world_height_1;
        let _e87 = world_height_1;
        let _e93 = u_1;
        let _e95 = hash(_e93.t_start);
        let _e97 = u_1;
        y_2 = ((_e84 / 2f) + ((_e87 * 0.7f) * sin(((6.2831855f * _e95) + (_e97.t * 0.6f)))));
        let _e107 = y_2;
        y_2 = (5f + (_e107 * 0.65f));
        let _e111 = q_5;
        let _e113 = y_2;
        q_blob = (_e111 - vec3<f32>(0f, _e113, 0f));
        let _e120 = q_blob;
        let _e121 = r_blob_1;
        let _e122 = sd_sphere(_e120, _e121);
        d_5 = _e122;
        let _e124 = d_5;
        let _e125 = hit_4;
        let _e128 = smin(_e124, _e125.d, 0.5f);
        d_5 = _e128;
        loop {
            let _e131 = i_6;
            if !((_e131 < 4i)) {
                break;
            }
            {
                let _e138 = q_5;
                let _e139 = i_6;
                let _e141 = g_blub_pos[_e139];
                q_blub = (_e138 - _e141);
                let _e144 = i_6;
                let _e146 = g_blub_r[_e144];
                r_4 = _e146;
                let _e148 = q_blub;
                let _e149 = r_4;
                let _e150 = sd_sphere(_e148, _e149);
                d2_ = _e150;
                let _e152 = d_5;
                let _e153 = d2_;
                let _e156 = r_4;
                let _e161 = smin(_e152, _e153, (1.5f - ((0.8f * _e156) / 5f)));
                d_5 = _e161;
            }
            continuing {
                let _e135 = i_6;
                i_6 = (_e135 + 1i);
            }
        }
        let _e162 = p_37;
        let _e164 = world_height_1;
        let _e167 = u_1;
        let _e181 = palette(((_e162.y / _e164) + (0.1f * _e167.t)), vec3(0.5f), vec3(0.5f), vec3(1f), vec3<f32>(0f, 0.33f, 0.67f));
        color_1 = _e181;
        let _e184 = color_1;
        m_3 = Material(0i, _e184, 0.2f, 0.8f);
        let _e189 = hit_4;
        let _e190 = d_5;
        let _e191 = m_3;
        let _e194 = u_op(_e189, Hit(_e190, _e191, 2i));
        hit_4 = _e194;
    }
    let _e195 = hit_4;
    return _e195;
}

fn map_lavalamp_p(p_38: vec3<f32>) -> Hit {
    var p_39: vec3<f32>;
    var hit_5: Hit;

    p_39 = p_38;
    let _e20 = p_39;
    let _e21 = map_lavalamp_s(_e20);
    hit_5 = _e21;
    let _e23 = hit_5;
    let _e24 = p_39;
    let _e27 = h_portal(_e24, 2i, 0i);
    let _e28 = u_op(_e23, _e27);
    hit_5 = _e28;
    let _e29 = hit_5;
    return _e29;
}

fn map_mountain_s(p_40: vec3<f32>) -> Hit {
    var p_41: vec3<f32>;
    var hit_6: Hit;
    var amp_1: f32 = 50f;
    var offset: vec2<f32>;
    var octaves_2: i32;
    var h_1: f32;

    p_41 = p_40;
    hit_6.world_target = -1i;
    hit_6.material = Material(0i, vec3<f32>(1f, 0.1f, 0.1f), 0.9f, 0.2f);
    let _e34 = p_41;
    p_41.y = (_e34.y + 30f);
    let _e41 = p_41;
    let _e43 = amp_1;
    if (_e41.y > (_e43 + 5f)) {
        {
            let _e48 = p_41;
            let _e50 = amp_1;
            hit_6.d = ((_e48.y - _e50) + 5f);
            let _e54 = hit_6;
            return _e54;
        }
    }
    let _e55 = u_1;
    let _e57 = hash12_(_e55.t_start);
    offset = _e57;
    let _e60 = p_41;
    let _e61 = u_1;
    octaves_2 = i32((6f - floor((length((_e60 - _e61.camera.pos)) / 60f))));
    let _e72 = offset;
    let _e73 = p_41;
    let _e78 = octaves_2;
    let _e79 = fbm((_e72 + (_e73.xz * 0.02f)), _e78);
    h_1 = _e79;
    let _e81 = h_1;
    h_1 = (_e81 * 50f);
    let _e85 = p_41;
    let _e87 = h_1;
    hit_6.d = (_e85.y - _e87);
    let _e90 = hit_6;
    hit_6.d = (_e90.d * 0.2f);
    let _e94 = hit_6;
    return _e94;
}

fn map_mountain_p(p_42: vec3<f32>) -> Hit {
    var p_43: vec3<f32>;
    var hit_7: Hit;

    p_43 = p_42;
    let _e20 = p_43;
    let _e21 = map_mountain_s(_e20);
    hit_7 = _e21;
    let _e23 = hit_7;
    let _e24 = p_43;
    let _e27 = h_portal(_e24, 3i, 0i);
    let _e28 = u_op(_e23, _e27);
    hit_7 = _e28;
    let _e29 = hit_7;
    return _e29;
}

fn map_water_s(p_44: vec3<f32>) -> Hit {
    var p_45: vec3<f32>;
    var hit_8: Hit;
    var q_6: vec3<f32>;
    var h_2: f32;

    p_45 = p_44;
    hit_8.world_target = -1i;
    let _e24 = p_45;
    q_6 = (_e24 + vec3(20f));
    let _e31 = q_6;
    let _e34 = u_1;
    h_2 = (3f * sin(((0.3f * _e31.x) + _e34.t)));
    let _e41 = q_6;
    let _e43 = h_2;
    hit_8.d = (_e41.y - _e43);
    let _e46 = hit_8;
    hit_8.d = (_e46.d * 0.4f);
    hit_8.material = Material(0i, vec3<f32>(0f, 0f, 1f), 0f, 0f);
    let _e59 = hit_8;
    return _e59;
}

fn map_water_p(p_46: vec3<f32>) -> Hit {
    var p_47: vec3<f32>;
    var hit_9: Hit;

    p_47 = p_46;
    let _e20 = p_47;
    let _e21 = map_water_s(_e20);
    hit_9 = _e21;
    let _e23 = hit_9;
    let _e24 = p_47;
    let _e27 = h_portal(_e24, 4i, 0i);
    let _e28 = u_op(_e23, _e27);
    hit_9 = _e28;
    let _e29 = hit_9;
    return _e29;
}

fn map_cloud_s(p_48: vec3<f32>) -> Hit {
    var p_49: vec3<f32>;
    var hit_10: Hit;
    var q_7: vec3<f32>;
    var d_6: f32;

    p_49 = p_48;
    hit_10.world_target = -1i;
    {
        let _e24 = p_49;
        q_7 = (_e24 - vec3<f32>(15f, 10f, -30f));
        let _e32 = q_7;
        let _e34 = sd_sphere(_e32, 10f);
        let _e37 = q_7;
        let _e41 = q_7;
        let _e46 = q_7;
        let _e50 = u_1;
        d_6 = (_e34 + (0.2f * sin(((((5f * _e37.x) + (3f * _e41.z)) - (10f * _e46.y)) - _e50.t))));
        let _e58 = d_6;
        hit_10.d = (_e58 * 0.2f);
        hit_10.material = Material(0i, vec3(1f), 0f, 0f);
    }
    let _e68 = hit_10;
    return _e68;
}

fn map_cloud_p(p_50: vec3<f32>) -> Hit {
    var p_51: vec3<f32>;
    var hit_11: Hit;

    p_51 = p_50;
    let _e20 = p_51;
    let _e21 = map_cloud_s(_e20);
    hit_11 = _e21;
    let _e23 = hit_11;
    let _e24 = p_51;
    let _e27 = h_portal(_e24, 5i, 0i);
    let _e28 = u_op(_e23, _e27);
    hit_11 = _e28;
    let _e29 = hit_11;
    return _e29;
}

fn map_secondary(p_52: vec3<f32>) -> Hit {
    var p_53: vec3<f32>;

    p_53 = p_52;
    let _e20 = world_ray;
    if (_e20 == 0i) {
        let _e23 = p_53;
        let _e24 = map_hub_s(_e23);
        return _e24;
    } else {
        let _e25 = world_ray;
        if (_e25 == 1i) {
            let _e28 = p_53;
            let _e29 = map_fractal_s(_e28);
            return _e29;
        } else {
            let _e30 = world_ray;
            if (_e30 == 2i) {
                let _e33 = p_53;
                let _e34 = map_lavalamp_s(_e33);
                return _e34;
            } else {
                let _e35 = world_ray;
                if (_e35 == 3i) {
                    let _e38 = p_53;
                    let _e39 = map_mountain_s(_e38);
                    return _e39;
                } else {
                    let _e40 = world_ray;
                    if (_e40 == 4i) {
                        let _e43 = p_53;
                        let _e44 = map_water_s(_e43);
                        return _e44;
                    } else {
                        let _e45 = world_ray;
                        if (_e45 == 5i) {
                            let _e48 = p_53;
                            let _e49 = map_cloud_s(_e48);
                            return _e49;
                        } else {
                            return Hit(0f, Material(0i, vec3<f32>(1f, 0f, 1f), 0f, 0f), -1i);
                        }
                    }
                }
            }
        }
    }
}

fn map_primary(p_54: vec3<f32>) -> Hit {
    var p_55: vec3<f32>;

    p_55 = p_54;
    let _e20 = world_ray;
    if (_e20 == 0i) {
        let _e23 = p_55;
        let _e24 = map_hub_p(_e23);
        return _e24;
    } else {
        let _e25 = world_ray;
        if (_e25 == 1i) {
            let _e28 = p_55;
            let _e29 = map_fractal_p(_e28);
            return _e29;
        } else {
            let _e30 = world_ray;
            if (_e30 == 2i) {
                let _e33 = p_55;
                let _e34 = map_lavalamp_p(_e33);
                return _e34;
            } else {
                let _e35 = world_ray;
                if (_e35 == 3i) {
                    let _e38 = p_55;
                    let _e39 = map_mountain_p(_e38);
                    return _e39;
                } else {
                    let _e40 = world_ray;
                    if (_e40 == 4i) {
                        let _e43 = p_55;
                        let _e44 = map_water_p(_e43);
                        return _e44;
                    } else {
                        let _e45 = world_ray;
                        if (_e45 == 5i) {
                            let _e48 = p_55;
                            let _e49 = map_cloud_p(_e48);
                            return _e49;
                        } else {
                            return Hit(0f, Material(0i, vec3<f32>(1f, 0f, 1f), 0f, 0f), -1i);
                        }
                    }
                }
            }
        }
    }
}

fn heightmap_mountain(p_56: vec2<f32>) -> Hit {
    var p_57: vec2<f32>;
    var offset_1: vec2<f32>;
    var h_3: f32;
    var m_4: Material = Material(0i, vec3<f32>(0.8f, 0.3f, 0.4f), 0.8f, 0.2f);

    p_57 = p_56;
    let _e20 = u_1;
    let _e22 = hash12_(_e20.t_start);
    offset_1 = _e22;
    let _e24 = offset_1;
    let _e25 = p_57;
    let _e30 = fbm((_e24 + (_e25 * 0.02f)), 5i);
    h_3 = _e30;
    let _e32 = h_3;
    h_3 = (_e32 * 50f);
    let _e44 = h_3;
    let _e45 = m_4;
    return Hit(_e44, _e45, 3i);
}

fn heightmap(p_58: vec2<f32>) -> Hit {
    var p_59: vec2<f32>;

    p_59 = p_58;
    let _e20 = world_ray;
    if (_e20 == 3i) {
        let _e23 = p_59;
        let _e24 = heightmap_mountain(_e23);
        return _e24;
    }
    return Hit(0f, Material(0i, vec3<f32>(1f, 0f, 1f), 0f, 0f), -1i);
}

fn march_sdf(ro: vec3<f32>, rd: vec3<f32>) -> Hit {
    var ro_1: vec3<f32>;
    var rd_1: vec3<f32>;
    var d_7: f32 = 0f;
    var material: Material;
    var world_target: i32;
    var i_7: i32 = 0i;
    var p_60: vec3<f32>;
    var hit_12: Hit;

    ro_1 = ro;
    rd_1 = rd;
    loop {
        let _e28 = i_7;
        if !((_e28 < 256i)) {
            break;
        }
        {
            let _e35 = ro_1;
            let _e36 = rd_1;
            let _e37 = d_7;
            p_60 = (_e35 + (_e36 * _e37));
            let _e41 = p_60;
            let _e42 = map_primary(_e41);
            hit_12 = _e42;
            let _e44 = hit_12;
            material = _e44.material;
            let _e46 = hit_12;
            world_target = _e46.world_target;
            let _e48 = d_7;
            let _e49 = hit_12;
            d_7 = (_e48 + _e49.d);
            let _e52 = hit_12;
            if (abs(_e52.d) < 0.0001f) {
                {
                    break;
                }
            }
            let _e57 = d_7;
            if (_e57 > 150f) {
                {
                    return Hit(100000000f, Material(0i, vec3(1f), 0f, 0f), -1i);
                }
            }
        }
        continuing {
            let _e32 = i_7;
            i_7 = (_e32 + 1i);
        }
    }
    let _e71 = d_7;
    let _e72 = material;
    let _e73 = world_target;
    return Hit(_e71, _e72, _e73);
}

fn march_terrain(ro_2: vec3<f32>, rd_2: vec3<f32>) -> Hit {
    var ro_3: vec3<f32>;
    var rd_3: vec3<f32>;
    var d_8: f32 = 0f;
    var hit_13: Hit;
    var i_8: i32 = 0i;
    var step_: f32;
    var p_61: vec3<f32>;
    var height: f32;

    ro_3 = ro_2;
    rd_3 = rd_2;
    loop {
        let _e27 = i_8;
        if !((_e27 < 256i)) {
            break;
        }
        {
            let _e35 = d_8;
            step_ = (0.5f + (_e35 * 0.1f));
            let _e40 = ro_3;
            let _e41 = rd_3;
            let _e42 = d_8;
            p_61 = (_e40 + (_e41 * _e42));
            let _e46 = world_ray;
            if (_e46 == 3i) {
                {
                    let _e49 = p_61;
                    let _e51 = heightmap_mountain(_e49.xz);
                    hit_13 = _e51;
                }
            }
            let _e52 = hit_13;
            height = _e52.d;
            let _e55 = p_61;
            let _e57 = height;
            if (_e55.y < _e57) {
                {
                    let _e60 = d_8;
                    hit_13.d = _e60;
                    let _e61 = hit_13;
                    return _e61;
                }
            }
            let _e62 = d_8;
            let _e63 = step_;
            d_8 = (_e62 + _e63);
            let _e65 = d_8;
            if (_e65 > 150f) {
                break;
            }
        }
        continuing {
            let _e31 = i_8;
            i_8 = (_e31 + 1i);
        }
    }
    return Hit(0f, Material(0i, vec3<f32>(1f, 0f, 1f), 0f, 0f), -1i);
}

fn march(ro_4: vec3<f32>, rd_4: vec3<f32>) -> Hit {
    var ro_5: vec3<f32>;
    var rd_5: vec3<f32>;
    var d_total: f32 = 0f;
    var hit_14: Hit = Hit(0f, Material(0i, vec3<f32>(1f, 0f, 1f), 0f, 0f), -1i);
    var ro_current: vec3<f32>;
    var n_8: vec3<f32>;
    var a_8: f32;

    ro_5 = ro_4;
    rd_5 = rd_4;
    loop {
        let _e37 = d_total;
        if !((_e37 < 150f)) {
            break;
        }
        {
            let _e42 = ro_5;
            let _e43 = rd_5;
            let _e44 = d_total;
            ro_current = (_e42 + (_e43 * _e44));
            let _e48 = world_ray;
            if (_e48 == 3i) {
                {
                    let _e51 = ro_current;
                    let _e52 = rd_5;
                    let _e53 = march_terrain(_e51, _e52);
                    hit_14 = _e53;
                }
            } else {
                {
                    let _e54 = ro_current;
                    let _e55 = rd_5;
                    let _e56 = march_sdf(_e54, _e55);
                    hit_14 = _e56;
                }
            }
            let _e57 = d_total;
            let _e58 = hit_14;
            d_total = (_e57 + _e58.d);
            let _e61 = hit_14;
            if (_e61.material.type_ == 1i) {
                {
                    let _e66 = hit_14;
                    world_ray = _e66.world_target;
                    let _e69 = world_ray;
                    let _e70 = get_portal(_e69);
                    n_8 = _e70[1];
                    let _e73 = n_8;
                    let _e74 = rd_5;
                    a_8 = max(abs(dot(_e73, _e74)), 0.00000001f);
                    let _e80 = d_total;
                    let _e82 = a_8;
                    d_total = (_e80 + (1f / _e82));
                    continue;
                }
            }
            break;
        }
    }
    let _e85 = d_total;
    let _e86 = hit_14;
    let _e88 = hit_14;
    return Hit(_e85, _e86.material, _e88.world_target);
}

fn normal(p_62: vec3<f32>) -> vec3<f32> {
    var p_63: vec3<f32>;
    var e: vec2<f32> = vec2<f32>(0.0001f, -0.0001f);

    p_63 = p_62;
    let _e30 = e;
    let _e32 = p_63;
    let _e33 = e;
    let _e36 = map_secondary((_e32 + _e33.xyy));
    let _e39 = e;
    let _e41 = p_63;
    let _e42 = e;
    let _e45 = map_secondary((_e41 + _e42.yyx));
    let _e49 = e;
    let _e51 = p_63;
    let _e52 = e;
    let _e55 = map_secondary((_e51 + _e52.yxy));
    let _e59 = e;
    let _e61 = p_63;
    let _e62 = e;
    let _e65 = map_secondary((_e61 + _e62.xxx));
    return normalize(((((_e30.xyy * _e36.d) + (_e39.yyx * _e45.d)) + (_e49.yxy * _e55.d)) + (_e59.xxx * _e65.d)));
}

fn shadow(ro_6: vec3<f32>, rd_6: vec3<f32>, d_max: f32) -> f32 {
    var ro_7: vec3<f32>;
    var rd_7: vec3<f32>;
    var d_max_1: f32;
    var d_9: f32 = 0.1f;
    var occlusion: f32 = 1f;
    var i_9: i32 = 0i;
    var p_64: vec3<f32>;
    var h_4: f32;

    ro_7 = ro_6;
    rd_7 = rd_6;
    d_max_1 = d_max;
    loop {
        let _e30 = i_9;
        let _e33 = d_9;
        let _e34 = d_max_1;
        if !(((_e30 < 256i) && (_e33 < _e34))) {
            break;
        }
        {
            let _e41 = ro_7;
            let _e42 = rd_7;
            let _e43 = d_9;
            p_64 = (_e41 + (_e42 * _e43));
            let _e47 = p_64;
            let _e48 = map_secondary(_e47);
            h_4 = _e48.d;
            let _e51 = h_4;
            if (_e51 < 0.001f) {
                return 0f;
            }
            let _e55 = occlusion;
            let _e57 = h_4;
            let _e59 = d_9;
            occlusion = min(_e55, ((64f * _e57) / _e59));
            let _e62 = d_9;
            let _e63 = h_4;
            d_9 = (_e62 + _e63);
        }
        continuing {
            let _e38 = i_9;
            i_9 = (_e38 + 1i);
        }
    }
    let _e65 = occlusion;
    return _e65;
}

fn ambient_occlusion(p_65: vec3<f32>, n_9: vec3<f32>) -> f32 {
    var p_66: vec3<f32>;
    var n_10: vec3<f32>;
    var scale_1: f32 = 1f;
    var occlusion_1: f32 = 0f;
    var i_10: i32 = 1i;
    var h_5: f32;
    var d_10: f32;

    p_66 = p_65;
    n_10 = n_9;
    loop {
        let _e28 = i_10;
        if !((_e28 <= 4i)) {
            break;
        }
        {
            let _e36 = i_10;
            h_5 = (0.04f * f32(_e36));
            let _e40 = p_66;
            let _e41 = h_5;
            let _e42 = n_10;
            let _e45 = map_secondary((_e40 + (_e41 * _e42)));
            d_10 = _e45.d;
            let _e48 = occlusion_1;
            let _e49 = h_5;
            let _e50 = d_10;
            let _e52 = scale_1;
            occlusion_1 = (_e48 + ((_e49 - _e50) * _e52));
            let _e55 = scale_1;
            scale_1 = (_e55 * 0.95f);
        }
        continuing {
            let _e32 = i_10;
            i_10 = (_e32 + 1i);
        }
    }
    let _e59 = occlusion_1;
    return (1f - clamp(_e59, 0f, 1f));
}

fn distribution(n_11: vec3<f32>, h_6: vec3<f32>, roughness: f32) -> f32 {
    var n_12: vec3<f32>;
    var h_7: vec3<f32>;
    var roughness_1: f32;
    var a_9: f32;
    var a2_: f32;
    var nh: f32;
    var nh2_: f32;
    var num: f32;
    var denom: f32;

    n_12 = n_11;
    h_7 = h_6;
    roughness_1 = roughness;
    let _e24 = roughness_1;
    let _e25 = roughness_1;
    a_9 = (_e24 * _e25);
    let _e28 = a_9;
    let _e29 = a_9;
    a2_ = (_e28 * _e29);
    let _e32 = n_12;
    let _e33 = h_7;
    nh = max(dot(_e32, _e33), 0f);
    let _e38 = nh;
    let _e39 = nh;
    nh2_ = (_e38 * _e39);
    let _e42 = a2_;
    num = _e42;
    let _e44 = nh2_;
    let _e45 = a2_;
    denom = ((_e44 * (_e45 - 1f)) + 1f);
    let _e53 = denom;
    let _e55 = denom;
    denom = ((3.1415927f * _e53) * _e55);
    let _e57 = num;
    let _e58 = denom;
    return (_e57 / _e58);
}

fn fresnel(v: vec3<f32>, h_8: vec3<f32>, f0_: vec3<f32>) -> vec3<f32> {
    var v_1: vec3<f32>;
    var h_9: vec3<f32>;
    var f0_1: vec3<f32>;
    var cos_theta: f32;

    v_1 = v;
    h_9 = h_8;
    f0_1 = f0_;
    let _e24 = v_1;
    let _e25 = h_9;
    cos_theta = max(dot(_e24, _e25), 0f);
    let _e30 = f0_1;
    let _e32 = f0_1;
    let _e36 = cos_theta;
    return (_e30 + ((vec3(1f) - _e32) * pow(clamp((1f - _e36), 0f, 1f), 5f)));
}

fn g1_(n_13: vec3<f32>, dir: vec3<f32>, roughness_2: f32) -> f32 {
    var n_14: vec3<f32>;
    var dir_1: vec3<f32>;
    var roughness_3: f32;
    var r_5: f32;
    var k_6: f32;
    var cos_theta_1: f32;
    var num_1: f32;
    var denom_1: f32;

    n_14 = n_13;
    dir_1 = dir;
    roughness_3 = roughness_2;
    let _e24 = roughness_3;
    r_5 = (_e24 + 1f);
    let _e28 = r_5;
    let _e29 = r_5;
    k_6 = ((_e28 * _e29) / 8f);
    let _e34 = n_14;
    let _e35 = dir_1;
    cos_theta_1 = max(dot(_e34, _e35), 0f);
    let _e40 = cos_theta_1;
    num_1 = _e40;
    let _e42 = cos_theta_1;
    let _e44 = k_6;
    let _e47 = k_6;
    denom_1 = ((_e42 * (1f - _e44)) + _e47);
    let _e50 = num_1;
    let _e51 = denom_1;
    return (_e50 / _e51);
}

fn geometry(n_15: vec3<f32>, v_2: vec3<f32>, l: vec3<f32>, roughness_4: f32) -> f32 {
    var n_16: vec3<f32>;
    var v_3: vec3<f32>;
    var l_1: vec3<f32>;
    var roughness_5: f32;
    var masking: f32;
    var shadowing: f32;

    n_16 = n_15;
    v_3 = v_2;
    l_1 = l;
    roughness_5 = roughness_4;
    let _e26 = n_16;
    let _e27 = v_3;
    let _e28 = roughness_5;
    let _e29 = g1_(_e26, _e27, _e28);
    masking = _e29;
    let _e31 = n_16;
    let _e32 = l_1;
    let _e33 = roughness_5;
    let _e34 = g1_(_e31, _e32, _e33);
    shadowing = _e34;
    let _e36 = masking;
    let _e37 = shadowing;
    return (_e36 * _e37);
}

fn lighting(p_67: vec3<f32>, n_17: vec3<f32>, v_4: vec3<f32>, light: Light, material_1: Material) -> vec3<f32> {
    var p_68: vec3<f32>;
    var n_18: vec3<f32>;
    var v_5: vec3<f32>;
    var light_1: Light;
    var material_2: Material;
    var l_2: vec3<f32>;
    var h_10: vec3<f32>;
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

    p_68 = p_67;
    n_18 = n_17;
    v_5 = v_4;
    light_1 = light;
    material_2 = material_1;
    let _e28 = light_1;
    let _e30 = p_68;
    l_2 = normalize((_e28.pos - _e30));
    let _e34 = v_5;
    let _e35 = l_2;
    h_10 = normalize((_e34 + _e35));
    let _e42 = f0_2;
    let _e43 = material_2;
    let _e45 = material_2;
    f0_2 = mix(_e42, _e43.albedo, vec3(_e45.metallic));
    let _e49 = light_1;
    let _e51 = p_68;
    distance_ = length((_e49.pos - _e51));
    let _e56 = distance_;
    let _e57 = distance_;
    attenuation = (1f / (_e56 * _e57));
    let _e61 = light_1;
    let _e63 = light_1;
    let _e66 = attenuation;
    radiance = ((_e61.color * _e63.strength) * _e66);
    let _e69 = n_18;
    let _e70 = h_10;
    let _e71 = material_2;
    let _e73 = distribution(_e69, _e70, _e71.roughness);
    D = _e73;
    let _e75 = n_18;
    let _e76 = v_5;
    let _e77 = l_2;
    let _e78 = material_2;
    let _e80 = geometry(_e75, _e76, _e77, _e78.roughness);
    G = _e80;
    let _e82 = v_5;
    let _e83 = h_10;
    let _e84 = f0_2;
    let _e85 = fresnel(_e82, _e83, _e84);
    F = _e85;
    let _e87 = D;
    let _e88 = G;
    let _e90 = F;
    num_2 = ((_e87 * _e88) * _e90);
    let _e94 = n_18;
    let _e95 = v_5;
    let _e100 = n_18;
    let _e101 = l_2;
    denom_2 = (((4f * max(dot(_e94, _e95), 0f)) * max(dot(_e100, _e101), 0f)) + 0.0001f);
    let _e109 = num_2;
    let _e110 = denom_2;
    specular = (_e109 / vec3(_e110));
    let _e114 = F;
    k_s = _e114;
    let _e118 = k_s;
    k_d = (vec3(1f) - _e118);
    let _e121 = k_d;
    let _e123 = material_2;
    k_d = (_e121 * (1f - _e123.metallic));
    let _e127 = k_d;
    let _e128 = material_2;
    let _e134 = specular;
    brdf = (((_e127 * _e128.albedo) / vec3(3.1415927f)) + _e134);
    let _e137 = brdf;
    let _e138 = radiance;
    let _e140 = n_18;
    let _e141 = l_2;
    return ((_e137 * _e138) * max(dot(_e140, _e141), 0f));
}

fn main_1() {
    var x_5: u32;
    var y_3: u32;
    var uv: vec2<f32>;
    var ro_8: vec3<f32>;
    var camera_orientation: mat3x3<f32>;
    var rd_8: vec3<f32>;
    var world_8: i32;
    var hit_15: Hit;
    var color_bg: vec3<f32>;
    var color_2: vec3<f32>;
    var p_69: vec3<f32>;
    var n_19: vec3<f32>;
    var v_6: vec3<f32>;
    var light_pos: vec3<f32>;
    var light_color: vec3<f32> = vec3<f32>(1f, 1f, 1f);
    var lamp: Light;
    var direct: vec3<f32>;
    var l_3: vec3<f32>;
    var s_3: f32;
    var ao: f32;
    var ambient: vec3<f32>;
    var fog_factor: f32;
    var noise: f32;

    let _e19 = gl_GlobalInvocationID_1;
    x_5 = _e19.x;
    let _e22 = gl_GlobalInvocationID_1;
    y_3 = _e22.y;
    let _e25 = x_5;
    let _e26 = u_1;
    let _e31 = y_3;
    let _e32 = u_1;
    if ((f32(_e25) >= _e26.resolution.x) || (f32(_e31) >= _e32.resolution.y)) {
        return;
    }
    let _e38 = x_5;
    let _e40 = u_1;
    let _e44 = y_3;
    let _e46 = u_1;
    uv = vec2<f32>((f32(_e38) / _e40.resolution.x), (f32(_e44) / _e46.resolution.y));
    let _e52 = uv;
    uv = ((_e52 * 2f) - vec2(1f));
    let _e59 = uv;
    uv.y = (_e59.y * -1f);
    let _e66 = uv;
    let _e68 = u_1;
    let _e71 = u_1;
    uv.x = (_e66.x * (_e68.resolution.x / _e71.resolution.y));
    let _e76 = u_1;
    ro_8 = _e76.camera.pos;
    let _e80 = u_1;
    let _e83 = u_1;
    let _e86 = u_1;
    camera_orientation = mat3x3<f32>(vec3<f32>(_e80.camera.right.x, _e80.camera.right.y, _e80.camera.right.z), vec3<f32>(_e83.camera.up.x, _e83.camera.up.y, _e83.camera.up.z), vec3<f32>(_e86.camera.forward.x, _e86.camera.forward.y, _e86.camera.forward.z));
    let _e103 = camera_orientation;
    let _e104 = uv;
    rd_8 = (_e103 * normalize(vec3<f32>(_e104.x, _e104.y, 1f)));
    let _e112 = get_world();
    world_8 = _e112;
    let _e114 = x_5;
    let _e118 = y_3;
    if ((_e114 == 0u) && (_e118 == 0u)) {
        {
            let _e123 = world_8;
            global.world_global = _e123;
            let _e124 = world_8;
            world_ray = _e124;
        }
    } else {
        let _e125 = world_8;
        world_ray = _e125;
    }
    precalculate_blobs();
    let _e126 = ro_8;
    let _e127 = rd_8;
    let _e128 = march(_e126, _e127);
    hit_15 = _e128;
    let _e130 = world_ray;
    let _e131 = get_bg(_e130);
    color_bg = _e131;
    let _e133 = color_bg;
    color_2 = _e133;
    let _e135 = hit_15;
    if (_e135.d < 150f) {
        {
            let _e140 = ro_8;
            let _e141 = hit_15;
            let _e143 = rd_8;
            p_69 = (_e140 + (_e141.d * _e143));
            let _e147 = p_69;
            let _e148 = normal(_e147);
            n_19 = _e148;
            let _e150 = ro_8;
            let _e151 = p_69;
            v_6 = normalize((_e150 - _e151));
            let _e155 = u_1;
            light_pos = (_e155.camera.pos + vec3<f32>(0f, 5f, 0f));
            let _e169 = light_pos;
            let _e170 = light_color;
            lamp = Light(_e169, _e170, 1500f);
            let _e174 = p_69;
            let _e175 = n_19;
            let _e176 = v_6;
            let _e177 = lamp;
            let _e178 = hit_15;
            let _e180 = lighting(_e174, _e175, _e176, _e177, _e178.material);
            direct = _e180;
            let _e182 = light_pos;
            let _e183 = p_69;
            l_3 = normalize((_e182 - _e183));
            let _e187 = p_69;
            let _e188 = l_3;
            let _e189 = light_pos;
            let _e190 = p_69;
            let _e193 = shadow(_e187, _e188, length((_e189 - _e190)));
            s_3 = _e193;
            let _e195 = direct;
            let _e196 = s_3;
            direct = (_e195 * _e196);
            let _e198 = p_69;
            let _e199 = n_19;
            let _e200 = ambient_occlusion(_e198, _e199);
            ao = _e200;
            let _e204 = hit_15;
            let _e208 = ao;
            ambient = ((vec3(0.0001f) * _e204.material.albedo) * _e208);
            let _e211 = direct;
            let _e212 = ambient;
            color_2 = (_e211 + _e212);
        }
    }
    let _e219 = hit_15;
    fog_factor = smoothstep(135f, 150f, _e219.d);
    let _e224 = color_2;
    let _e225 = color_bg;
    let _e226 = fog_factor;
    color_2 = mix(_e224, _e225, vec3(_e226));
    let _e229 = color_2;
    color_2 = pow(_e229, vec3(0.45454544f));
    let _e235 = uv;
    let _e236 = u_1;
    let _e240 = hash21_((_e235 + vec2(_e236.t)));
    noise = ((_e240 * 2f) - 1f);
    let _e246 = color_2;
    let _e247 = noise;
    color_2 = (_e246 + vec3((_e247 * 0.003921569f)));
    let _e254 = x_5;
    let _e255 = y_3;
    let _e259 = color_2;
    textureStore(rendertarget, vec2<i32>(i32(_e254), i32(_e255)), vec4<f32>(_e259.x, _e259.y, _e259.z, 1f));
    return;
}

@compute @workgroup_size(16, 16, 1) 
fn main(@builtin(global_invocation_id) gl_GlobalInvocationID: vec3<u32>) {
    gl_GlobalInvocationID_1 = gl_GlobalInvocationID;
    main_1();
    return;
}

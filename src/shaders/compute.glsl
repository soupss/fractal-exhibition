#version 450

layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;

layout(rgba8, set = 0, binding = 0) uniform writeonly image2D rendertarget;

layout(set = 0, binding = 1, std430) buffer state {
    int world_global;
};

#define MATERIAL_NULL 0.0
#define MATERIAL_FRACTAL 1.0
#define MATERIAL_FRACTAL_FLOOR 1.1
#define MATERIAL_MOUNTAIN 2.0
#define MATERIAL_WATER 3.0
#define MATERIAL_CLOUD 4.0
#define MATERIAL_LAVALAMP 5.0

#define MATERIAL_PORTAL_BASE 100.0

#define NULL -1

#define WORLD_HUB 0
#define WORLD_SUB_FRACTAL 1
#define WORLD_SUB_LAVALAMP 2
#define WORLD_SUB_MOUNTAIN 3
#define WORLD_SUB_WATER 4
#define WORLD_SUB_CLOUD 5

#define NUM_PORTALS 5
const int SUB_WORLDS[NUM_PORTALS] = {
    WORLD_SUB_LAVALAMP,
    WORLD_SUB_FRACTAL,
    WORLD_SUB_MOUNTAIN,
    WORLD_SUB_WATER,
    WORLD_SUB_CLOUD
};

// #define DEBUG
#define PI 3.1415926535897932384626433832795
#define D_MAX 150 //TODO: custom for each world
#define STEPS_MAX 256

#define PORTAL_WIDTH 4.6
#define PORTAL_HEIGHT 7.4

int world_ray;

bool use_heightmap() {
    bool res;
    if (world_ray == WORLD_HUB ||
            world_ray == WORLD_SUB_FRACTAL ||
            world_ray == WORLD_SUB_LAVALAMP ||
            world_ray == WORLD_SUB_CLOUD)
    {
        res = false;
    }
    else if (world_ray == WORLD_SUB_MOUNTAIN ||
            world_ray == WORLD_SUB_WATER)
    {
        res = true;
    }
    return res;
}


struct Camera {
    vec3 pos;
    vec3 right;
    vec3 forward;
    vec3 up;
};

layout(set = 1, binding = 0, std140) uniform frame {
    vec2 resolution;
    float t;
    float t_start;
    Camera camera;
    vec3 camera_pos_prev;
} u;

struct Material {
    vec3 albedo;
    float roughness;
    float metallic;
};

struct Light {
    vec3 pos;
    vec3 color;
    float strength;
};

float sd_sphere(vec3 p, float r) {
    return length(p) - r;
}

float sd_plane(vec3 p, vec3 n) {
    return dot(p, n);
}

float sd_box(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
}

float sd_ellipsoid(vec3 p, vec3 r) {
    float k0 = length(p/r);
    float k1 = length(p/(r*r));
    return k0*(k0-1.0)/k1;
}

mat2 rotate_2d(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, s, -s, c);
}

vec3 smootherstep(float edge0, float edge1, vec3 x) {
    x = clamp(x, edge0, edge1);
    return x * x * x * (x * (x * 6 - 15) + 10);
}

// TODO: take mat2x3 as input to work well with get_portal?
float sd_portal(vec3 p, vec3 n) {
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 right = normalize(cross(up, n));

    vec3 p_local = vec3(dot(p, right), dot(p, up), dot(p, n));

    return max(
            sd_ellipsoid(p_local, vec3(PORTAL_WIDTH/2.0, PORTAL_HEIGHT/2.0, 1.0)),
            sd_box(p_local, vec3(PORTAL_WIDTH/2.0, PORTAL_HEIGHT/2.0, 1e-8))
            );
}

// TODO: avoid trig in N functions
float hash(float k) {
    return fract(sin(k * 12.9898) * 43758.5453123);
}

float hash31(vec3 p3) {
    p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// float hash21(vec2 p) {
//     return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453123);
// }

float hash21(vec2 p) {
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

// float hash21(vec2 p) {
//     uvec2 q = floatBitsToUint(p);
//     uint n = q.x ^ q.y * 1597334677U;
//     n *= 3812015801U;
//     n ^= n >> 15;
//     n *= 1597334677U;
//     n ^= n >> 15;
//     return float(n) * (1.0 / float(0xffffffffU));
// }

vec3 hash23(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy) * 2.0 - 1.0;
}

vec2 hash12(float p) {
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xx + p3.yz) * p3.zy);
}

vec3 hash13(float p) {
    vec3 p3 = fract(vec3(p) * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.xxy + p3.yzz) * p3.zyx);
}

vec3 hash33(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return 2.0*fract((p3.xxy + p3.yxx)*p3.zyx) - 1.0;
}

float smin(float a, float b, float k) {
    k *= 2.0;
    float x = b-a;
    return 0.5*( a+b-sqrt(x*x+k*k) );
}

vec2 u_op(vec2 a, vec2 b) {
    return (a.x < b.x) ? a : b;
}

// cosine palette, credit to inigo quilez
vec3 palette(float k, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(6.28318 * (c * k + d));
}

// returns 2d value noise and its two derivatives
vec3 noised_value(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    vec2 du = 30.0 * f * f * (f * (f - 2.0) + 1.0);

    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));

    float k0 = a;
    float k1 = b - a;
    float k2 = c - a;
    float k3 = a - b - c + d;

    float noise = k0 + k1*u.x + k2*u.y + k3*u.x*u.y;

    vec2 grad = du*vec2(k1 + k3*u.y, k2 + k3*u.x);

    return vec3(noise, grad.x, grad.y);
}

// returns 2d value noise and its two derivatives
vec3 noised_gradient(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);

    // u
    // 6t^5 - 15t^4 + 10t^3
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    vec2 du = 30.0 * f * f * (f * (f - 2.0) + 1.0);

    vec2 ga = hash22(i);
    vec2 gb = hash22(i + vec2(1.0, 0.0));
    vec2 gc = hash22(i + vec2(0.0, 1.0));
    vec2 gd = hash22(i + vec2(1.0, 1.0));

    // v
    float va = dot(ga, f - vec2(0.0, 0.0));
    float vb = dot(gb, f - vec2(1.0, 0.0));
    float vc = dot(gc, f - vec2(0.0, 1.0));
    float vd = dot(gd, f - vec2(1.0, 1.0));

    float k0 = va;
    float k1 = vb - va;
    float k2 = vc - va;
    float k3 = va - vb - vc + vd;

    float noise = k0 + k1*u.x + k2*u.y + k3*u.x*u.y;

    // u*dv
    vec2 grad_g = mix(mix(ga, gb, u.x), mix(gc, gd, u.x), u.y);
    // du*v
    vec2 grad_v = du*vec2(k1 + k3*u.y, k2 + k3*u.x);

    // u*dv + du*v
    vec2 grad = grad_v + grad_g;

    return vec3(0.5*noise + 0.5, grad)/0.807;
}

// used for snow texture
float fbm(vec2 p, int octaves) {
    float h = 0.0;
    float amp = 1.0;

    const mat2 rot = mat2(0.8, -0.6, 0.6, 0.8);

    for (int i = 0; i < octaves; i++) {
        h += amp*noised_gradient(p).x;

        amp *= 0.5;
        p = rot*p*2.0;
    }
    return 0.5*h+0.5;
}

// fbm using gradients for erosion
// https://iquilezles.org/articles/morenoise/
vec3 terrain(vec2 p, int octaves) {
    float h = 0.0;
    vec2 grad = vec2(0.0);
    vec2 grad_eroded = vec2(0.0);
    float amp = 1.0;

    const mat2 rot = mat2(0.8, -0.6, 0.6, 0.8);

    mat2 m = mat2(1.0, 0.0, 0.0, 1.0);
    for (int i = 0; i < octaves; i++) {
        vec3 n = noised_gradient(0.5*p);

        vec2 grad_octave = m * n.yz;

        grad += grad_octave;
        float erosion = 1.0/(1.0 + dot(grad, grad));
        h += n.x * amp * erosion;
        grad_eroded += grad_octave * erosion;

        amp *= 0.5;
        p = rot*p*2.0;
        m = transpose(rot)*m;
    }
    return vec3(h, grad_eroded);
}

// get portal to "world" position and normal
// column 1 is portal position
// column 2 is portal normal
mat2x3 get_portal(int world) {
    vec3 pos, n;

    // this parametrization is too performance heavy

    // for (int i = 0; i < NUM_PORTALS; i++) {
    //     if (SUB_WORLDS[i] == world) {
    //         float t = (2 * PI * float(i)) / float(NUM_PORTALS);
    //         float r = 10.0;
    //
    //         pos = vec3(r*cos(t), 4.0, r*sin(t));
    //         n = vec3(-cos(t), 0.0, -sin(t));
    //
    //         break;
    //     }
    // }

    // so it's hardcoded

    if (world == WORLD_SUB_LAVALAMP) {
        pos = vec3(10.0, 4.0, 0.0);
        n = vec3(-1.0, 0.0, 0.0);
    }
    else if (world == WORLD_SUB_FRACTAL) {
        pos = vec3(3.09017, 4.0, 9.51057);
        n = vec3(-0.309017, 0.0, -0.951057);
    }
    else if (world == WORLD_SUB_MOUNTAIN) {
        pos = vec3(-8.09017, 4.0, 5.87785);
        n = vec3(0.809017, 0.0, -0.587785);
    }
    else if (world == WORLD_SUB_WATER) {
        pos = vec3(-8.09017, 4.0, -5.87785);
        n = vec3(0.809017, 0.0, 0.587785);
    }
    else if (world == WORLD_SUB_CLOUD) {
        pos = vec3(3.09017, 4.0, -9.51057);
        n = vec3(-0.309017, 0.0, 0.951057);
    }
    else {
        pos = vec3(0.0);
        n = vec3(0.0, 0.0, 1.0);
    }

    return mat2x3(pos, n);
}

bool portal_entered(int world) {
    mat2x3 portal = get_portal(world);
    vec3 pos = portal[0];
    vec3 n = portal[1];

    vec3 cam_pos_relative = u.camera.pos - pos;
    vec3 cam_pos_relative_prev = u.camera_pos_prev - pos;

    // camera pos in portal space
    float z = dot(cam_pos_relative, n);
    float z_prev = dot(cam_pos_relative_prev, n);

    if (sign(z) != sign(z_prev)) {
        // portal's local axes
        vec3 up = vec3(0.0, 1.0, 0.0);
        vec3 right = normalize(cross(up, n));

        float x = dot(cam_pos_relative, right);
        float y = dot(cam_pos_relative, up);

        float x2 = x*x;
        float y2 = y*y;
        float w = PORTAL_WIDTH/2.0;
        float h = PORTAL_HEIGHT/2.0;
        float w2 = w*w;
        float h2 = h*h;

        bool intersects_xy = x2/w2 + y2/h2 <= 1.0;
        return intersects_xy;
    }

    return false;
}

// get world camera is in
int get_world() {
    if (world_global == WORLD_HUB) {
        for (int i = 0; i < NUM_PORTALS; i++) {
            int world = SUB_WORLDS[i];
            if (portal_entered(world)) return world;
        }
        return WORLD_HUB;
    }
    else {
        if (portal_entered(world_global)) return WORLD_HUB;
        return world_global;
    }
    return NULL;
}

vec3 get_bg(int world) {
    if (world == WORLD_HUB) return vec3(1.0);
    else if (world == WORLD_SUB_MOUNTAIN) return vec3(0.53, 0.81, 0.92);
    else if (world == WORLD_SUB_WATER) return 0.5*vec3(0.53, 0.81, 0.92);
    else return vec3(0.0);
}

// TODO: get_light

vec2 map_hub(vec3 p) {
    return vec2(1e8, MATERIAL_NULL);
}

vec4 g_trap = vec4(1e10);

vec2 map_fractal(vec3 p) {
    mat2x3 portal = get_portal(WORLD_SUB_FRACTAL);

    // project to fractal world space
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 forward = portal[1];
    vec3 right = normalize(cross(up, forward));

    vec3 q = vec3(dot(p, right), dot(p, up), dot(p, forward));
    vec2 res = vec2(sd_plane(q + vec3(0.0, 4.0, 0.0), vec3(0.0, 1.0, 0.0)), MATERIAL_FRACTAL_FLOOR);

    q = q - vec3(0.0, 3.5 + 0.35*sin(0.8*u.t), -18.0);

    float s = 11.0;
    vec2 id = round(q.xy/s);
    if (id.y > 0 && id.y < 15) {
        q.xy = q.xy - s*round(id);

        q.xz *= rotate_2d(0.1 * u.t);
        q.yz *= rotate_2d(0.05 * u.t);
        q.xz *= rotate_2d(0.05 * -u.t);

        float d_bound = sd_sphere(q, 10.0);
        if (d_bound > 2.0) {
            res = u_op(res, vec2(d_bound, MATERIAL_NULL));
        }
        else {
            mat2 rot_xz = rotate_2d(0.2*u.t);
            mat2 rot_xy = rotate_2d(0.15*u.t);
            float scale = 2.0;
            float scaled = 1.0;

            for (int i = 0; i < id.y; i++) {
                q = abs(q);
                q -= vec3(1.0, 0.4, 0.7);
                q.xz *= rot_xz;
                q.xy *= rot_xy;
                q *= scale*0.8;
                scaled *= scale;
                g_trap = min(g_trap, vec4(abs(q), length(q)));
            }

            float d = sd_box(q, vec3(1.0, 1.2, 1.0));
            d /= scaled;

            res = u_op(res, vec2(d, MATERIAL_FRACTAL));
        }
    }

    return res;
}

#define BLUBS 4

//TODO: dont change roof/floor color except blend
//TODO: more blobs
vec2 map_lavalamp(vec3 p) {
    vec2 res = vec2(1e8, MATERIAL_LAVALAMP);
    float world_height = 20.0;
    p.y += 4.0;
    p.x -= 35.0;

    float d_floor = sd_plane(p, vec3(0.0, 1.0, 0.0));

    vec3 p_roof = p - vec3(0.0, world_height, 0.0);
    float d_roof = sd_plane(p_roof, vec3(0.0, -1.0, 0.0));

    float d_world = min(d_floor, d_roof);

    float y = world_height/2.0 + world_height * 0.7 * sin(2.0*PI*hash(u.t_start) + u.t * 0.6);
    y = 5.0 + y*0.65;

    float d_blob = sd_sphere(p - vec3(0.0, y, 0.0), 5.0 + 3.0*sin(u.t));

    d_world = smin(d_world, d_blob, 0.5);
    return vec2(d_world, MATERIAL_LAVALAMP);
}

vec2 map_cloud(vec3 p) {
    vec3 q = p - vec3(15.0, 10.0, -30.0);
    float d = sd_sphere(q, 10.0) + 0.2*sin(5.0*q.x + 3.0*q.z - 10.0*q.y - u.t);

    d *= 0.2;

    return vec2(d, MATERIAL_CLOUD);
}

float get_heightmap_amplitude(int world) {
    if (world == WORLD_SUB_WATER) return 3.0;
    if (world == WORLD_SUB_MOUNTAIN) return 60.0;
    else return -1.0;
}

vec4 heightmap_water(vec2 p) {
    float amp = get_heightmap_amplitude(WORLD_SUB_WATER);
    float h = -20.0 + amp*sin(0.3*p.x + u.t);
    return vec4(h, vec2(0.0), MATERIAL_WATER);
}

vec4 heightmap_mountain_octaves(vec2 p, int octaves) {
    float freq = 0.01;

    vec3 fbm = terrain(100.0*hash12(u.t_start) + freq*p, octaves);
    float h = fbm.x;

    float amp = get_heightmap_amplitude(WORLD_SUB_MOUNTAIN);
    h *= amp;
    h -= amp;

    vec2 grad = fbm.yz * freq * amp;

    return vec4(h, grad, MATERIAL_MOUNTAIN);
}

vec4 heightmap_mountain(vec2 p, float t, float t_max) {
    int oct_max = 6;
    int oct_min = 2;
    int octaves = int(round(oct_min + (oct_max-oct_min)*(1.0 - smoothstep(t_max/2.0, t_max, t))));
    return heightmap_mountain_octaves(p, octaves);
}

vec2 map(vec3 p) {
    if (world_ray == WORLD_HUB) return map_hub(p);
    else if (world_ray == WORLD_SUB_FRACTAL) return map_fractal(p);
    else if (world_ray == WORLD_SUB_LAVALAMP) return map_lavalamp(p);
    else if (world_ray == WORLD_SUB_CLOUD) return map_cloud(p);
    else if (world_ray == WORLD_SUB_MOUNTAIN) return vec2(p.y - heightmap_mountain(p.xz, 0.0, 0.0).x, MATERIAL_MOUNTAIN);
    else if (world_ray == WORLD_SUB_WATER) return vec2(p.y - heightmap_water(p.xz).x, MATERIAL_WATER);
    else return vec2(1e8, MATERIAL_NULL);
}

vec2 map_portals(vec3 p) {
    vec2 res = vec2(1e8, MATERIAL_NULL);
    if (world_ray == WORLD_HUB) {
        for (int i = 0; i < NUM_PORTALS; i++) {
            int world_dst = SUB_WORLDS[i];
            mat2x3 portal = get_portal(world_dst);
            float d = sd_portal(p - portal[0], portal[1]);
            res = u_op(res, vec2(d, MATERIAL_PORTAL_BASE + float(world_dst)));
        }
    }
    else {
        mat2x3 portal = get_portal(world_ray);
        float d = sd_portal(p - portal[0], -1.0 * portal[1]);
        res = u_op(res, vec2(d, MATERIAL_PORTAL_BASE + float(WORLD_HUB)));
    }
    return res;
}

// returns vec4(height, grad.x, grad.y, material_id)
vec4 heightmap(vec2 p, float t, float t_max) {
    if (world_ray == WORLD_SUB_MOUNTAIN) return heightmap_mountain(p, t, t_max);
    if (world_ray == WORLD_SUB_WATER) return heightmap_water(p);
    return vec4(0.0);
}

////////////
// engine //
////////////

vec3 raymarch_sdf(vec3 ro, vec3 rd, float t_global) {
    float t_tot = 0.001;
    float t_candidate = 0.001;
    float err_candidate = 1e8;
    float id_candidate = MATERIAL_NULL;

    float t_max = 100.0;

    float pixel_radius = 1.0/u.resolution.y;

    float steps = 0.0;
    for (int i = 0; i < 256; i++) {
        steps++;
        vec3 p = ro + t_tot*rd;

        vec2 hit = map(p);

        hit = u_op(hit, map_portals(p));

        float t = hit.x;
        float id = hit.y;

        float err = t/(t_global + t_tot); // screen_space

        if (err < err_candidate) {
            err_candidate = err;
            t_candidate = t_tot;
            id_candidate = id;
        }

        if (err < 1.0*pixel_radius) { //TODO: tune threshold
            break;
        }

        t_tot += t;

        if (t_tot > t_max) {
            t_candidate = -1.0;
            break;
        }
    }
    return vec3(t_candidate, id_candidate, steps);
}

vec3 raymarch_terrain(vec3 ro, vec3 rd) {
    float t = 0.01;
    const float t_max = 1600.0;

    float h_max = get_heightmap_amplitude(world_ray);

    bool rd_is_up = rd.y > 0.0;

    mat2x3 portal = get_portal(world_ray);
    float h_portal = portal[0].y + PORTAL_HEIGHT;

    h_max = max(h_max, h_portal);

    if (ro.y > h_max && rd_is_up ) return vec3(-1.0);
    if (ro.y > h_max) {
        t = max(t, (h_max - ro.y) / rd.y);
    }

    float steps = 0.0;
    for (int i = 0; i < 256; i ++) {
        steps++;
        vec3 p = ro + t*rd;

        vec4 hm = heightmap(p.xz, t, t_max);
        float h = hm.x;
        float id = hm.w;

        float dh = p.y - h;
        if (abs(dh) < 0.001*t) {
            return vec3(t, id, steps);
        }

        float d_portal = sd_portal(p - portal[0], -1.0 * portal[1]);
        if (d_portal < 0.001) {
            return vec3(t, MATERIAL_PORTAL_BASE + float(WORLD_HUB), steps);
        }

        float dt = 0.45*dh;
        dt = min(dt, d_portal);

        t += dt;
        if (t > t_max) break;
    }
    return vec3(-1.0);
}

vec3 raymarch(vec3 ro, vec3 rd) {
    float t_res = 0.0;
    float steps = 0.0;

    while (t_res < D_MAX) {
        vec3 ro_current = ro + rd*t_res;

        vec3 hit;

        if (use_heightmap()) hit = raymarch_terrain(ro_current, rd);
        else hit = raymarch_sdf(ro_current, rd, t_res);

        float t = hit.x;
        float id = hit.y;
        float steps = hit.z;

        if (t > 0.0) {
            t_res += t;

            if (id >= MATERIAL_PORTAL_BASE) {
                world_ray = int(id - MATERIAL_PORTAL_BASE);

                vec3 n = get_portal(world_ray)[1];
                float a = max(abs(dot(n, rd)), 1e-6);
                t_res += 0.5 / a;
                continue;
            }

            return vec3(t_res, id, steps);
        }
        else break;
    }
    return vec3(-1.0);
}

// Hit march_old(vec3 ro, vec3 rd) {
//     float d = 0.0;
//     Hit hit;
//     float r_prev = 0.0;
//     float omega = 1.4;
//     float step = 0.0;
//
//     float d_candidate = 0.0;
//     float error_candidate = 1e8;
//     Material material_candidate = Material(MATERIAL_TYPE_OPAQUE, vec3(0.0), 0.0, 0.0);
//     int target_candidate = NULL;
//
//     float r_pixel = 1.0/u.resolution.y;
//
//     float is = 0.0;
//     for (int i = 0; i < STEPS_MAX; i++) {
//         vec3 p = ro + d * rd;
//         hit = map_primary(p);
//         is++;
//
//         float r = hit.d;
//
//         float threshold = 0.001 + (d * r_pixel/2.0);
//         if (abs(r) < threshold && hit.material.type == MATERIAL_TYPE_PORTAL) {
//             world_ray = hit.world_target;
//             vec3 n = get_portal(world_ray)[1];
//             float a = abs(dot(n, rd));
//             a = max(a, 1e-8);
//             d += (20.0*threshold) / a;
//
//             r_prev = 0.0;
//             step = 0.0;
//             error_candidate = 1e8;
//             continue;
//         }
//
//         bool overstep = (omega > 1.0) && (r + r_prev) < step; // step from previous iteration
//         if (overstep) {
//             d -= step;
//             step = r_prev;
//             omega = 1.0;
//             continue;
//         }
//         else {
//             step = r * omega;
//             r_prev = r;
//         }
//
//         float error = r / d;
//
//         if (!overstep && error < error_candidate) {
//             d_candidate = d;
//             error_candidate = error;
//             material_candidate = hit.material;
//             target_candidate = hit.world_target;
//         }
//
//         if (!overstep && error < r_pixel && hit.material.type != MATERIAL_TYPE_PORTAL) break;
//         if (r < threshold) break;
//
//         if (d > D_MAX) return Hit(1e8, material_candidate, NULL);
//
//         d += step;
//     }
//
// #ifdef DEBUG
//     return Hit(is, material_candidate, target_candidate);
// #endif
//
//     if (error_candidate > r_pixel * 1.5) {
//         return Hit(1e8, material_candidate, NULL);
//     }
//
//     return Hit(d_candidate, material_candidate, target_candidate);
// }

// tetrahedron method
// credit to inigo quilez

vec3 normal_numerical(vec3 p, float t) {
    vec2 e = vec2(1.0, -1.0) * max(0.001, 0.001 * t);
    vec3 n;
    if (world_ray == WORLD_SUB_MOUNTAIN) {
        int o = 11;
        n = normalize(
                e.xyy * (p.y + e.y - heightmap_mountain_octaves(p.xz + e.xy, o).x) +
                e.yyx * (p.y + e.y - heightmap_mountain_octaves(p.xz + e.yx, o).x) +
                e.yxy * (p.y + e.x - heightmap_mountain_octaves(p.xz + e.yy, o).x) +
                e.xxx * (p.y + e.x - heightmap_mountain_octaves(p.xz + e.xx, o).x)
                );
    }
    else { // TODO
        n = normalize(
                e.xyy * map(p + e.xyy).x +
                e.yyx * map(p + e.yyx).x +
                e.yxy * map(p + e.yxy).x +
                e.xxx * map(p + e.xxx).x
                );
    }
    return n;
}

vec3 normal_analytical(vec2 p) {
    vec2 grad = heightmap_mountain_octaves(p, 12).yz;
    vec3 n = normalize(vec3(-grad.x, 1.0, -grad.y));
    return n;
}

vec3 normal(vec3 p, float t) {
    vec3 n;
    // if (use_heightmap()) n = normal_analytical(p.xz);
    if (false);
    else n = normal_numerical(p, t);
    return n;
}

float shadow(vec3 ro, vec3 rd, float d_max) {
    float d = 0.1;
    float occlusion = 1.0;
    for (int i = 0; i < 128 && d < d_max; i++) {
        vec3 p = ro + rd * d;
        float h = map(p).x;
        if (h < 0.001) return 0.0;
        occlusion = min(occlusion, 32.0*h/d);
        d += h;
    }
    return occlusion;
}

// TODO:
float shadow_terrain(vec3 ro, vec3 rd, float d_max) {
    return 0.0;
}

float ambient_occlusion_sdf(vec3 p, vec3 n) {
    float scale = 1.00;
    float occlusion = 0.0;
    for (int i = 1; i <= 4; i++) {
        float h = 0.04*float(i);
        float d = map(p + h*n).x;
        occlusion += (h-d) * scale;
        scale *= 0.95;
    }
    return 1.0 - clamp(occlusion, 0.0, 1.0);
}

//TODO: make this work
float ambient_occlusion_terrain(vec3 p) {
    vec2 offsets[4] = {
        vec2(1.0, 0.0),
        vec2(0.0, 1.0),
        vec2(-1.0, 0.0),
        vec2(0.0, -1.0),
    };
    float occlusion = 1.0;
    for (int i = 0; i < 4; i++) {
        vec2 q = p.xz + 0.1*offsets[i];
        float h = heightmap(p.xz, 0.0, 0.0).x;
        float dh = p.y - h;
        occlusion -= 0.5*max(-dh, 0.0);
    }
    return occlusion;
}

float ambient_occlusion(vec3 p, vec3 n) {
    float ao;
    // if (use_heightmap()) {
    //     ao = ambient_occlusion_terrain(p);
    // }
    // else {
        ao = ambient_occlusion_sdf(p, n);
    // }
    return ao;
}

// cook torrance pbr

// Trowbridge-Reitz GGX Normal Distribution
float distribution(vec3 n, vec3 h, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;

    float nh = max(dot(n, h), 0.0);
    float nh2 = nh * nh;

    float num = a2;
    float denom = (nh2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / denom;
}

// Fresnel Schlick's approximation
vec3 fresnel(vec3 v, vec3 h, vec3 f0) {
    float cos_theta = max(dot(v,h), 0.0);
    return f0 + (1.0 - f0) * pow(clamp(1.0 - cos_theta, 0.0, 1.0), 5.0);
}

// Schlick-GGX
// calculates microfacet occlusion
float g1(vec3 n, vec3 dir, float roughness) {

    // remap roughness for direct lightning
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;

    float cos_theta = max(dot(n, dir), 0.0);

    float num = cos_theta;
    float denom = cos_theta * (1.0 - k) + k;

    return num / denom;
}

float geometry(vec3 n, vec3 v, vec3 l, float roughness) {
    // smith method
    float masking = g1(n, v, roughness);
    float shadowing = g1(n, l, roughness);

    return masking * shadowing;
}

vec3 light_direct(vec3 p, vec3 n, vec3 v, Light light, Material material) {
    vec3 l = normalize(light.pos - p);
    vec3 h = normalize(v + l);

    vec3 f0 = vec3(0.04);
    f0 = mix(f0, material.albedo, material.metallic);

    float distance = length(light.pos - p);
    float attenuation = 1.0 / (distance * distance); // light follows inverse square law
    vec3 radiance = light.color * light.strength * attenuation;

    float D = distribution(n, h, material.roughness);
    float G = geometry(n, v, l, material.roughness);
    vec3 F = fresnel(v, h, f0);

    vec3 num = D * G * F;
    float denom = 4.0 * max(dot(n, v), 0.0) * max(dot(n, l), 0.0) + 0.0001;
    vec3 specular = num / denom;

    vec3 k_s = F;
    vec3 k_d = vec3(1.0) - k_s;

    k_d *= 1.0 - material.metallic;

    vec3 brdf = k_d * material.albedo / PI + specular;

    return brdf * radiance * max(dot(n, l), 0.0);
}

vec3 lighting(vec3 p, vec3 n, vec3 v, Material material, float t) {
    vec3 color = vec3(0.0);
    if (use_heightmap()) {
        vec3 dir_sun = normalize(vec3(-0.8, 0.4, -0.3));

        vec3 col_sun = vec3(1.64, 1.27, 0.99);
        vec3 col_sky = vec3(0.16, 0.20, 0.28);
        vec3 col_ind = vec3(0.20, 0.09, 0.08);

        float diffuse_sun = clamp(dot(n, dir_sun), 0.0, 1.0);
        float diffuse_sky = clamp(0.5 + 0.5*n.y, 0.0, 1.0);
        float diffuse_ind = clamp(dot(n, normalize(dir_sun*vec3(-1.0,0.0,-1.0))), 0.0, 1.0);

        // float ao = ambient_occlusion(p, n);
        float ao = 1.0;
        float s = shadow(p, dir_sun, 300.0);
        // float s = 1.0;

        vec3 light = col_sun*diffuse_sun*s;
        light += 0.2*col_sky*diffuse_sky*ao;
        light += 0.2*col_ind*diffuse_ind*ao;

        color = material.albedo * light;
    }
    else {
        vec3 light_pos = u.camera.pos + vec3(0.0, 5.0, 0.0);
        vec3 light_color = vec3(1.0, 1.0, 1.0);
        Light lamp = Light(light_pos, light_color, 500.0);
        vec3 direct = light_direct(p, n, v, lamp, material);

        vec3 l = normalize(light_pos - p);
        float s = shadow(p, l, length(light_pos - p));
        direct *= s;

        float ao = ambient_occlusion(p, n);
        vec3 ambient = vec3(0.0001) * material.albedo * ao;
        color = direct + ambient;
    }

    return color;
}

Material get_material(float id, vec3 p, vec3 n, float t, vec4 trap) {
    if (id == MATERIAL_FRACTAL) {
        vec3 color =palette(trap.z * 4.0, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.1, 0.2));
        return Material(color, 0.8, 0.2);
    }
    else if (id == MATERIAL_FRACTAL_FLOOR) {
        return Material(vec3(0.6, 0.5, 0.4), 0.8, 0.2);
    }
    else if (id == MATERIAL_MOUNTAIN ) {
        float amp = get_heightmap_amplitude(WORLD_SUB_MOUNTAIN);
        float r = noised_value(p.xz*0.01).x;
        float y = p.y+amp;

        vec3 rock1 = vec3(0.1, 0.09, 0.08);
        vec3 rock2 = vec3(0.05, 0.04, 0.03);
        vec3 color = 0.9*(r*0.25+0.75)*mix(rock1, rock2, noised_value(0.1*(vec2(p.x, p.y*3.0))).x);

        vec3 dirt = vec3(0.045, 0.03, 0.02);
        color = mix(color, dirt*(r*0.5+0.5), smoothstep(0.75, 0.9, n.y));

        vec3 grass = vec3(0.05, 0.05, 0.01);
        color = mix(color, grass*(r*0.75+0.25), smoothstep(0.95, 1.0, n.y));

        float h = smoothstep(0.85*amp, 1.00*amp, y+0.13*amp*fbm(p.xz, 3));
        float s = smoothstep(1.0-0.5*h, 1.0-0.1*h, 0.25 + 0.75*n.y);
        vec3 snow = vec3(0.95);
        color = mix(color, snow, s);

        // vec3 fog = 0.6*vec3(0.5, 0.6, 1.0);
        // float fo = 1.0-exp(-pow(0.001*t, 2.0));
        // color = mix(color, fog, fo);

        return Material(color, 0.0, 0.2);
    }
    else if (id == MATERIAL_WATER ) return Material(vec3(0.0, 0.0, 1.0), 0.5, 0.5);
    else if (id == MATERIAL_CLOUD ) return Material(vec3(0.8, 0.8, 0.8), 0.5, 0.5);
    else if (id == MATERIAL_LAVALAMP ) return Material(vec3(1.0, 0.0, 1.0), 0.5, 0.5);
    return Material(vec3(1.0, 0.0 ,1.0), 0.0, 0.0);
}

void main() {
    uint x = gl_GlobalInvocationID.x;
    uint y = gl_GlobalInvocationID.y;

    if (x >= u.resolution.x || y >= u.resolution.y) return;

    vec2 uv = vec2(float(x) / u.resolution.x, float(y) / u.resolution.y);
    uv = uv * 2.0 - 1.0;
    uv.y *= -1;
    uv.x *= u.resolution.x/u.resolution.y;

    vec3 ro = u.camera.pos;
    mat3 camera_orientation = mat3(u.camera.right, u.camera.up, u.camera.forward);
    vec3 rd = camera_orientation * normalize(vec3(uv, 1.0));

    int world = get_world();
    if (x == 0 && y == 0) {
        world_global = world;
        world_ray = world;
    }
    else world_ray = world;

    vec3 hit = raymarch(ro, rd);
    float t = hit.x;
    float material_id = hit.y;
    float steps = hit.z;

    vec3 color = vec3(0.0);
    if (t > 0.0) {
#ifdef DEBUG
        color = mix(vec3(0.0), vec3(1.0), steps/256);
#else
        vec3 p = ro + t*rd;

        g_trap = vec4(1e10);
        if (world_ray == WORLD_SUB_FRACTAL) {
            map_fractal(p);
        }
        vec4 hit_trap = g_trap;

        vec3 n = normal(p, t);
        vec3 v = normalize(ro - p);

        Material material = get_material(material_id, p, n, t, hit_trap);
        vec3 light = lighting(p, n, v, material, t);

        color = light;
#endif
    }
    else {
        color = get_bg(world_ray);
    }

    color = pow(color, vec3(1.0 / 2.2)); // gamma correction

    // dithering to reduce color banding
    imageStore(rendertarget, ivec2(x, y), vec4(color, 1.0));
}

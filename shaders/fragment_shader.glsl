#version 330 core

in vec2 vertex_pos;

out vec4 frag_color;

uniform vec3 u_ro;
uniform vec2 u_resolution;
uniform mat3 u_cam_matrix;
uniform float u_t;

#define PI 3.1415926535897932384626433832795
#define DIST_MAX 100

#define NULL -1

#define WORLD_HUB 0
#define WORLD_LAVALAMP 1
#define WORLD_FRACTAL 2

#define MATERIAL_OPAQUE 0
#define MATERIAL_PORTAL 1

int g_world = WORLD_HUB;

////////////////
// primitives //
////////////////

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

float sd_portal(vec3 p) {
    return max(sd_ellipsoid(p, vec3(2.0, 3.7, 1.0)),
            sd_box(p, vec3(2.0, 4.0, 0.02)));
}


struct Material {
    int type;
    vec3 albedo;
    float roughness;
    float metallic;
};

struct Light {
    vec3 pos;
    vec3 color;
    float strength;
};

struct Hit {
    float d;
    Material material;
    int world;
};


mat2 rotate_2d(float a) {
    return mat2(cos(a), sin(a), -sin(a), cos(a));
}

// union operation
Hit u_op(Hit a, Hit b) {
    if (a.d < b.d) return a;
    else return b;
}

// cosine palette, credit to inigo quilez
vec3 palette(float k, vec3 a, vec3 b, vec3 c, vec3 d) {
    return a + b * cos(6.28318 * (c * k + d));
}


///////////
// scene //
///////////

Hit map_s_hub(vec3 p) {
    Hit hit;
    {
        // ground
        hit.d = sd_plane(p, vec3(0.0, 1.0, 0.0));
        hit.material = Material(MATERIAL_OPAQUE, vec3(1.0), 0.0, 0.0);
    }

    return hit;
}

Hit map_p_hub(vec3 p) {
    Hit hit = map_s_hub(p);
    {
        // portal to fractal world
        vec3 q = p - vec3(0.0, 4.0, 0.0);
        float d = sd_portal(q);
        Material m = Material(MATERIAL_PORTAL, vec3(1.0), 0.0, 0.0);
        hit = u_op(hit, Hit(d, m, WORLD_FRACTAL));
    }

    {
        // portal to lavalamp world
        vec3 q = p - vec3(10.0, 4.0, 0.0);
        float d = sd_portal(q);
        Material m = Material(MATERIAL_PORTAL, vec3(1.0), 0.0, 0.0);
        hit = u_op(hit, Hit(d, m, WORLD_LAVALAMP));
    }
    return hit;
}

Hit map_s_fractal(vec3 p) {
    Hit hit;
    {
        hit.d = sd_plane(p, vec3(0.0, 1.0, 0.0));
        hit.material = Material(MATERIAL_OPAQUE, vec3(0.0, 0.0, 1.0), 0.0, 0.0);
    }

    {
        vec3 q = p - vec3(0.0, 3.5 + 0.35*sin(0.8*u_t), -18.0);

        float s = 11.0;
        float id = round(q.x/s);
        if (id < 0 || id > 10) return hit;
        q.x = q.x - s*round(q.x/s);

        q.xz *= rotate_2d(0.1 * u_t);
        q.yz *= rotate_2d(0.05 * u_t);
        q.xz *= rotate_2d(0.05 * -u_t);

        // kifs fractal
        float scale = 2.0;
        float scaled = 1.0;
        vec4 trap = vec4(1e10);
        for (int i = 0; i < id; i++) {
            q = abs(q);
            q -= vec3(1.0, 0.4, 0.7);
            q.xz *= rotate_2d(0.2*u_t);
            q.xy *= rotate_2d(0.15*u_t);
            q *= scale*0.8;
            scaled *= scale;
            trap = min(trap, vec4(abs(q), length(q)));
        }

        float d = sd_box(q, vec3(1.0, 1.2, 1.0));
        d /= scaled;

        vec3 color = palette(trap.z * 4.0, vec3(0.5), vec3(0.5), vec3(1.0), vec3(0.0, 0.1, 0.2));
        Material m = Material(MATERIAL_OPAQUE, color, 0.4, 1.0);
        hit = u_op(hit, Hit(d, m, NULL));
    }

    return hit;
}

Hit map_p_fractal(vec3 p) {
    Hit hit = map_s_fractal(p);
    {
        vec3 q = p - vec3(0.0, 4.0, 0.0);
        float d = sd_portal(q);
        Material m = Material(MATERIAL_PORTAL, vec3(1.0), 0.0, 0.0);
        hit = u_op(hit, Hit(d, m, WORLD_HUB));
    }
    return hit;
}

Hit map_s_lavalamp(vec3 p) {
    Hit hit;
    {
        hit.d = sd_plane(p, vec3(0.0, 1.0, 0.0));
        hit.material = Material(MATERIAL_OPAQUE, vec3(1.0, 0.0, 1.0), 0.0, 0.0);
    }
    return hit;
}

Hit map_p_lavalamp(vec3 p) {
    return map_s_lavalamp(p);
}

Hit map_secondary(vec3 p) {
    switch(g_world) {
        case WORLD_HUB:
            return map_s_hub(p);
        case WORLD_FRACTAL:
            return map_s_fractal(p);
        case WORLD_LAVALAMP:
            return map_s_lavalamp(p);
    }
}

Hit map_primary(vec3 p) {
    switch(g_world) {
        case WORLD_HUB:
            return map_p_hub(p);
        case WORLD_FRACTAL:
            return map_p_fractal(p);
        case WORLD_LAVALAMP:
            return map_p_lavalamp(p);
    }
}

////////////
// engine //
////////////

Hit march(vec3 ro, vec3 rd) {
    float d = 0.0;
    Material m;
    int world;

    for (int i = 0; i < 512; i++) {
        vec3 p = ro + d * rd;
        Hit hit = map_primary(p);
        m = hit.material;
        world = hit.world;

        if (abs(hit.d) < 0.001) {
            if (hit.material.type == MATERIAL_PORTAL) {
                g_world = hit.world;
                d += 3.0;
                continue;
            }
            break;
        }
        d += hit.d;
        if (d > DIST_MAX) break;
    }

    return Hit(d, m, world);
}

vec3 normal(vec3 p) {
    vec2 e = vec2(1.0, -1.0) * 0.0001;
    return normalize(
            e.xyy * map_secondary(p + e.xyy).d +
            e.yyx * map_secondary(p + e.yyx).d +
            e.yxy * map_secondary(p + e.yxy).d +
            e.xxx * map_secondary(p + e.xxx).d
            );
}

float shadow(vec3 ro, vec3 rd) {
    float d = 0.1;
    float result = 1.0;
    for (int i = 0; i < 512 && d < 64.0; i++) {
        float h = map_secondary(ro + rd*d).d;
        if (h < 0.001) return 0.0;
        result = min(result, 64.0*h/d);
        d += h;
    }
    return result;
}

float ambient_occlusion(vec3 p, vec3 n) {
    float scale = 1.00;
    float occlusion = 0.0;
    for (int i = 1; i <= 4; i++) {
        float h = 0.04*float(i);
        float d = map_secondary(p + h*n).d;
        occlusion += (h-d) * scale;
        scale *= 0.95;
    }
    return 1.0 - clamp(occlusion, 0.0, 1.0);
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

vec3 lighting(vec3 p, vec3 n, vec3 v, Light light, Material material) {
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

void main() {
    vec2 uv = vertex_pos;
    uv.x *= u_resolution.x/u_resolution.y;

    vec3 ro = u_ro;
    vec3 rd = u_cam_matrix * normalize(vec3(uv, 1.0));

    if (ro.z < 0.0) g_world = WORLD_FRACTAL;

    Hit hit = march(ro, rd);

    vec3 color_bg = vec3(0.9);
    vec3 color = color_bg;

    if (hit.d < DIST_MAX) {
        vec3 p = ro + hit.d * rd;
        vec3 n = normal(p);
        vec3 v = normalize(ro - p);

        vec3 light_pos = ro + vec3(0.0, 2.0, 0.0);
        vec3 light_color = vec3(1.0, 1.0, 1.0);
        Light lamp = Light(light_pos, light_color, 200.0);
        vec3 direct = lighting(p, n, v, lamp, hit.material);

        vec3 l = normalize(light_pos - p);
        float s = shadow(p, l);
        direct *= s;

        float ao = ambient_occlusion(p, n);
        vec3 ambient = vec3(0.0001) * hit.material.albedo * ao;

        color = direct + ambient;
    }

    // float fog_factor = smoothstep(DIST_MAX * 0.7, DIST_MAX, hit.d);
    // color = mix(color, color_bg, fog_factor);

    color = color / (color + vec3(1.0)); // tone mapping
    color = pow(color, vec3(1.0 / 2.2)); // gamma correction

    frag_color = vec4(color, 1.0);
}

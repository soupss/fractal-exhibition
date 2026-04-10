#version 330 core

in vec2 vertex_pos;

out vec4 frag_color;

uniform vec2 resolution;
uniform float t;

#define PI 3.1415926535897932384626433832795
#define DIST_MAX 50

// primitives
float sd_sphere(vec3 p, float r) {
    return length(p) - r;
}

float sd_plane(vec3 p, vec3 n) {
    return dot(p, n);
}

float sd_round_box(vec3 p, vec3 b, float r)
{
  vec3 q = abs(p) - b + r;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

// types
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

struct Hit {
    float d;
    Material material;
};

// helper functions
vec2 rotate_2d(vec2 p, float a) {
    return p * mat2(cos(a), sin(a), -sin(a), cos(a));
}

// union operation
vec2 u_op(vec2 a, vec2 b) {
    if (a.x < b.x) return a;
    else return b;
}

#define MATERIAL_MARBLE 0.0
#define MATERIAL_GOLD 1.0

// scene
vec2 map(vec3 p) {
    // x component is distance
    // y component is material id
    vec2 hit = vec2(1e10, -1.0);

    {
        // ground
        vec3 q = p;
        hit.x = sd_plane(q, vec3(0.0, 1.0, 0.0));
        hit.y = MATERIAL_MARBLE;
    }

    {
        // gold tacka
        vec3 q = p - vec3(0.0, 0.5, 0.0);
        q.zx = rotate_2d(q.zx, t);
        float d = sd_round_box(q, vec3(1.0, 0.2, 0.4), 0.1);
        float m = MATERIAL_GOLD;
        hit = u_op(hit, vec2(d, m));
    }

    return hit;
}

// engine
vec2 march(vec3 ro, vec3 rd) {
    float d = 0.0;
    float material_id = -1.0;

    for (int s = 0; s < 100; s++) {
        vec3 p = ro + d * rd;
        vec2 hit = map(p);
        material_id = hit.y;

        if (abs(hit.x) < 0.001) break;
        d += hit.x;
        if (d > DIST_MAX) break;
    }

    return vec2(d, material_id);
}

vec3 normal(vec3 p) {
    // credit to inigo quilez

    vec2 e = vec2(0.0001, 0.0);
    vec3 n = vec3(map(p+e.xyy).x - map(p-e.xyy).x,
                  map(p+e.yxy).x - map(p-e.yxy).x,
                  map(p+e.yyx).x - map(p-e.yyx).x);
    return normalize(n);
}

// pbr, using cook torrance lighting model

float distribution(vec3 n, vec3 h, float roughness) {
    // Trowbridge-Reitz GGX Normal Distribution

    float a = roughness * roughness;
    float a2 = a * a;

    float nh = max(dot(n, h), 0.0);
    float nh2 = nh * nh;

    float num = a2;
    float denom = (nh2 * (a2 - 1.0) + 1.0);
    denom = PI * denom * denom;

    return num / denom;
}

vec3 fresnel(vec3 v, vec3 h, vec3 f0) {
    // Fresnel Schlick's approximation

    float cos_theta = max(dot(v,h), 0.0);
    return f0 + (1.0 - f0) * pow(clamp(1.0 - cos_theta, 0.0, 1.0), 5.0);
}

// calculates microfacet occlusion
float g1(vec3 n, vec3 dir, float roughness) {
    // Schlick-GGX

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

// cook-torrance implementation
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

Material get_material(float id) {
    if (id == MATERIAL_MARBLE) return Material(vec3(0.8, 0.8, 0.8), 0.5, 0.0);
    else if (id == MATERIAL_GOLD) return Material(vec3(1.0, 0.89, 0.0), 0.2, 1.0);
}

// render
void main() {
    vec2 uv = vertex_pos;
    uv.x *= resolution.x/resolution.y;

    // ray origin, ray direction
    vec3 ro = vec3(0.0, 2.0, 5.0);
    vec3 rd = normalize(vec3(uv, -1.0));
    rd.zy = rotate_2d(rd.zy, -PI*0.09);

    vec2 hit = march(ro, rd);
    float d = hit.x;
    float material_id = hit.y;

    vec3 color_bg = vec3(0.04);
    vec3 color = color_bg;

    if (d < DIST_MAX) {
        vec3 p = ro + d * rd;
        vec3 n = normal(p); // NOTE: maybe calculate normal inside lighting function
        vec3 v = normalize(ro - p);

        Material m = get_material(material_id);

        vec3 light_pos = vec3(sin(t), 1.0, 0.5);
        vec3 light_color = vec3(1.0, 1.0, 1.0);
        Light lamp = Light(light_pos, light_color, 2.0);

        color = lighting(p, n, v, lamp, m);
    }

    color = color / (color + vec3(1.0)); // tone mapping
    color = pow(color, vec3(1.0 / 2.2)); // gamma correction

    frag_color = vec4(color, 1.0);
}

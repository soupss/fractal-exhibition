#version 450

layout(set = 0, binding = 0) uniform texture2D rendertarget;
layout(set = 0, binding = 1) uniform sampler _sampler;

struct Camera {
    vec3 pos;
    vec3 right;
    vec3 forward;
    vec3 up;
};

layout(set = 1, binding = 0, std140) uniform Uniform {
    vec2 resolution;
    float t;
    Camera camera;
} u;

layout(location = 0) out vec4 frag_color;

void main() {
    vec2 uv = gl_FragCoord.xy / u.resolution;

    frag_color = texture(sampler2D(rendertarget, _sampler), uv);
}

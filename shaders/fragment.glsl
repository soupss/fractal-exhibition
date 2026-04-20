#version 450

layout(set = 0, binding = 0, std430) readonly buffer Color {
    vec4 colors[];
};

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

layout(location = 0) out vec4 color_frag;

void main() {
    uint x = uint(gl_FragCoord.x);
    uint y = uint(gl_FragCoord.y);

    uint i = y * int(u.resolution.x) + x;
    color_frag = colors[i];
}
